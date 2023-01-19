/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.apache.spark.sql.hive.thriftserver

import java.io._
import java.nio.charset.StandardCharsets.UTF_8
import java.util.{ArrayList => JArrayList, List => JList, Locale}
import java.util.concurrent.TimeUnit

import scala.collection.JavaConverters._

import jline.console.ConsoleReader
import jline.console.history.FileHistory
import org.apache.commons.lang3.StringUtils
import org.apache.hadoop.conf.Configuration
import org.apache.hadoop.hive.cli.{CliDriver, CliSessionState, OptionsProcessor}
import org.apache.hadoop.hive.common.HiveInterruptUtils
import org.apache.hadoop.hive.conf.HiveConf
import org.apache.hadoop.hive.ql.Driver
import org.apache.hadoop.hive.ql.processors._
import org.apache.hadoop.hive.ql.session.SessionState
import org.apache.hadoop.security.{Credentials, UserGroupInformation}
import org.apache.thrift.transport.TSocket
import org.slf4j.LoggerFactory
import sun.misc.{Signal, SignalHandler}

import org.apache.spark.SparkConf
import org.apache.spark.deploy.SparkHadoopUtil
import org.apache.spark.internal.Logging
import org.apache.spark.sql.errors.QueryExecutionErrors
import org.apache.spark.sql.hive.HiveUtils
import org.apache.spark.sql.hive.client.HiveClientImpl
import org.apache.spark.sql.hive.security.HiveDelegationTokenProvider
import org.apache.spark.sql.internal.SharedState
import org.apache.spark.util.ShutdownHookManager

object MySparkSQLCLIDriver extends Logging {
  private val prompt = "my-spark-sql-3"
  private val continuedPrompt = "".padTo(prompt.length, ' ')
  private var transport: TSocket = _
  private final val SPARK_HADOOP_PROP_PREFIX = "spark.hadoop."

  initializeLogIfNecessary(true)
  installSignalHandler()

  /**
   * Install an interrupt callback to cancel all Spark jobs. In Hive's CliDriver#processLine(),
   * a signal handler will invoke this registered callback if a Ctrl+C signal is detected while
   * a command is being processed by the current thread.
   */
  def installSignalHandler(): Unit = {
    HiveInterruptUtils.add(() => {
      // Handle remote execution mode
      if (SparkSQLEnv.sparkContext != null) {
        SparkSQLEnv.sparkContext.cancelAllJobs()
      } else {
        if (transport != null) {
          // Force closing of TCP connection upon session termination
          transport.getSocket.close()
        }
      }
    })
  }

  /**
   * 相比于 SparkSQLCLIDriver 重写main方法，去除交互模式
   *
   * @param args
   */
  def main(args: Array[String]): Unit = {
    val oproc = new OptionsProcessor()
    if (!oproc.process_stage1(args)) {
      System.exit(1)
    }

    val sparkConf = new SparkConf(loadDefaults = true)
    val hadoopConf = SparkHadoopUtil.get.newConfiguration(sparkConf)
    val extraConfigs = HiveUtils.formatTimeVarsForHiveClient(hadoopConf)

    val cliConf = HiveClientImpl.newHiveConf(sparkConf, hadoopConf, extraConfigs)

    val sessionState = new CliSessionState(cliConf)

    sessionState.in = System.in
    try {
      sessionState.out = new PrintStream(System.out, true, UTF_8.name())
      sessionState.info = new PrintStream(System.err, true, UTF_8.name())
      sessionState.err = new PrintStream(System.err, true, UTF_8.name())
    } catch {
      case e: UnsupportedEncodingException => System.exit(3)
    }

    if (!oproc.process_stage2(sessionState)) {
      System.exit(2)
    }

    // Set all properties specified via command line.
    val conf: HiveConf = sessionState.getConf
    // Hive 2.0.0 onwards HiveConf.getClassLoader returns the UDFClassLoader (created by Hive).
    // Because of this spark cannot find the jars as class loader got changed
    // Hive changed the class loader because of HIVE-11878, so it is required to use old
    // classLoader as sparks loaded all the jars in this classLoader
    conf.setClassLoader(Thread.currentThread().getContextClassLoader)
    sessionState.cmdProperties.entrySet().asScala.foreach { item =>
      val key = item.getKey.toString
      val value = item.getValue.toString
      // We do not propagate metastore options to the execution copy of hive.
      if (key != "javax.jdo.option.ConnectionURL") {
        conf.set(key, value)
        sessionState.getOverriddenConfigurations.put(key, value)
      }
    }

    val tokenProvider = new HiveDelegationTokenProvider()
    if (tokenProvider.delegationTokensRequired(sparkConf, hadoopConf)) {
      val credentials = new Credentials()
      tokenProvider.obtainDelegationTokens(hadoopConf, sparkConf, credentials)
      UserGroupInformation.getCurrentUser.addCredentials(credentials)
    }

    val warehousePath = SharedState.resolveWarehousePath(sparkConf, conf)
    val qualified = SharedState.qualifyWarehousePath(conf, warehousePath)
    SharedState.setWarehousePathConf(sparkConf, conf, qualified)
    SessionState.setCurrentSessionState(sessionState)

    // Clean up after we exit
    ShutdownHookManager.addShutdownHook { () => SparkSQLEnv.stop() }

    if (isRemoteMode(sessionState)) {
      // Hive 1.2 + not supported in CLI
      throw QueryExecutionErrors.remoteOperationsUnsupportedError()
    }
    // Respect the configurations set by --hiveconf from the command line
    // (based on Hive's CliDriver).
    val hiveConfFromCmd = sessionState.getOverriddenConfigurations.entrySet().asScala
    val newHiveConf = hiveConfFromCmd.map { kv =>
      // If the same property is configured by spark.hadoop.xxx, we ignore it and
      // obey settings from spark properties
      val k = kv.getKey
      val v = sys.props.getOrElseUpdate(SPARK_HADOOP_PROP_PREFIX + k, kv.getValue)
      (k, v)
    }

    val cli = new SparkSQLCLIDriver
    cli.setHiveVariables(oproc.getHiveVariables)

    // In SparkSQL CLI, we may want to use jars augmented by hiveconf
    // hive.aux.jars.path, here we add jars augmented by hiveconf to
    // Spark's SessionResourceLoader to obtain these jars.
    val auxJars = HiveConf.getVar(conf, HiveConf.ConfVars.HIVEAUXJARS)
    if (StringUtils.isNotBlank(auxJars)) {
      val resourceLoader = SparkSQLEnv.sqlContext.sessionState.resourceLoader
      StringUtils.split(auxJars, ",").foreach(resourceLoader.addJar(_))
    }

    // The class loader of CliSessionState's conf is current main thread's class loader
    // used to load jars passed by --jars. One class loader used by AddJarsCommand is
    // sharedState.jarClassLoader which contain jar path passed by --jars in main thread.
    // We set CliSessionState's conf class loader to sharedState.jarClassLoader.
    // Thus we can load all jars passed by --jars and AddJarsCommand.
    sessionState.getConf.setClassLoader(SparkSQLEnv.sqlContext.sharedState.jarClassLoader)

    // TODO work around for set the log output to console, because the HiveContext
    // will set the output into an invalid buffer.
    sessionState.in = System.in
    try {
      sessionState.out = new PrintStream(System.out, true, UTF_8.name())
      sessionState.info = new PrintStream(System.err, true, UTF_8.name())
      sessionState.err = new PrintStream(System.err, true, UTF_8.name())
    } catch {
      case e: UnsupportedEncodingException => System.exit(3)
    }

    if (sessionState.database != null) {
      SparkSQLEnv.sqlContext.sessionState.catalog.setCurrentDatabase(
        s"${sessionState.database}")
    }

    // Execute -i init files (always in silent mode)
    cli.processInitFiles(sessionState)

    // We don't propagate hive.metastore.warehouse.dir, because it might has been adjusted in
    // [[SharedState.loadHiveConfFile]] based on the user specified or default values of
    // spark.sql.warehouse.dir and hive.metastore.warehouse.dir.
    for ((k, v) <- newHiveConf if k != "hive.metastore.warehouse.dir") {
      SparkSQLEnv.sqlContext.setConf(k, v)
    }

    cli.printMasterAndAppId

    val ret: Int = if (sessionState.execString != null) {
      cli.processLine(sessionState.execString)
    } else {
      try {
        if (sessionState.fileName != null) {
          cli.processFile(sessionState.fileName)
        } else {
          logError(s"at least one args need: -e or -f")
          -1
        }
      } catch {
        case e: FileNotFoundException =>
          logError(s"Could not open input file for reading. (${e.getMessage})")
          3
        case e: Throwable =>
          logError(s"error when exec MySparkSQLCLIDriver. (${e.getMessage})")
          -1
      }
    }
    sessionState.close()
    if (ret != 0) {
      throw new RuntimeException(s"MySparkSQLCLIDriver exit with code($ret)")
    }
  }


  def isRemoteMode(state: CliSessionState): Boolean = {
    //    sessionState.isRemoteMode
    state.isHiveServerQuery
  }

}

