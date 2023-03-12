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

FLINK_HOME=${PRJ_HOME}/flink
:<<EOF
FLINK_VERSION=1.16.1
FLINK_SHORT_VERSION=1.16
FLINKOP_VERSION=1.4.0
EOF
FLINK_VERSION=1.15.3
FLINK_SHORT_VERSION=1.15
FLINKOP_VERSION=1.3.1

HADOOP_VERSION=3.2.1
HIVEREV=3.1.2

JUICEFS_VERSION=1.0.2

STARROCKS_CONNECTOR_VERSION=1.2.5

SCALA_VERSION=2.12

HUDI_VERSION=0.12.2

PYTHON_VERSION=3.7.9

cd ${FLINK_HOME}/

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
cd ${FLINK_HOME}/flink-kubernetes-operator-release-${FLINKOP_VERSION}
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

cd ${FLINK_HOME}/flink-kubernetes-operator-release-${FLINKOP_VERSION}/helm/flink-kubernetes-operator
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
kubectl get pod -n flink |grep -v Running |awk '{print $1}'| xargs kubectl delete pod "$1" -n flink --force --grace-period=0
kubectl delete RoleBinding flink-role-binding -n flink
kubectl delete Role flink -n flink
kubectl delete ServiceAccount flink -n flink

kubectl delete ns flink --force --grace-period=0

wget -c https://raw.githubusercontent.com/apache/flink-kubernetes-operator/release-1.4/examples/basic.yaml
kubectl create -n flink -f basic.yaml

kubectl exec -it -n flink `kubectl get pod -n flink | grep Running | grep operator | awk '{print $1}'` -- bash


cd ${FLINK_HOME}/flink-kubernetes-operator-release-${FLINKOP_VERSION}
cd examples/flink-sql-runner-example
mvn -ntp clean install -DskipTests=true -Dmaven.test.skip=true -Dmaven.javadoc.skip=true
cd ${FLINK_HOME}/flink-kubernetes-operator-release-${FLINKOP_VERSION}
cd examples/kubernetes-client-examples
mvn -ntp clean install -DskipTests=true -Dmaven.test.skip=true -Dmaven.javadoc.skip=true
cd ${FLINK_HOME}/flink-kubernetes-operator-release-${FLINKOP_VERSION}

cd ${FLINK_HOME}
#cp ${PRJ_HOME}/juicefs/juicefs-hadoop-${JUICEFS_VERSION}-jdk11-debian11.jar ./
cp ${PRJ_HOME}/juicefs/juicefs-hadoop-${JUICEFS_VERSION}-jdk11-ubuntu22.04.jar ./

mkdir -p conf/hadoop
cp ${PRJ_HOME}/juicefs/core-site.xml conf/hadoop/
cp ${PRJ_HOME}/spark/hdfs-site.xml conf/hadoop/
kubectl create cm hadoop-config-sql-runner -n flink --from-file=conf/hadoop

cp ${PRJ_HOME}/spark/hive-site.xml ./

cd ${FLINK_HOME}
cat << EOF > setting.sql
-- set up the default properties
SET sql-client.execution.mode=batch;
SET parallism.default=10;
SET pipeline.auto-watermark-interval=500;

CREATE CATALOG hive WITH (
    'type' = 'hive',
    'default-database' = 'default',
    'hive-conf-dir' = '/opt/flink/conf',
    'hadoop-conf-dir'='/opt/flink/conf'
);
-- set the HiveCatalog as the current catalog of the session
USE CATALOG hive;
EOF

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
cat << EOF > conf/flink/flink-conf.yaml
taskmanager.numberOfTaskSlots: 2
classloader.check-leaked-classloader: false
EOF
cat << EOF > conf/flink/log4j.properties
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
kubectl create cm flink-config-sql-runner -n flink --from-file=conf/hadoop

DOCKER_BUILDKIT=1 docker build ./ --progress=plain\
 --build-arg FLINKOP_VERSION="${FLINKOP_VERSION}"\
 --build-arg JUICEFS_VERSION="${JUICEFS_VERSION}"\
 --build-arg STARROCKS_CONNECTOR_VERSION="${STARROCKS_CONNECTOR_VERSION}"\
 --build-arg FLINK_SHORT_VERSION="${FLINK_SHORT_VERSION}"\
 --build-arg SCALA_VERSION="${SCALA_VERSION}"\
 --build-arg FLINK_VERSION="${FLINK_VERSION}"\
 --build-arg HIVEREV="${HIVEREV}"\
 --build-arg HUDI_VERSION="${HUDI_VERSION}"\
 -t harbor.my.org:1080/flink/flink-juicefs:${FLINK_VERSION}
docker push harbor.my.org:1080/flink/flink-juicefs:${FLINK_VERSION}

#docker
ansible all -m shell -a"docker images|grep flink-juicefs"
ansible all -m shell -a"docker images|grep flink-juicefs|awk '{print \$3}'|xargs docker rmi -f"
#containerd
ansible all -m shell -a"crictl images|grep flink-juicefs"
ansible all -m shell -a"crictl images|grep flink-juicefs|awk '{print \$3}'|xargs crictl rmi"


cd ${FLINK_HOME}/flink-kubernetes-operator-release-${FLINKOP_VERSION}
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


