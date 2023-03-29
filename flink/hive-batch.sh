#!/usr/bin/env bash
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Mac detected."
    #mac
    MYHOME=/Volumes/data
    SED=gsed
else
    echo "Assuming linux by default."
    #linux
    MYHOME=~
    SED=sed
fi

WORK_HOME=${MYHOME}/workspace
PRJ_HOME=${WORK_HOME}/dockerfile

PRJ_FLINK_HOME=${PRJ_HOME}/flink

FLINK_VERSION=1.15.4
FLINK_SHORT_VERSION=1.15

:<<EOF
FLINK_VERSION=1.16.1
FLINK_SHORT_VERSION=1.16


FLINK_VERSION=1.15.3
FLINK_SHORT_VERSION=1.15

FLINK_VERSION=1.14.0
FLINK_VERSION=1.14.6
FLINK_SHORT_VERSION=1.14

EOF

#FLINKOP_VERSION=1.4.0
FLINKOP_VERSION=1.3.1

#HADOOP_VERSION=3.3.1
#HADOOP_VERSION=3.1.1
HADOOP_VERSION=3.3.4
HIVEREV=3.1.2

JUICEFS_VERSION=1.0.2

STARROCKS_CONNECTOR_VERSION=1.2.5

SCALA_VERSION=2.12

HUDI_VERSION=0.12.2
#1.16.1 only support hudi 0.13.0
#HUDI_VERSION=0.13.0

CDC_VERSION=2.3.0

PYTHON_VERSION=3.7.9

cd ${PRJ_FLINK_HOME}/test

mkdir testsql
cd testsql
:<<EOF
echo "USE hive.tpcds_bin_partitioned_orc_10;SHOW TABLES;" > show_tables.sql
echo "USE hive.tpcds_bin_partitioned_orc_10;SELECT * FROM date_dim LIMIT 5;" > select_date_dim_5.sql
echo "USE hive.tpcds_bin_partitioned_orc_10;SELECT * FROM store_sales LIMIT 5;" > select_store_sales_limit_5.sql
echo "USE hive.tpcds_bin_partitioned_orc_10;SELECT COUNT(1) FROM store_sales;" > select_count_store_sales.sql
EOF
echo "SHOW TABLES;" > show_tables.sql
echo "SELECT * FROM date_dim LIMIT 5" > select_date_dim_5.sql
echo "SELECT * FROM store_sales LIMIT 5;" > select_store_sales_limit_5.sql
echo "SELECT COUNT(1) FROM store_sales;" > select_count_store_sales.sql

mkdir testsql-hivecat
cd testsql-hivecat
arr=(show_tables select_date_dim_5 select_store_sales_limit_5 select_count_store_sales)
for torun in ${arr[*]}
do
  torun=${torun}.sql
  cat ../../setting.sql > ${torun}
  cat ../testsql/${torun} >> ${torun}
  cat ${torun}
done

SQL_FILE_HOME=/app/hdfs/hive
HDFS_SQL_FILE_HOME=/tmp

arr=(show_tables select_date_dim_5 select_store_sales_limit_5 select_count_store_sales)
for torun in ${arr[*]}
do
  torun=${torun}.sql
  ../hdfs_upload_file.sh ${SQL_FILE_HOME} ${HDFS_SQL_FILE_HOME} ${torun}
done

arr=(show_tables)
for torun in ${arr[*]}
do
  torun=${torun}.sql
  cp ${PRJ_FLINK_HOME}/flink-kubernetes-operator-release-${FLINKOP_VERSION}/examples/flink-sql-runner-example/sql-runner.yaml sql-runner.yaml
  $SED -i "/    args:/d" sql-runner.yaml
  $SED -i "/ jarURI: local:/a\    args: [\"/opt/flink/usrlib/testsql-hivecat/${torun}\"]" sql-runner.yaml
  #$SED -i "/ jarURI: local:/a\    args: [\"local:///opt/flink/usrlib/testsql/${torun}\"]" sql-runner.yaml
  #$SED -i "/ jarURI: local:/a\    args: [\"jfs://miniofs/tmp/${torun}\"]" sql-runner.yaml
  cat sql-runner.yaml
  kubectl create -n flink -f sql-runner.yaml
  kubectl logs -f -n flink `kubectl get pod -n flink | grep sql-runner | awk '{print $1}'`
  kubectl logs -n flink `kubectl get pod -n flink | grep sql-runner | awk '{print $1}'`
  kubectl delete -n flink -f sql-runner.yaml
  kubectl get pod -n flink |grep -v Running |grep sql-runner|awk '{print $1}'| xargs kubectl delete pod "$1" -n flink --force --grace-period=0
done

kubectl get pod -n flink
watch kubectl get pod -n flink

kubectl apply -f flink-client.yaml -n flink
kubectl delete -f flink-client.yaml -n flink
kubectl delete pod flink-client -n flink --force --grace-period=0

kubectl cp -n flink flink-client:/opt/flink flink
chmod a+x flink/bin/*
export FLINK_HOME=$PWD/flink
export PATH=$PATH:${FLINK_HOME}/bin
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-11.0.17.jdk/Contents/Home
:<<EOF
本地运行需要CLASS_PATH设置可能
java.lang.NoClassDefFoundError: com/ctc/wstx/io/InputBootstrapper
	at io.juicefs.FlinkFileSystemFactory.configure(FlinkFileSystemFactory.java:36)
	at org.apache.flink.core.fs.FileSystem.initialize(FileSystem.java:344)
	at org.apache.flink.client.cli.CliFrontend.<init>(CliFrontend.java:127)
	at org.apache.flink.client.cli.CliFrontend.<init>(CliFrontend.java:116)
	at org.apache.flink.client.cli.CliFrontend.main(CliFrontend.java:1160)
Caused by: java.lang.ClassNotFoundException: com.ctc.wstx.io.InputBootstrapper
	at java.base/jdk.internal.loader.BuiltinClassLoader.loadClass(BuiltinClassLoader.java:581)
	at java.base/jdk.internal.loader.ClassLoaders$AppClassLoader.loadClass(ClassLoaders.java:178)
	at java.base/java.lang.ClassLoader.loadClass(ClassLoader.java:521)
	... 5 more
EOF

:<<EOF
1, operator提供的example里执行SQL文件的接口，不能执行SET命令

2，flink-config-${APPNAME}是operator创建的，事先手工创建没用

3, 不再报错找不到core/hive等xml，但是flink官方image的docker-entrypoint.sh似乎根据FlinkDeployment李的job/task配置，cat修改flink-conf.yaml，
但是operator自己生成的job pod里，用configmap方式挂载了conf目录导致flink-conf.yaml不可写，最终导致job配置没有写入flink-conf.yaml。
localhost:test apple$ kubectl logs -f -n flink `kubectl get pod -n flink | grep sql-runner | awk '{print $1}'`
/docker-entrypoint.sh: line 73: /opt/flink/conf/flink-conf.yaml: Permission denied
/docker-entrypoint.sh: line 73: /opt/flink/conf/flink-conf.yaml: Permission denied
/docker-entrypoint.sh: line 73: /opt/flink/conf/flink-conf.yaml: Permission denied
/docker-entrypoint.sh: line 89: /opt/flink/conf/flink-conf.yaml.tmp: Read-only file system
[ERROR] The execution result is empty.
[ERROR] Could not get JVM parameters and dynamic configurations properly.
[ERROR] Raw output from BashJavaUtils:
WARNING: sun.reflect.Reflection.getCallerClass is not supported. This will impact performance.
INFO  [] - Loading configuration property: taskmanager.numberOfTaskSlots, 2
INFO  [] - Loading configuration property: classloader.check-leaked-classloader, false
Exception in thread "main" org.apache.flink.configuration.IllegalConfigurationException: JobManager memory configuration failed: Either required fine-grained memory (jobmanager.memory.heap.size), or Total Flink Memory size (Key: 'jobmanager.memory.flink.size' , default: null (fallback keys: [])), or Total Process Memory size (Key: 'jobmanager.memory.process.size' , default: null (fallback keys: [])) need to be configured explicitly.
	at org.apache.flink.runtime.jobmanager.JobManagerProcessUtils.processSpecFromConfigWithNewOptionToInterpretLegacyHeap(JobManagerProcessUtils.java:78)
	at org.apache.flink.runtime.util.bash.BashJavaUtils.getJmResourceParams(BashJavaUtils.java:98)
	at org.apache.flink.runtime.util.bash.BashJavaUtils.runCommand(BashJavaUtils.java:69)
	at org.apache.flink.runtime.util.bash.BashJavaUtils.main(BashJavaUtils.java:56)
Caused by: org.apache.flink.configuration.IllegalConfigurationException: Either required fine-grained memory (jobmanager.memory.heap.size), or Total Flink Memory size (Key: 'jobmanager.memory.flink.size' , default: null (fallback keys: [])), or Total Process Memory size (Key: 'jobmanager.memory.process.size' , default: null (fallback keys: [])) need to be configured explicitly.
	at org.apache.flink.runtime.util.config.memory.ProcessMemoryUtils.failBecauseRequiredOptionsNotConfigured(ProcessMemoryUtils.java:129)
	at org.apache.flink.runtime.util.config.memory.ProcessMemoryUtils.memoryProcessSpecFromConfig(ProcessMemoryUtils.java:86)
	at org.apache.flink.runtime.jobmanager.JobManagerProcessUtils.processSpecFromConfig(JobManagerProcessUtils.java:83)
	at org.apache.flink.runtime.jobmanager.JobManagerProcessUtils.processSpecFromConfigWithNewOptionToInterpretLegacyHeap(JobManagerProcessUtils.java:73)
	... 3 more
EOF

:<<EOF
#创建一个账户
kubectl create serviceaccount flink -n flink
#service account和角色的绑定
kubectl create clusterrolebinding flink-role-binding \
  --clusterrole=edit \
  --serviceaccount=flink:flink
EOF

kubectl get pod -n flink
watch kubectl get pod -n flink my-first-application-cluster-

kubectl logs -f -n flink

kubectl delete deployments.apps -n flink my-first-application-cluster

cat << EOF > /opt/flink/usrlib/testsql-hivecat/show_tables.sql
CREATE CATALOG hive WITH (
    'type' = 'hive',
    'default-database' = 'default',
    'hive-conf-dir' = '/opt/flink/hiveconf',
    'hadoop-conf-dir'='/opt/hadoop/conf'
);
-- set the HiveCatalog as the current catalog of the session
USE hive.tpcds_bin_partitioned_orc_10;
SHOW TABLES;
EOF

cat << \EOF > sql-client-env.sh
#!/usr/bin/env bash
################################################################################
#  Licensed to the Apache Software Foundation (ASF) under one
#  or more contributor license agreements.  See the NOTICE file
#  distributed with this work for additional information
#  regarding copyright ownership.  The ASF licenses this file
#  to you under the Apache License, Version 2.0 (the
#  "License"); you may not use this file except in compliance
#  with the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
# limitations under the License.
################################################################################

################################################################################
# Adopted from "flink" bash script
################################################################################

target="$0"
# For the case, the executable has been directly symlinked, figure out
# the correct bin path by following its symlink up to an upper bound.
# Note: we can't use the readlink utility here if we want to be POSIX
# compatible.
iteration=0
while [ -L "$target" ]; do
    if [ "$iteration" -gt 100 ]; then
        echo "Cannot resolve path: You have a cyclic symlink in $target."
        break
    fi
    ls=`ls -ld -- "$target"`
    target=`expr "$ls" : '.* -> \(.*\)$'`
    iteration=$((iteration + 1))
done

# Convert relative path to absolute path
bin=`dirname "$target"`

# get flink config
. "$bin"/config.sh

if [ "$FLINK_IDENT_STRING" = "" ]; then
        FLINK_IDENT_STRING="$USER"
fi

CC_CLASSPATH=`constructFlinkClassPath`

################################################################################
# SQL client specific logic
################################################################################

log=$FLINK_LOG_DIR/flink-$FLINK_IDENT_STRING-sql-client-$HOSTNAME.log
log_setting=(-Dlog.file="$log" -Dlog4j.configuration=file:"$FLINK_CONF_DIR"/log4j-cli.properties -Dlog4j.configurationFile=file:"$FLINK_CONF_DIR"/log4j-cli.properties -Dlogback.configurationFile=file:"$FLINK_CONF_DIR"/logback.xml)

# get path of jar in /opt if it exist
FLINK_SQL_CLIENT_JAR=$(find "$FLINK_OPT_DIR" -regex ".*flink-sql-client.*.jar")

# add flink-python jar to the classpath
if [[ ! "$CC_CLASSPATH" =~ .*flink-python.*.jar ]]; then
    FLINK_PYTHON_JAR=$(find "$FLINK_OPT_DIR" -regex ".*flink-python.*.jar")
    if [ -n "$FLINK_PYTHON_JAR" ]; then
        CC_CLASSPATH="$CC_CLASSPATH:$FLINK_PYTHON_JAR"
    fi
fi
EOF

kubectl cp -f docker-entrypoint.sh -n flink `kubectl get pod -n flink | grep flink-client | awk '{print $1}'`:/docker-entrypoint.sh

kubectl exec -it -n flink `kubectl get pod -n flink | grep flink-client | awk '{print $1}'` -- bash
  #FLINK_VERSION=1.16.1
  FLINK_VERSION=1.15.3
  arr=(show_tables)
  for torun in ${arr[*]}
  do
    torun=${torun}.sql

    flink run-application \
    --target kubernetes-application \
    -Dexecution.attached=true \
    -Dkubernetes.namespace=flink \
    -Dkubernetes.cluster-id=my-first-application-cluster \
    -Dkubernetes.high-availability=org.apache.flink.kubernetes.highavailability.KubernetesHaServicesFactory \
    -Dhigh-availability.storageDir=jfs://miniofs/flink/recovery \
    -Dkubernetes.container.image=harbor.my.org:1080/flink/flink-juicefs-py37:${FLINK_VERSION} \
    -Dkubernetes.rest-service.exposed.type=NodePort \
    -Djobmanager.memory.process.size=2048m \
    -Dkubernetes.jobmanager.cpu=1 \
    -Dtaskmanager.memory.process.size=2048m \
    -Dkubernetes.taskmanager.cpu=1 \
    -Dtaskmanager.numberOfTaskSlots=2 \
    -Dstate.backend=rocksdb \
    -Dstate.checkpoints.dir=jfs://miniofs/flink/checkpoints \
    -Dstate.backend.incremental=true \
    -C file:/opt/flink/opt/flink-python_2.12-1.15.3.jar \
    -c org.apache.flink.table.client.SqlClient \
    local:///opt/flink/opt/flink-sql-client-1.15.3.jar -i /opt/flink/usrlib/setting.sql -e 'SELECT * FROM tpcds_bin_partitioned_orc_10.date_dim LIMIT 5'
    #-f /opt/flink/usrlib/testsql/select_date_dim_5_yat.sql
    #show_tables.sql
    #/opt/flink/usrlib/sql-scripts/simple.sql

    flink cancel --target kubernetes-application -Dkubernetes.cluster-id=my-first-application-cluster -Dkubernetes.namespace=flink `flink list --target kubernetes-application -Dkubernetes.cluster-id=my-first-application-cluster -Dkubernetes.namespace=flink`

    echo 'stop' | kubernetes-session.sh -Djobmanager.memory.process.size=2048m -Dexecution.attached=true -Dtaskmanager.memory.process.size=2048m -Dkubernetes.cluster-id=my-first-application-cluster

    kubectl logs -f -n flink `kubectl get pod -n flink | grep sql-runner | awk '{print $1}'`
    kubectl logs -n flink `kubectl get pod -n flink | grep sql-runner | awk '{print $1}'`
    kubectl delete -n flink -f sql-runner.yaml
    kubectl get pod -n flink |grep -v Running |grep sql-runner|awk '{print $1}'| xargs kubectl delete pod "$1" -n flink --force --grace-period=0
  done
:<<EOF
flink run-application
Caused by: java.lang.IllegalArgumentException: only single statement supported
	at org.apache.flink.util.Preconditions.checkArgument(Preconditions.java:138) ~[flink-dist-1.15.3.jar:1.15.3]
	at org.apache.flink.table.planner.delegation.ParserImpl.parse(ParserImpl.java:103) ~[?:?]
	at org.apache.flink.table.api.internal.TableEnvironmentImpl.executeSql(TableEnvironmentImpl.java:695) ~[flink-table-api-java-uber-1.15.3.jar:1.15.3]
	at org.apache.flink.examples.SqlRunner.main(SqlRunner.java:52) ~[?:?]
	at jdk.internal.reflect.NativeMethodAccessorImpl.invoke0(Native Method) ~[?:?]
	at jdk.internal.reflect.NativeMethodAccessorImpl.invoke(Unknown Source) ~[?:?]
	at jdk.internal.reflect.DelegatingMethodAccessorImpl.invoke(Unknown Source) ~[?:?]
	at java.lang.reflect.Method.invoke(Unknown Source) ~[?:?]
	at org.apache.flink.client.program.PackagedProgram.callMainMethod(PackagedProgram.java:355) ~[flink-dist-1.15.3.jar:1.15.3]
	at org.apache.flink.client.program.PackagedProgram.invokeInteractiveModeForExecution(PackagedProgram.java:222) ~[flink-dist-1.15.3.jar:1.15.3]
	at org.apache.flink.client.ClientUtils.executeProgram(ClientUtils.java:114) ~[flink-dist-1.15.3.jar:1.15.3]
	at org.apache.flink.client.deployment.application.ApplicationDispatcherBootstrap.runApplicationEntryPoint(ApplicationDispatcherBootstrap.java:291) ~[flink-dist-1.15.3.jar:1.15.3]
	... 13 more
EOF

  #FLINK_VERSION=1.15.3
  #FLINK_VERSION=1.14.6
  #FLINK_VERSION=1.16.1
  #FLINK_VERSION=1.14.0
  FLINK_VERSION=1.15.4
  kubernetes-session.sh \
      -Dexecution.attached=true \
      -Dkubernetes.namespace=flink \
      -Dkubernetes.cluster-id=my-first-application-cluster \
      -Dkubernetes.high-availability=org.apache.flink.kubernetes.highavailability.KubernetesHaServicesFactory \
      -Dhigh-availability.storageDir=jfs://miniofs/flink/recovery \
      -Dkubernetes.container.image=harbor.my.org:1080/flink/flink-juicefs:${FLINK_VERSION} \
      -Dkubernetes.rest-service.exposed.type=NodePort \
      -Djobmanager.memory.process.size=2048m \
      -Dkubernetes.jobmanager.cpu=1 \
      -Dtaskmanager.memory.process.size=2048m \
      -Dkubernetes.taskmanager.cpu=1 \
      -Dtaskmanager.numberOfTaskSlots=2 \
      -Dstate.backend=rocksdb \
      -Dstate.checkpoints.dir=jfs://miniofs/flink/checkpoints \
      -Dstate.backend.incremental=true

#1.15.3
Flink SQL>   SELECT * FROM date_dim LIMIT 5;
>
13:57:48.002 [ORC_GET_SPLITS #0] ERROR org.apache.hadoop.hive.ql.io.AcidUtils - Failed to get files with ID; using regular API: Only supported for DFS; got class io.juicefs.JuiceFileSystem
#1.14.6
Flink SQL>   SELECT * FROM date_dim LIMIT 5;
>
13:57:48.002 [ORC_GET_SPLITS #0] ERROR org.apache.hadoop.hive.ql.io.AcidUtils - Failed to get files with ID; using regular API: Only supported for DFS; got class io.juicefs.JuiceFileSystem
[ERROR] Could not execute SQL statement. Reason:
java.lang.NoSuchMethodError: java.nio.ByteBuffer.limit(I)Ljava/nio/ByteBuffer;
#1.14.6
Flink SQL> SELECT * FROM time_dim LIMIT 5;
01:11:37.918 [ORC_GET_SPLITS #0] ERROR org.apache.hadoop.hive.ql.io.AcidUtils - Failed to get files with ID; using regular API: Only supported for DFS; got class io.juicefs.JuiceFileSystem
#1.14.0
Flink SQL> SELECT * FROM time_dim LIMIT 5;
01:11:37.918 [ORC_GET_SPLITS #0] ERROR org.apache.hadoop.hive.ql.io.AcidUtils - Failed to get files with ID; using regular API: Only supported for DFS; got class io.juicefs.JuiceFileSystem
[ERROR] Could not execute SQL statement. Reason:
java.lang.NoSuchMethodError: java.nio.ByteBuffer.limit(I)Ljava/nio/ByteBuffer;


#1.15.3
Flink SQL> SET table.sql-dialect=hive;
[ERROR] Could not execute SQL statement. Reason:
org.apache.flink.table.api.ValidationException: Could not find any factory for identifier 'hive' that implements 'org.apache.flink.table.planner.delegation.ParserFactory' in the classpath.

Available factory identifiers are:



kubectl exec -it -n flink `kubectl get pod -n flink | grep my-first-application-cluster | awk '{print $1}'` -- sql-client.sh embedded -i /opt/flink/usrlib/setting.sql
kubectl exec -it -n flink `kubectl get pod -n flink | grep my-first-application-cluster | awk '{print $1}'` -- sql-client.sh
  SHOW TABLES;
  SELECT * FROM date_dim LIMIT 5;

      -Dkubernetes.container.image=flink:1.15 \

  FLINK_VERSION=1.14.6
  kubernetes-session.sh \
      -Dexecution.attached=true \
      -Dkubernetes.namespace=flink \
      -Dkubernetes.cluster-id=my-first-application-cluster \
      -Dkubernetes.container.image=harbor.my.org:1080/flink/flink-juicefs:${FLINK_VERSION} \
      -Djobmanager.memory.process.size=2048m \
      -Dkubernetes.jobmanager.cpu=1 \
      -Dtaskmanager.memory.process.size=2048m \
      -Dkubernetes.taskmanager.cpu=1 \
      -Dtaskmanager.numberOfTaskSlots=2

#有hadoop classpath没有shaded可以
#有shaded，删掉hadoop class path运行sql-client.sh提示java.lang.NoClassDefFoundError: com/ctc/wstx/io/InputBootstrapper