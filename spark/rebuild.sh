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

SPARK_VERSION=3.3.1
HADOOP_VERSION=3.2.1
HIVEREV=3.1.2
:<<EOF
tgz解压有meta data问题可能是文件名过长
wget -c https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}.tgz
tar xzvf spark-${SPARK_VERSION}.tgz
EOF
wget -c https://github.com/apache/spark/archive/refs/tags/v${SPARK_VERSION}.zip -o spark-${SPARK_VERSION}.zip
unzip -q spark-${SPARK_VERSION}.zip
cd spark-${SPARK_VERSION}
#安装scala2.12
file=./dev/make-distribution.sh
cp ${file} ${file}.bk
cp ${file}.bk ${file}
$SED -i 's/clean package/package/g' ${file}
cp ./dev/make-distribution.sh ./dev/make-distribution.sh.bk
cp ../make-distribution-${SPARK_VERSION}.sh ./dev/make-distribution.sh
wget -c https://downloads.lightbend.com/scala/2.12.15/scala-2.12.15.tgz
./dev/change-scala-version.sh 2.12
export MAVEN_OPTS=-Xss4096k
./dev/make-distribution.sh --name volcano --pip --tgz -Pyarn -Phadoop-3.2 -Dhadoop.version=${HADOOP_VERSION} -Psparkr -Phive -Phive-thriftserver -Pkubernetes -Pvolcano  -DskipTests package
# mvn -Pyarn -Phadoop-3.2 -Dhadoop.version=${HADOOP_VERSION} -Phive -Phive-thriftserver -Pkubernetes -Pvolcano  -DskipTests package
:<<EOF
1，-DskipTests跳过test case执行，-Dmaven.test.skip=true不编译tests代码
mllib对mllib-local的test jar有依赖导致编译出错，需要去掉-Dmaven.test.skip=true，保留-DskipTests
报错：[ERROR] Failed to execute goal on project spark-mllib_2.12: Could not resolve dependencies for project org.apache.spark:spark-mllib_2.12:jar:3.3.1: org.apache.spark:spark-mllib-local_2.12:jar:tests:3.3.1 was not found in http://maven.aliyun.com/nexus/content/groups/public/ during a previous attempt. This failure was cached in the local repository and resolution is not reattempted until the update interval of alimaven has elapsed or updates are forced -> [Help 1]

2，如果碰到"Exception in thread "main" java.lang.StackOverflowError"
export MAVEN_OPTS=-Xss4096k

3，sparkr编译代码对r和很多包有依赖，
  下载安装r
  #mac需要安装native包xquartz（x11），knitr依赖
  r
  #cran选择25（shenzhen）
  >
    #, repos = "https://mirrors.ustc.edu.cn/CRAN/"
    install.packages('knitr')
    install.packages('rmarkdown')
    install.packages('pandoc')
    install.packages('e1071')
  #mac需要安装pandoc、basictex包（包含pdflatex）

4，maven编译结束后，如果打包因为r包等原因出错，可以注释掉maven编译命令以避免重新编译jar（虽然删除clean，但是还是会重新build）


[INFO] Scanning for projects...
[INFO] ------------------------------------------------------------------------
[INFO] Reactor Build Order:
[INFO]
[INFO] Spark Project Parent POM                                           [pom]
[INFO] Spark Project Tags                                                 [jar]
[INFO] Spark Project Sketch                                               [jar]
[INFO] Spark Project Local DB                                             [jar]
[INFO] Spark Project Networking                                           [jar]
[INFO] Spark Project Shuffle Streaming Service                            [jar]
[INFO] Spark Project Unsafe                                               [jar]
[INFO] Spark Project Launcher                                             [jar]
[INFO] Spark Project Core                                                 [jar]
[INFO] Spark Project ML Local Library                                     [jar]
[INFO] Spark Project GraphX                                               [jar]
[INFO] Spark Project Streaming                                            [jar]
[INFO] Spark Project Catalyst                                             [jar]
[INFO] Spark Project SQL                                                  [jar]
[INFO] Spark Project ML Library                                           [jar]
[INFO] Spark Project Tools                                                [jar]
[INFO] Spark Project Hive                                                 [jar]
[INFO] Spark Project REPL                                                 [jar]
[INFO] Spark Project YARN Shuffle Service                                 [jar]
[INFO] Spark Project YARN                                                 [jar]
[INFO] Spark Project Kubernetes                                           [jar]
[INFO] Spark Project Hive Thrift Server                                   [jar]
[INFO] Spark Project Assembly                                             [pom]
[INFO] Kafka 0.10+ Token Provider for Streaming                           [jar]
[INFO] Spark Integration for Kafka 0.10                                   [jar]
[INFO] Kafka 0.10+ Source for Structured Streaming                        [jar]
[INFO] Spark Project Examples                                             [jar]
[INFO] Spark Integration for Kafka 0.10 Assembly                          [jar]
[INFO] Spark Avro                                                         [jar]
[INFO]
[INFO] -----------------< org.apache.spark:spark-parent_2.12 >-----------------
[INFO] Building Spark Project Parent POM 3.3.1                           [1/29]
[INFO] --------------------------------[ pom ]---------------------------------
EOF

ls -l spark-${SPARK_VERSION}-bin-volcano.tgz
#281906227
rm -rf tmp;mkdir tmp;cd tmp
tar xzvf ../spark-${SPARK_VERSION}-bin-volcano.tgz
du -h -d 2
:<<EOF
288M	./spark-3.3.1-bin-hadoop3/jars
116K	./spark-3.3.1-bin-hadoop3/bin
336K	./spark-3.3.1-bin-hadoop3/licenses
 14M	./spark-3.3.1-bin-hadoop3/python
112K	./spark-3.3.1-bin-hadoop3/sbin
5.5M	./spark-3.3.1-bin-hadoop3/R
 11M	./spark-3.3.1-bin-hadoop3/yarn
4.0M	./spark-3.3.1-bin-hadoop3/examples
 52K	./spark-3.3.1-bin-hadoop3/kubernetes
816K	./spark-3.3.1-bin-hadoop3/data
 36K	./spark-3.3.1-bin-hadoop3/conf
324M	./spark-3.3.1-bin-hadoop3
324M	.

271M	./spark-3.3.1-bin-volcano/jars
116K	./spark-3.3.1-bin-volcano/bin
336K	./spark-3.3.1-bin-volcano/licenses
 14M	./spark-3.3.1-bin-volcano/python
112K	./spark-3.3.1-bin-volcano/sbin
3.2M	./spark-3.3.1-bin-volcano/R
 11M	./spark-3.3.1-bin-volcano/yarn
4.0M	./spark-3.3.1-bin-volcano/examples
 52K	./spark-3.3.1-bin-volcano/kubernetes
816K	./spark-3.3.1-bin-volcano/data
 36K	./spark-3.3.1-bin-volcano/conf
305M	./spark-3.3.1-bin-volcano
305M	.
EOF
mv spark-${SPARK_VERSION}-bin-volcano.tgz ../

:<<EOF
diff spark-2.4.5/sql/hive-thriftserver/src/main/scala/org/apache/spark/sql/hive/thriftserver/SparkSQLDriver.scala spark-3.3.1/sql/hive-thriftserver/src/main/scala/org/apache/spark/sql/hive/thriftserver/SparkSQLCLIDriver.scala
diff spark-2.4.5/sql/hive-thriftserver/src/main/scala/org/apache/spark/sql/hive/thriftserver/SparkSQLDriver.scala spark-sql-cluster-mode/src/main/scala/org/apache/spark/sql/hive/my/MySparkSQLCLIDriver.scala
EOF
git clone git@github.com:zhfk/spark-sql-cluster-mode.git
cp -rf spark-sql-cluster-mode spark-sql-cluster-mode-3
cp MySparkSQLCLIDriver.scala spark-sql-cluster-mode-3/src/main/scala/org/apache/spark/sql/hive/my/MySparkSQLCLIDriver.scala
cd spark-sql-cluster-mode-3
$SED -i 's/<spark.version>2.4.5<\/spark.version>/<spark.version>3.3.1<\/spark.version>/g' pom.xml
$SED -i 's/<scala.version>2.11<\/scala.version>/<scala.version>2.12<\/scala.version>/g' pom.xml
mvn clean scala:compile compile package
