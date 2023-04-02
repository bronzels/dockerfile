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
FLINK_VERSION=1.17.0
FLINK_SHORT_VERSION=1.17

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
#HADOOP_VERSION=2.10.2
HIVEREV=3.1.2
#HIVEREV=2.3.6
#HIVEREV=2.3.9
#HIVEREV=3.1.3

#JUICEFS_VERSION=1.0.2
JUICEFS_VERSION=1.0.3

STARROCKS_CONNECTOR_VERSION=1.2.5

SCALA_VERSION=2.12

HUDI_VERSION=0.12.2
#1.16.1 only support hudi 0.13.0
#HUDI_VERSION=0.13.0

CDC_VERSION=2.3.0

PYTHON_VERSION=3.7.9

cd ${PRJ_FLINK_HOME}/

#starrocks connector
#虽然flink官方image的jdk是11，但是thrift和connector的pom都要求8
#export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-11.0.17.jdk/Contents/Home
#2 libs for starrrocks spark connector
tar xzvf starrocks-connector-for-apache-flink-1.2.5.tar.gz
cd starrocks-connector-for-apache-flink-1.2.5
cd starrocks-stream-load-sdk/
mvn clean install -DskipTests -Dmaven.test.skip=true -Dmaven.javadoc.skip=true
cd ..
cd starrocks-thrift-sdk/
:<<EOF
file=pom.xml
cp ${file} ${file}.bk
$SED -i '/<build>/a\<pluginManagement>' ${file}
$SED -i '/<\/build>/i\<\/pluginManagement>' ${file}
file=pom.xml
cp ${file} ${file}.bk
$SED -i 's/<phase>package<\/phase>/<phase>install<\/phase>/g' ${file}
./build-thrift.sh
EOF
thrift -r -gen java gensrc/StarrocksExternalService.thrift
if [ ! -d "src/main/java/com/starrocks/thrift" ]; then
    mkdir -p src/main/java/com/starrocks/thrift
else
    rm -rf src/main/java/com/starrocks/thrift/*
fi
cp -r gen-java/com/starrocks/thrift/* src/main/java/com/starrocks/thrift
rm -rf gen-java
:<<EOF
出现失败maven-gpg-plugin gpg: no default secret key: No secret key
安装pgp
gpg --gen-key
mvn clean install -DskipTests -Dmaven.test.skip=true -Dgpg.skip -Dmaven.javadoc.skip=true
EOF
mvn clean package -DskipTests -Dmaven.test.skip=true -Dmaven.javadoc.skip=true
mvn install:install-file -DgroupId=com.starrocks -DartifactId=starrocks-thrift-sdk -Dversion=1.0.1 -Dpackaging=jar -Dfile=target/starrocks-thrift-sdk-1.0.1.jar
cd ..
#starrrocks flink connector
mvn clean package -DskipTests -Dmaven.test.skip=true -Dmaven.javadoc.skip=true



wget -c https://github.com/apache/flink-kubernetes-operator/archive/refs/tags/release-${FLINKOP_VERSION}.tar.gz
tar xzvf flink-kubernetes-operator-release-${FLINKOP_VERSION}.tar.gz
cd ${PRJ_FLINK_HOME}/flink-kubernetes-operator-release-${FLINKOP_VERSION}
:<<EOF
mkdir .m2
cp ${MYHOME}/m2/settings.xml .m2/
EOF
file=Dockerfile
cp ${file} ${file}.bk
$SED -i 's/RUN --mount=type=cache/#RUN --mount=type=cache/g' ${file}
$SED -i "/; then apt-get update; fi/i\RUN sed -i -E 's/(deb|security).debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list" ${file}
#$SED -i '/COPY . ./a\ADD .\/flink-kubernetes-operator.tar.gz .\/' ${file}
#$SED -i 's/COPY . ./#COPY . ./g' ${file}
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-11.0.17.jdk/Contents/Home
mvn -ntp clean install -pl flink-kubernetes-standalone,flink-kubernetes-operator-api,flink-kubernetes-operator,flink-kubernetes-webhook -DskipTests=true -Dmaven.test.skip=true -Dmaven.javadoc.skip=true
#mvn -ntp install -pl examples/flink-sql-runner-example,examples/kubernetes-client-examples,examples/flink-python-example -DskipTests=true -Dmaven.test.skip=true -Dmaven.javadoc.skip=true

DOCKER_BUILDKIT=1 docker build ./ --progress=plain --build-arg FLINKOP_VERSION=${FLINKOP_VERSION} --build-arg SKIP_OS_UPDATE="false" -t harbor.my.org:1080/flink/flink-kubernetes-operator:${FLINKOP_VERSION}
docker push harbor.my.org:1080/flink/flink-kubernetes-operator:${FLINKOP_VERSION}

#docker
ansible all -m shell -a"docker images|grep flink-kubernetes-operator"
ansible all -m shell -a"docker images|grep flink-kubernetes-operator|awk '{print \$3}'|xargs docker rmi -f"
#containerd
ansible all -m shell -a"crictl images|grep flink-kubernetes-operator"
ansible all -m shell -a"crictl images|grep flink-kubernetes-operator|awk '{print \$3}'|xargs crictl rmi"

:<<EOF
#docker
ansible all -m shell -a"docker images|grep flink-kubernetes-operator-juicefs"
ansible all -m shell -a"docker images|grep flink-kubernetes-operator-juicefs|awk '{print \$3}'|xargs docker rmi -f"
#containerd
ansible all -m shell -a"crictl images|grep flink-kubernetes-operator-juicefs"
ansible all -m shell -a"crictl images|grep flink-kubernetes-operator-juicefs|awk '{print \$3}'|xargs crictl rmi"
EOF

kubectl create ns flink

cd ${PRJ_FLINK_HOME}/flink-kubernetes-operator-release-${FLINKOP_VERSION}/helm/flink-kubernetes-operator
wget -c https://github.com/jetstack/cert-manager/releases/download/v1.8.2/cert-manager.yaml
kubectl create -f cert-manager.yaml
kubectl delete -f cert-manager.yaml
#helm install my -n flink -f values.yaml \
helm install my -n flink -f values.yaml \
  --set image.repository=harbor.my.org:1080/flink/flink-kubernetes-operator \
  --set image.tag=${FLINKOP_VERSION} \
  --set webhook.create=false \
  ./
:<<EOF
NAME: my
LAST DEPLOYED: Mon Mar  6 10:58:02 2023
NAMESPACE: flink
STATUS: deployed
REVISION: 1
TEST SUITE: None
EOF

kubectl get all -n flink
watch kubectl get all -n flink

helm uninstall my -n flink
:<<EOF
These resources were kept due to the resource policy:
[RoleBinding] flink-role-binding
[Role] flink
[ServiceAccount] flink
EOF
#保留，在直接提交作业到k8s时复用
kubectl get rolebindings flink-role-binding -n flink -o yaml > flink-role-binding.yaml
kubectl get role flink -n flink -o yaml > flink-role.yaml
kubectl get serviceaccount flink -n flink -o yaml > flink-serviceaccount.yaml

kubectl delete rolebindings flink-role-binding -n flink
kubectl delete role flink -n flink
kubectl delete serviceaccount flink -n flink
kubectl delete serviceaccount flink-operator -n flink

kubectl get pod -n flink |grep -v Running |awk '{print $1}'| xargs kubectl delete pod "$1" -n flink --force --grace-period=0
kubectl delete RoleBinding flink-role-binding -n flink
kubectl delete Role flink -n flink
kubectl delete ServiceAccount flink -n flink

kubectl delete ns flink --force --grace-period=0

wget -c https://raw.githubusercontent.com/apache/flink-kubernetes-operator/release-1.4/examples/basic.yaml
kubectl create -n flink -f basic.yaml

kubectl exec -it -n flink `kubectl get pod -n flink | grep Running | grep operator | awk '{print $1}'` -- bash


cd ${PRJ_FLINK_HOME}/flink-kubernetes-operator-release-${FLINKOP_VERSION}
cd examples/flink-sql-runner-example
mvn -ntp clean install -DskipTests=true -Dmaven.test.skip=true -Dmaven.javadoc.skip=true
cd ${PRJ_FLINK_HOME}/flink-kubernetes-operator-release-${FLINKOP_VERSION}
cd examples/kubernetes-client-examples
mvn -ntp clean install -DskipTests=true -Dmaven.test.skip=true -Dmaven.javadoc.skip=true
cd ${PRJ_FLINK_HOME}/flink-kubernetes-operator-release-${FLINKOP_VERSION}

cd ${PRJ_FLINK_HOME}
#cp ${PRJ_HOME}/juicefs/juicefs-hadoop-${JUICEFS_VERSION}-jdk11-ubuntu22.04.jar ./
cp ${PRJ_HOME}/juicefs/juicefs-hadoop-${JUICEFS_VERSION}.jar ./

:<<EOF
mkdir -p conf/hadoop
cp ${PRJ_HOME}/juicefs/core-site.xml conf/hadoop/
cp ${PRJ_HOME}/spark/hdfs-site.xml conf/hadoop/
kubectl create cm hadoop-config-sql-runner -n flink --from-file=conf/hadoop
kubectl delete cm hadoop-config-sql-runner -n flink
kubectl get cm hadoop-config-sql-runner -n flink -o yaml
EOF
cp ${PRJ_HOME}/juicefs/core-site.xml conf/
cp ${PRJ_HOME}/spark/hdfs-site.xml conf/

cp ${PRJ_HOME}/spark/hive-site.xml conf/

cd ${PRJ_FLINK_HOME}
:<<EOF
-- set up the default properties
SET sql-client.execution.mode=batch;
SET parallism.default=10;
SET pipeline.auto-watermark-interval=500;
EOF
cat << EOF > setting.sql
SET execution.checkpointing.interval = 3s;
  
-- SET table.local-time-zone=Asia/Shanghai;
  
CREATE CATALOG hive WITH (
    'type' = 'hive',
    'default-database' = 'default',
    'hive-conf-dir' = '/opt/flink/hiveconf',
    'hadoop-conf-dir'='/opt/hadoop/conf'
);

CREATE CATALOG hudi_catalog WITH (
    'type' = 'hudi',
    'mode' = 'hms',
    'default-database' = 'default',
    'hive.conf.dir' = '/opt/flink/hiveconf',
    'table.external' = 'true'
);
EOF

cat << EOF > create_databases.sql
CREATE DATABASE IF NOT EXISTS hive.flink_mydb;
CREATE DATABASE IF NOT EXISTS hive.flink_tpcds;
CREATE DATABASE IF NOT EXISTS hudi_catalog.hudi_mydb;
CREATE DATABASE IF NOT EXISTS hudi_catalog.hudi_tpcds;
EOF

SQL_FILE_HOME=/app/hdfs/hive
HDFS_SQL_FILE_HOME=/flink/scripts

../hdfs_upload_file.sh ${SQL_FILE_HOME} ${HDFS_SQL_FILE_HOME} create_databases.sql

:<<EOF
maven repo下载如下4个jar，1和4必须
flink-sql-connector-hive-3.1.2_2.12-1.15.3.jar
flink-connector-hive_2.12-1.15.3.jar
hive-exec-3.1.2.jar
flink-shaded-hadoop-3-3.1.1.7.2.9.0-173-9.0.jar
flink-sql-connector-hive-3.1.2_2.12-1.14.0.jar 以及 hive-exec-3.1.2.jar 包含的guava版本和hadoop版本有冲突，所以操作如下：
用压缩软件打开，找到com/google，然后把这个google全部删除。(注意：不需要解压缩，直接右键删除)

flink-sql-connector-kafka-1.15.3.jar
EOF
cp ${PRJ_HOME}/spark/hudi-release-0.12.2/packaging/hudi-flink-bundle/target/hudi-flink${FLINK_SHORT_VERSION}-bundle-${HUDI_VERSION}.jar ./

kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- hadoop classpath
#/app/hdfs/hadoop/etc/hadoop:/app/hdfs/hadoop/share/hadoop/common/lib/*:/app/hdfs/hadoop/share/hadoop/common/*:/app/hdfs/hadoop/share/hadoop/hdfs:/app/hdfs/hadoop/share/hadoop/hdfs/lib/*:/app/hdfs/hadoop/share/hadoop/hdfs/*:/app/hdfs/hadoop/share/hadoop/mapreduce/lib/*:/app/hdfs/hadoop/share/hadoop/mapreduce/*:/app/hdfs/hadoop/share/hadoop/yarn:/app/hdfs/hadoop/share/hadoop/yarn/lib/*:/app/hdfs/hadoop/share/hadoop/yarn/*
mkdir -p conf/flink
cat << EOF > conf/flink-conf.yaml
taskmanager.numberOfTaskSlots: 2
classloader.check-leaked-classloader: false
EOF
cat << EOF > conf/log4j.properties
# This affects logging for both user code and Flink
log4j.rootLogger=INFO, console

# Uncomment this if you want to _only_ change Flink's logging
log4j.logger.org.apache.flink=INFO

# The following lines keep the log level of common libraries/connectors on
# log level INFO. The root logger does not override this. You have to manually
# change the log levels here.
log4j.logger.akka=INFO
log4j.logger.org.apache.kafka=INFO
log4j.logger.org.apache.hadoop=INFO
log4j.logger.org.apache.zookeeper=INFO

# Log all infos to the console
log4j.appender.console=org.apache.log4j.ConsoleAppender
log4j.appender.console.layout=org.apache.log4j.PatternLayout
log4j.appender.console.layout.ConversionPattern=%d{yyyy-MM-dd HH:mm:ss,SSS} %-5p %-60c %x - %m%n

# Suppress the irrelevant (wrong) warnings from the Netty channel handler
log4j.logger.org.apache.flink.shaded.akka.org.jboss.netty.channel.DefaultChannelPipeline=ERROR, console
EOF
kubectl create cm flink-config-sql-runner -n flink --from-file=conf
kubectl delete cm flink-config-sql-runner -n flink
kubectl get cm flink-config-sql-runner -n flink -o yaml

kubectl cp -n flink flink-client:/docker-entrypoint.sh docker-entrypoint.sh

wget -c https://github.com/apache/flink/archive/refs/tags/release-${FLINK_VERSION}.tar.gz
cd flink-release-${FLINK_VERSION}
# (shade-flink) on project flink-sql-connector-kinesis:GC overhead limit exceeded
#allied to hadoop3/hive3
#1.15.4
mvn clean install -DskipTests -Dspotless.check.skip=true -Dfast -T 1C -Dhadoop.version=3.3.4 -Dhive.version=3.1.2 -Dhivemetastore.hadoop.version=3.3.4 -Dmaven.javadoc.skip=true -Dcheckstyle.skip=true -Dlicense.skip=true -Drat.ignoreErrors=true
#1.16.1
mvn clean install -DskipTests -Dspotless.check.skip=true -Dfast -T 1C -Dhadoop.version=3.3.4 -Dhive.version=3.1.2 -Dhivemetastore.hadoop.version=3.3.4 -Dmaven.javadoc.skip=true -Dcheckstyle.skip=true -Dlicense.skip=true -Drat.ignoreErrors=true
#1.17.0
#hive.version can't be 3.1.2 as no such already built lib as dep
mvn clean install -DskipTests -Dspotless.check.skip=true -Dfast -T 1C -Dflink.hadoop.version=3.3.4 -Dhive.version=3.1.3 -Dmaven.javadoc.skip=true -Dcheckstyle.skip=true -Dlicense.skip=true -Drat.ignoreErrors=true
#default hadoop2/hive2
:<<EOF
#flink
    <hadoop.version>2.8.5</hadoop.version>
    <hive.version>2.3.9</hive.version>
    <hive-2.2.0-orc-version>1.4.3</hive-2.2.0-orc-version>
    <orc.version>1.5.6</orc.version>
    <!--
            Hive 2.3.4 relies on Hadoop 2.7.2 and later versions.
            For Hadoop 2.7, the minor Hadoop version supported for flink-shaded-hadoop-2-uber is 2.7.5
    -->
    <hivemetastore.hadoop.version>2.7.5</hivemetastore.hadoop.version>
#hudi
    <hadoop.version>2.10.1</hadoop.version>
    <hive.groupid>org.apache.hive</hive.groupid>
    <hive.version>2.3.1</hive.version>
    <hive.parquet.version>1.10.1</hive.parquet.version>
    <hive.avro.version>1.8.2</hive.avro.version>
    <hive.exec.classifier>core</hive.exec.classifier>
    <orc.version>1.6.0</orc.version>
    <spark.version>${spark2.version}</spark.version>
    <spark2.version>2.4.4</spark2.version>
    <spark3.version>3.3.1</spark3.version>
    <sparkbundle.version></sparkbundle.version>
    <flink1.15.version>1.15.1</flink1.15.version>
    <flink1.14.version>1.14.5</flink1.14.version>
    <flink1.13.version>1.13.6</flink1.13.version>
    <flink.version>${flink1.15.version}</flink.version>
    <hudi.flink.module>hudi-flink1.15.x</hudi.flink.module>
EOF
mvn clean install -DskipTests -Dspotless.check.skip=true -Dfast -T 1C -Dmaven.javadoc.skip=true -Dcheckstyle.skip=true -Dlicense.skip=true -Drat.ignoreErrors=true
:<<EOF
[ERROR] Failed to execute goal com.github.eirslett:frontend-maven-plugin:1.11.0:npm (npm install) on project flink-runtime-web: Failed to run task: 'npm ci --cache-max=0 --no-save ${npm.proxy}' failed. org.apache.commons.exec.ExecuteException: Process exited with an error: 1 (Exit value: 1) -> [Help 1]
先cd到flink-runtime-web模块进行编译
1> 删除web-dashboard下面的node_modules文件夹
2> 修改runtime-web下面的pom文件
vim pom.xml
/--cache-max=0 --no-save 搜索这个字符串把他修改成install -g -registry=https://registry.npm.taobao.org --cache-max=0 --no-save
3> 在web-dashboard下执行 npm install命令（需要等待很长时间）
EOF
-rf :flink-runtime-web
export MAVEN_OPTS="-Xms1024m -Xmx4096m"
-rf :flink-sql-connector-kinesis
#1.15.4
mvn install:install-file -DgroupId=io.confluent -DartifactId=kafka-schema-registry-client -Dversion=6.2.2 -Dpackaging=jar -Dfile=kafka-schema-registry-client-6.2.2.jar
#1.17.0
mvn install:install-file -DgroupId=io.confluent -DartifactId=kafka-schema-registry-client -Dversion=7.2.2 -Dpackaging=jar -Dfile=kafka-schema-registry-client-7.2.2.jar
-rf :flink-sql-avro-confluent-registry
cd flink-connectors && 单独编译 flink-connectors && cd ..
[ERROR] /Users/apple/flink-release-1.15.4/flink-formats/flink-avro-confluent-registry/src/test/java/org/apache/flink/formats/avro/registry/confluent/CachedSchemaCoderProviderTest.java:[89,21] 无法访问org.apache.kafka.common.Configurable
[ERROR]   找不到org.apache.kafka.common.Configurable的类文件承担
                <dependency>
                        <!-- include 2.0 server for tests  -->
                        <groupId>org.apache.kafka</groupId>
                        <artifactId>kafka_${scala.binary.version}</artifactId>
                        <version>${kafka.version}</version>
                        <exclusions>
                                <exclusion>
                                        <groupId>org.slf4j</groupId>
                                        <artifactId>slf4j-api</artifactId>
                                </exclusion>
                        </exclusions>
                        <scope>test</scope>
                </dependency>
-rf :flink-avro-confluent-registry
#1.15.4
mvn install:install-file -DgroupId=io.confluent -DartifactId=kafka-avro-serializer -Dversion=6.2.2 -Dpackaging=jar -Dfile=kafka-avro-serializer-6.2.2.jar
#1.17.0
mvn install:install-file -DgroupId=io.confluent -DartifactId=kafka-avro-serializer -Dversion=7.2.2 -Dpackaging=jar -Dfile=kafka-avro-serializer-7.2.2.jar
-rf :flink-end-to-end-tests-common-kafka
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin:3.8.0:testCompile (default-testCompile) on project flink-end-to-end-tests-common-kafka: Compilation failure
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-assembly-plugin:2.4:single (create-test-dependency-user-jar-depend) on project flink-clients: Failed to create assembly: Error creating assembly archive test-user-classloader-job-lib-jar: You must set at least one file. -> [Help 1]
flink-clients/pom.xml ，删除<build></build>
[ERROR] /Users/apple/flink-release-1.15.4/flink-end-to-end-tests/flink-end-to-end-tests-common-kafka/src/test/java/org/apache/flink/tests/util/kafka/SQLClientSchemaRegistryITCase.java:[124,20] 无法访问io.confluent.kafka.serializers.AbstractKafkaSchemaSerDe
[ERROR]   找不到io.confluent.kafka.serializers.AbstractKafkaSchemaSerDe的类文件
在flink-end-to-end-tests的pom.xml注释掉flink-end-to-end-tests-common-kafka子项目
#1.17.0
[ERROR] Failed to execute goal on project flink-sql-gateway-test: Could not resolve dependencies for project org.apache.flink:flink-sql-gateway-test:jar:1.17.0: Could not find artifact org.apache.flink:flink-sql-connector-hive-3.1.2_2.12:jar:1.17.0 in nexus-tencentyun (http://mirrors.cloud.tencent.com/nexus/repository/maven-public/) -> [Help 1]
mvn install:install-file -DgroupId=org.apache.flink -DartifactId=flink-sql-connector-hive-3.1.2_2.12 -Dversion=1.17.0 -Dpackaging=jar -Dfile=flink-sql-connector-hive-3.1.2_2.12-1.17.0.jar
#default hadoop2/hive2
[ERROR] Failed to execute goal on project flink-connector-hive_2.12: Could not resolve dependencies for project org.apache.flink:flink-connector-hive_2.12:jar:1.15.4: Could not find artifact org.pentaho:pentaho-aggdesigner-algorithm:jar:5.1.5-jhyde in nexus-tencentyun (http://mirrors.cloud.tencent.com/nexus/repository/maven-public/) -> [Help 1]
mvn install:install-file -DgroupId=org.pentaho -DartifactId=pentaho-aggdesigner-algorithm -Dversion=5.1.5-jhyde -Dpackaging=jar -Dfile=pentaho-aggdesigner-algorithm-5.1.5-jhyde.jar
-rf :flink-connector-hive_2.12
TARGET_BUILT=hadoop3hive3
HIVEREV=3.1.2
#HIVEREV=3.1.3
#TARGET_BUILT=hadoop2hive2
#HIVEREV=2.3.6
mv flink-dist/target/flink-${FLINK_VERSION}-bin/flink-${FLINK_VERSION} ${PRJ_FLINK_HOME}/flink-${FLINK_VERSION}-${TARGET_BUILT}
cp flink-connectors/flink-sql-connector-hive-${HIVEREV}/target/flink-sql-connector-hive-${HIVEREV}_${SCALA_VERSION}-${FLINK_VERSION}.jar ${PRJ_FLINK_HOME}/flink-${FLINK_VERSION}-${TARGET_BUILT}/lib/
cp flink-connectors/flink-connector-hive/target/flink-connector-hive_${SCALA_VERSION}-${FLINK_VERSION}.jar ${PRJ_FLINK_HOME}/flink-${FLINK_VERSION}-${TARGET_BUILT}/lib/
cp flink-connectors/flink-sql-connector-kafka/target/flink-sql-connector-kafka-${FLINK_VERSION}.jar ${PRJ_FLINK_HOME}/flink-${FLINK_VERSION}-${TARGET_BUILT}/lib/
cp flink-connectors/flink-sql-connector-hive-${HIVEREV}/target/flink-sql-connector-hive-${HIVEREV}_${SCALA_VERSION}-${FLINK_VERSION}.jar ${PRJ_FLINK_HOME}/flinkbk/${TARGET_BUILT}/
cp flink-connectors/flink-connector-hive/target/flink-connector-hive_${SCALA_VERSION}-${FLINK_VERSION}.jar ${PRJ_FLINK_HOME}/flinkbk/${TARGET_BUILT}/
cp flink-connectors/flink-sql-connector-kafka/target/flink-sql-connector-kafka-${FLINK_VERSION}.jar ${PRJ_FLINK_HOME}/flinkbk/${TARGET_BUILT}/
cd ..
mv flink-release-${FLINK_VERSION} ${PRJ_FLINK_HOME}/flink-release-${FLINK_VERSION}-${TARGET_BUILT}

tar xzvf ${PRJ_HOME}/hadoop/hadoop-${HADOOP_VERSION}.tar.gz
rm -rf hadoop-${HADOOP_VERSION}/share/doc
mkdir hadoop-${HADOOP_VERSION}/conf
cp conf/core-site.xml hadoop-${HADOOP_VERSION}/conf/
cp conf/hdfs-site.xml hadoop-${HADOOP_VERSION}/conf/
cp conf/core-site.xml hadoop-${HADOOP_VERSION}/etc/hadoop
cp conf/hdfs-site.xml hadoop-${HADOOP_VERSION}/etc/hadoop

#DOCKER_BUILDKIT=1 docker build ./ --progress=plain\
DOCKER_BUILDKIT=1 docker build -f Dockerfile-rebuild ./ --progress=plain\
 --build-arg FLINKOP_VERSION="${FLINKOP_VERSION}"\
 --build-arg JUICEFS_VERSION="${JUICEFS_VERSION}"\
 --build-arg STARROCKS_CONNECTOR_VERSION="${STARROCKS_CONNECTOR_VERSION}"\
 --build-arg FLINK_SHORT_VERSION="${FLINK_SHORT_VERSION}"\
 --build-arg SCALA_VERSION="${SCALA_VERSION}"\
 --build-arg FLINK_VERSION="${FLINK_VERSION}"\
 --build-arg HIVEREV="${HIVEREV}"\
 --build-arg HUDI_VERSION="${HUDI_VERSION}"\
 --build-arg HADOOP_VERSION="${HADOOP_VERSION}"\
 --build-arg CDC_VERSION="${CDC_VERSION}"\
 --build-arg TARGET_BUILT="${TARGET_BUILT}"\
 -t harbor.my.org:1080/flink/flink-juicefs-${TARGET_BUILT}:${FLINK_VERSION}
docker push harbor.my.org:1080/flink/flink-juicefs-${TARGET_BUILT}:${FLINK_VERSION}

#docker
ansible all -m shell -a"docker images|grep flink-juicefs"
ansible all -m shell -a"docker images|grep flink-juicefs|awk '{print \$3}'|xargs docker rmi -f"
#containerd
ansible all -m shell -a"crictl images|grep flink-juicefs"
ansible all -m shell -a"crictl images|grep flink-juicefs|awk '{print \$3}'|xargs crictl rmi"


cd ${PRJ_FLINK_HOME}/flink-kubernetes-operator-release-${FLINKOP_VERSION}
cd examples/flink-python-example
wget -c https://www.python.org/ftp/python/3.7.9/Python-3.7.9.tgz
cp ${PRJ_HOME}/image/pip.conf ./

file=Dockerfile
cp ${file} ${file}.bk
$SED -i "/FROM flink:1.15/i\ARG FLINK_VERSION=?" ${file}
$SED -i "/FROM flink:1.15/a\ARG PYTHON_VERSION=?" ${file}
$SED -i "/FROM flink:1.15/a\USER root" ${file}
$SED -i "s@FROM flink:1.15@FROM harbor.my.org:1080/flink/flink-juicefs:\${FLINK_VERSION}@g" ${file}
$SED -i "/RUN apt-get update/i\RUN sed -i 's@/archive.ubuntu.com/@/mirrors.aliyun.com/@g' /etc/apt/sources.list" ${file}
$SED -i "/RUN apt-get update/i\COPY Python-\${PYTHON_VERSION}.tgz ./" ${file}
$SED -i "s@Python-3.7.9@Python-\${PYTHON_VERSION}@g" ${file}
$SED -i "/wget https/d" ${file}
$SED -i "/RUN pip3 install/i\RUN mkdir /root/.pip\nCOPY pip.conf /root/.pip/" ${file}
$SED -i "/RUN mkdir \/opt\/flink\/usrlib/d" ${file}
$SED -i "/wget https/d" ${file}
$SED -i "/USER flink/d" ${file}
$SED -i "/ADD python_demo.py/a\USER flink" ${file}
$SED -i "s@ADD python_demo.py@ADD --chown=flink:root python_demo.py@g" ${file}

DOCKER_BUILDKIT=1 docker build ./ --progress=plain --build-arg FLINK_VERSION="${FLINK_VERSION}" --build-arg PYTHON_VERSION="${PYTHON_VERSION}" -t harbor.my.org:1080/flink/flink-juicefs-py37:${FLINK_VERSION}
docker push harbor.my.org:1080/flink/flink-juicefs-py37:${FLINK_VERSION}

#docker
ansible all -m shell -a"docker images|grep flink-juicefs-py37"
ansible all -m shell -a"docker images|grep flink-juicefs-py37|awk '{print \$3}'|xargs docker rmi -f"
#containerd
ansible all -m shell -a"crictl images|grep flink-juicefs-py37"
ansible all -m shell -a"crictl images|grep flink-juicefs-py37|awk '{print \$3}'|xargs crictl rmi"


cd ${PRJ_FLINK_HOME}/flink-kubernetes-operator-release-${FLINKOP_VERSION}
cd examples/flink-sql-runner-example

DOCKER_BUILDKIT=1 docker build ./ --progress=plain -t harbor.my.org:1080/flink/flink:${FLINK_VERSION}
docker push harbor.my.org:1080/flink/flink:${FLINK_VERSION}


cp sql-example.yaml sql-runner.yaml
file=sql-runner.yaml
$SED -i "s@image: flink-sql-runner-example:latest@image: harbor.my.org:1080/flink/flink:${FLINK_VERSION}@g" ${file}
$SED -i "s@  name: sql-example@  name: sql-runner@g" ${file}

kubectl create -n flink -f sql-runner.yaml
kubectl logs -f -n flink `kubectl get pod -n flink | grep sql-runner | awk '{print $1}'`
kubectl logs -n flink `kubectl get pod -n flink | grep sql-runner | awk '{print $1}'`
kubectl delete -n flink -f sql-runner.yaml
kubectl get pod -n flink |grep -v Running |grep sql-runner|awk '{print $1}'| xargs kubectl delete pod "$1" -n flink --force --grace-period=0

#docker
ansible all -m shell -a"docker images|grep 'flink '"
ansible all -m shell -a"docker images|grep 'flink '|awk '{print \$3}'|xargs docker rmi -f"
#containerd
ansible all -m shell -a"crictl images|grep 'flink '"
ansible all -m shell -a"crictl images|grep 'flink '|awk '{print \$3}'|xargs crictl rmi"

cp sql-example.yaml sql-runner.yaml
file=sql-runner.yaml
$SED -i "s@image: flink-sql-runner-example:latest@image: harbor.my.org:1080/flink/flink-juicefs:${FLINK_VERSION}@g" ${file}
$SED -i "s@  name: sql-example@  name: sql-runner@g" ${file}

kubectl apply -f clusterrole-endpoints-reader-flink.yaml
kubectl create clusterrolebinding endpoints-reader-default-flink \
  --clusterrole=endpoints-reader-flink  \
  --serviceaccount=flink:default
:<<EOF
kubectl delete clusterrolebinding endpoints-reader-default-flink
kubectl delete -f clusterrole-endpoints-reader-flink.yaml
EOF

kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- hadoop fs -mkdir -p /flink/checkpoints
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- hadoop fs -mkdir -p /flink/recovery

#开启harbor等同机器的docker远程访问，一些流作业操作平台要build成镜像push以后再在k8s上application session方式运行
#运行socat容器：
docker run -d --name dockerremote --restart always -p 2375:2375 -v /var/run/docker.sock:/var/run/docker.sock alpine/socat TCP4-LISTEN:2375,fork,reuseaddr UNIX-CONNECT:/var/run/docker.sock
#docker run -d -v /var/run/docker.sock:/var/run/docker.sock -p 2376:2375 bobrik/socat TCP4-LISTEN:2375,fork,reuseaddr UNIX-CONNECT:/var/run/docker.sock
:<<EOF
vim .bash_profile
添加内容：export DOCKER_HOST=tcp://localhost:2375
source .bash_profile
EOF
curl localhost:2375/version

