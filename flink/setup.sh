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
FLINK_VERSION=1.16.1
FLINK_SHORT_VERSION=1.16
:<<EOF
FLINK_VERSION=1.15.3
FLINK_SHORT_VERSION=1.15

FLINK_VERSION=1.14.6
FLINK_VERSION=1.14.0
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

#HUDI_VERSION=0.12.2
HUDI_VERSION=0.13.0

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
#cp ${PRJ_HOME}/juicefs/juicefs-hadoop-${JUICEFS_VERSION}-jdk11-debian11.jar ./
cp ${PRJ_HOME}/juicefs/juicefs-hadoop-${JUICEFS_VERSION}-jdk11-ubuntu22.04.jar ./

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
CREATE CATALOG hive WITH (
    'type' = 'hive',
    'default-database' = 'default',
    'hive-conf-dir' = '/opt/flink/hiveconf',
    'hadoop-conf-dir'='/opt/hadoop/conf'
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

kubectl cp -n flink flink-test:/docker-entrypoint.sh docker-entrypoint.sh

wget -c https://github.com/apache/flink/archive/refs/tags/release-1.15.3.tar.gz
cd flink-release-${FLINK_VERSION}
mvn clean install -DskipTests -Dmaven.test.skip=true -Dspotless.check.skip=true -Dfast -T 1C -Dhadoop.version=3.1.1 -Dmaven.javadoc.skip=true -Dcheckstyle.skip=true -Dlicense.skip=true -Drat.ignoreErrors=true
:<<EOF
[ERROR] Failed to execute goal com.github.eirslett:frontend-maven-plugin:1.11.0:npm (npm install) on project flink-runtime-web: Failed to run task: 'npm ci --cache-max=0 --no-save ${npm.proxy}' failed. org.apache.commons.exec.ExecuteException: Process exited with an error: 1 (Exit value: 1) -> [Help 1]
修改flink-runtime-web/pom.xml的<id>npm install</id>处的configuration为install -g -registry=https://registry.npm.taobao
.org --cache-max=0 --no-save

          <execution>
                        <id>npm install</id>
                        <goals>
                            <goal>npm</goal>
                        </goals>
                        <configuration>
                            <arguments>install -g -registry=https://registry.npm.taobao
.org --cache-max=0 --no-save</arguments>
                        </configuration>
          </execution>
EOF

tar xzvf ${PRJ_HOME}/hadoop/hadoop-${HADOOP_VERSION}.tar.gz
rm -rf hadoop-${HADOOP_VERSION}/share/doc
mkdir hadoop-${HADOOP_VERSION}/conf
cp conf/core-site.xml hadoop-${HADOOP_VERSION}/conf/
cp conf/hdfs-site.xml hadoop-${HADOOP_VERSION}/conf/
cp conf/core-site.xml hadoop-${HADOOP_VERSION}/etc/hadoop
cp conf/hdfs-site.xml hadoop-${HADOOP_VERSION}/etc/hadoop

DOCKER_BUILDKIT=1 docker build ./ --progress=plain\
 --build-arg FLINKOP_VERSION="${FLINKOP_VERSION}"\
 --build-arg JUICEFS_VERSION="${JUICEFS_VERSION}"\
 --build-arg STARROCKS_CONNECTOR_VERSION="${STARROCKS_CONNECTOR_VERSION}"\
 --build-arg FLINK_SHORT_VERSION="${FLINK_SHORT_VERSION}"\
 --build-arg SCALA_VERSION="${SCALA_VERSION}"\
 --build-arg FLINK_VERSION="${FLINK_VERSION}"\
 --build-arg HIVEREV="${HIVEREV}"\
 --build-arg HUDI_VERSION="${HUDI_VERSION}"\
 --build-arg HADOOP_VERSION="${HADOOP_VERSION}"\
 -t harbor.my.org:1080/flink/flink-juicefs:${FLINK_VERSION}
docker push harbor.my.org:1080/flink/flink-juicefs:${FLINK_VERSION}

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
  kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- \
    rm -f ${SQL_FILE_HOME}/${torun}
  kubectl cp ${torun} -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'`:${SQL_FILE_HOME}/${torun}
  kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- \
    hadoop fs -rm -f ${HDFS_SQL_FILE_HOME}/${torun}
  kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- \
    hadoop fs -put ${torun} ${HDFS_SQL_FILE_HOME}/${torun}
  kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- \
    hadoop fs -cat ${HDFS_SQL_FILE_HOME}/${torun}
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

kubectl apply -f test/flink-test.yaml -n flink
kubectl delete -f test/flink-test.yaml -n flink
kubectl delete pod flink-test -n flink --force --grace-period=0

kubectl cp -n flink flink-test:/opt/flink flink
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


kubectl apply -f clusterrole-endpoints-reader-flink.yaml
kubectl create clusterrolebinding endpoints-reader-default-flink \
  --clusterrole=endpoints-reader-flink  \
  --serviceaccount=flink:default
:<<EOF
kubectl delete clusterrolebinding endpoints-reader-default-flink
kubectl delete -f clusterrole-endpoints-reader-flink.yaml
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
USE hive.tpcds_bin_partitioned_orc_10;SHOW TABLES;
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

kubectl cp -f docker-entrypoint.sh -n flink `kubectl get pod -n flink | grep flink-test | awk '{print $1}'`:/docker-entrypoint.sh

kubectl exec -it -n flink `kubectl get pod -n flink | grep flink-test | awk '{print $1}'` -- bash
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
  FLINK_VERSION=1.14.0
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
Flink SQL> set table.sql-dialect=hive;
[ERROR] Could not execute SQL statement. Reason:
org.apache.flink.table.api.ValidationException: Could not find any factory for identifier 'hive' that implements 'org.apache.flink.table.planner.delegation.ParserFactory' in the classpath.

Available factory identifiers are:



kubectl exec -it -n flink `kubectl get pod -n flink | grep my-first-application-cluster | awk '{print $1}'` -- sql-client.sh embedded -i /opt/flink/usrlib/setting.sql
kubectl exec -it -n flink `kubectl get pod -n flink | grep my-first-application-cluster | awk '{print $1}'` -- sql-client.sh
  SHOW TABLES;
  SELECT * FROM date_dim LIMIT 5;
