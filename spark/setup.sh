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

#SPARK_VERSION=3.3.0
SPARK_VERSION=3.3.1
HADOOP_VERSION=3.2.1
HIVEREV=3.1.2
RSS_VERSION=0.2.0-incubating

:<<EOF
wget -c https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz
docker build ./ -f Dockerfile.all --progress=plain --build-arg SPARK_VERSION="${SPARK_VERSION}" --build-arg HADOOP_VERSION="${HADOOP_VERSION}" --build-arg HIVEREV="${HIVEREV}" -t harbor.my.org:1080/bronzels/spark-hadoop-${HADOOP_VERSION}-juicefs:${SPARK_VERSION}
docker push harbor.my.org:1080/bronzels/spark-hadoop-${HADOOP_VERSION}-juicefs:${SPARK_VERSION}
EOF

#mv ../spark-${SPARK_VERSION}-bin-hadoop3.tgz ./
mv ../spark-${SPARK_VERSION}-bin-volcano-rss.tgz ./
:<<EOF
docker build ./ --progress=plain --build-arg SPARK_VERSION="${SPARK_VERSION}" --build-arg HADOOP_VERSION="${HADOOP_VERSION}" --build-arg HIVEREV="${HIVEREV}" --build-arg RSS_VERSION="${RSS_VERSION}" -t harbor.my.org:1080/bronzels/spark-juicefs:${SPARK_VERSION}
docker push harbor.my.org:1080/bronzels/spark-juicefs:${SPARK_VERSION}
EOF

#doris integration
#git clone https://github.com/apache/doris-spark-connector.git
unzip -x doris-spark-connector-master.zip
cd doris-spark-connector-master
cp custom_env.sh.tpl custom_env.sh
$SED -i 's@#export THRIFT_BIN=@export THRIFT_BIN=/usr/local/bin/thrift@g' custom_env.sh
cd spark-doris-connector/
GETOPT_PATH=`brew --prefix gnu-getopt`   # get the gnu-getopt execute path
export PATH="${GETOPT_PATH}/bin:$PATH"         # set gnu-getopt as default getopt
sh build.sh --spark 3.3.1 --scala 2.12


#starrocks integration
#git clone https://github.com/StarRocks/spark-starrocks-connector.git
unzip -x starrocks-connector-for-apache-spark-main.zip
cd starrocks-connector-for-apache-spark-main
file=build.sh
cp ${file} ${file}.bk
$SED -i 's/export STARROCKS_SPARK_VERSION=3.1.2/export STARROCKS_SPARK_VERSION=3.3.1/g' ${file}
#依赖starrocks-stream-load-sdk需要先编译flink starrrocks connector
:<<EOF
程序包org.codehaus.jackson不存在
pom添加依赖项
    <dependency>
        <groupId>org.codehaus.jackson</groupId>
        <artifactId>jackson-mapper-asl</artifactId>
        <version>1.9.13</version>
    </dependency>
EOF
#sh build.sh 3
    export STARROCKS_SPARK_BASE_VERSION=3
    export STARROCKS_SPARK_VERSION=3.3.1
    export STARROCKS_SCALA_VERSION=2.12
:<<EOF
[ERROR] /Volumes/data/workspace/dockerfile/spark/starrocks-connector-for-apache-spark-main/src/main/java/com/starrocks/connector/spark/sql/conf/WriteStarRocksConfig.java:[175,36] 不兼容的类型: java.lang.String[]无法转换为java.lang.String
EOF
mvn clean package -DskipTests -Dmaven.test.skip=true -Dmaven.javadoc.skip=true
mvn install:install-file -DgroupId=com.starrocks -DartifactId=starrocks-spark3_2.12 -Dversion=1.0.0 -Dpackaging=jar -Dfile=target/starrocks-spark3_2.12-1.0.0.jar
git clone git@github.com:StarRocks/demo.git
unzip -x demo-master.zip
mvn install:install-file -DgroupId=org.apache.calcite -DartifactId=calcite-avatica -Dversion=1.2.0-incubating -Dpackaging=jar -Dfile=calcite-avatica-1.2.0-incubating.jar
:<<EOF
失败，放弃
1，导入数据提示com.starrocks.connector.spark.sql.StarrocksRelation@46a9c368 does not allow insertion
2，改成sparksql从doris用temporary view SELECT数据，提示Could not initialize class com.starrocks.shaded.org.apache.arrow.vector.types.pojo.Schema，但是把jar包解开这个类有的，这是个shade plugin重命名的包，可能为了避免包冲突
3，connector编译时pom的spark版本改到3.1.2，在3.3.1的spark image上跑，还是一样的does not allow insertion错误
EOF



#hudi integration
#HUDI_VERSION=0.13.0
HUDI_VERSION=0.12.2
wget -c https://github.com/apache/hudi/archive/refs/tags/release-${HUDI_VERSION}.tar.gz
tar xzvf hudi-release-${HUDI_VERSION}.tar.gz
cd hudi-release-${HUDI_VERSION}
#flink, jdk11
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-11.0.17.jdk/Contents/Home
JDK=11
#spark, jdk8
JDK=8
mvn clean package -DskipTests -Dspark3.3 -Dflink1.15 -Dscala-2.12 -Dhadoop.version=3.2.1 -Pflink-bundle-shade-hive3
  mvn install:install-file -DgroupId=io.confluent -DartifactId=kafka-avro-serializer -Dversion=5.3.4 -Dpackaging=jar -Dfile=kafka-avro-serializer-5.3.4.jar
  mvn install:install-file -DgroupId=io.confluent -DartifactId=common-config -Dversion=5.3.4 -Dpackaging=jar -Dfile=common-config-5.3.4.jar
  mvn install:install-file -DgroupId=io.confluent -DartifactId=common-utils -Dversion=5.3.4 -Dpackaging=jar -Dfile=common-utils-5.3.4.jar
  mvn install:install-file -DgroupId=io.confluent -DartifactId=kafka-schema-registry-client -Dversion=5.3.4 -Dpackaging=jar -Dfile=kafka-schema-registry-client-5.3.4.jar
mv packaging packaging.${JDK}
#0.12.2以下版本
#修改hadoop3兼容问题
file=hudi-common/src/main/java/org/apache/hudi/common/table/log/block/HoodieParquetDataBlock.java
$SED -i 's@try (FSDataOutputStream outputStream = new FSDataOutputStream(baos))@try (FSDataOutputStream outputStream = new FSDataOutputStream(baos, null))@g' ${file}

cp ${PRJ_HOME}/juicefs/core-site.xml ./

kubectl cp -n spark-operator spark-test:/app/hdfs/entrypoint.sh entrypoint.sh
chmod a+x entrypoint.sh
file=entrypoint.sh
cp ${file} ${file}.bk
$SED -i '/case "$1" in/i\SPARK_CLASSPATH="/opt/spark/conf::/opt/spark/jars/*:/opt/spark/imgconf";' ${file}
cp ${PRJ_HOME}/juicefs/juicefs-hadoop-1.0.2.jar ./

DOCKER_BUILDKIT=1 docker build ./ --progress=plain --build-arg java_image_tag=8-jre --build-arg SPARK_VERSION="${SPARK_VERSION}" --build-arg HADOOP_VERSION="${HADOOP_VERSION}" --build-arg HIVEREV="${HIVEREV}" --build-arg RSS_VERSION="${RSS_VERSION}" -t harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss:${SPARK_VERSION}
docker push harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss:${SPARK_VERSION}


#SPARK_CLASSPATH="/opt/spark/jars/*:/opt/spark/conf";
unset SPARK_CLASSPATH
cat /opt/spark/conf/spark.properties
ls -l /opt/spark/conf
cat /opt/spark/conf/cores-site.xml

ansible all -m shell -a"crictl images|grep spark-juicefs-volcano-rss|awk '{print \$3}'|xargs crictl rmi"

#mv ./spark-${SPARK_VERSION}-bin-hadoop3.tgz ../
mv ./spark-${SPARK_VERSION}-bin-volcano-rss.tgz ../
cp ../image/sources-22.04.list sources.list
#docker build ./ -f Dockerfile.tpc --progress=plain --build-arg SPARK_VERSION="${SPARK_VERSION}" -t harbor.my.org:1080/bronzels/spark-juicefs-tpc:${SPARK_VERSION}
:<<EOF
docker build ./ -f Dockerfile.tpc --progress=plain -t harbor.my.org:1080/bronzels/spark-juicefs-tpc:${SPARK_VERSION}
docker push harbor.my.org:1080/bronzels/spark-juicefs-tpc:${SPARK_VERSION}
EOF
DOCKER_BUILDKIT=1 docker build ./ -f Dockerfile.tpc --progress=plain -t harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss-tpc:${SPARK_VERSION}
docker push harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss-tpc:${SPARK_VERSION}

wget -c https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/releases/download/spark-operator-chart-1.1.26/spark-operator-1.1.26.tgz

helm repo add spark-operator https://googlecloudplatform.github.io/spark-on-k8s-operator

#helm install my spark-operator/spark-operator --namespace spark-operator --create-namespace --set image.tag=v1beta2-1.3.3-3.1.1
helm install my spark-operator/spark-operator \
  --namespace spark-operator --create-namespace \
  --set image.repository=registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-spark-operator-spark-operator-v1beta2-1.3.0-3.1.1 \
  --set image.tag=1.0
helm uninstall my -n spark-operator

#gcr.io/spark-operator/spark-operator:v1beta2-1.3.3-3.1.1
#registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-spark-operator-spark-operator-v1beta2-1.3.3-3.1.1:

#gcr.io/spark-operator/spark-operator:v1beta2-1.3.2-3.1.1
#registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-spark-operator-spark-operator-v1beta2-1.3.2-3.1.1:

#gcr.io/spark-operator/spark-operator:v1beta2-1.3.0-3.1.1
#registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-spark-operator-spark-operator-v1beta2-1.3.0-3.1.1:

#docker
ansible all -m shell -a"docker images|grep spark-juicefs"
ansible all -m shell -a"docker images|grep spark-juicefs|awk '{print \$3}'|xargs docker rmi -f"
#containerd
ansible all -m shell -a"crictl images|grep spark-juicefs"
ansible all -m shell -a"crictl images|grep spark-juicefs|awk '{print \$3}'|xargs crictl rmi"

kubectl apply -f app-pi-nfs-pvc.yaml -n spark-operator
kubectl apply -f app-pi.yaml -n spark-operator
:<<EOF
kubectl delete -f app-pi.yaml -n spark-operator
kubectl delete -f app-pi-nfs-pvc.yaml -n spark-operator
EOF

kubectl create cm spark-config-sql-runner -n spark-operator --from-file=conf
  sparkConf:
    "spark.kubernetes.scheduler.volcano.podGroupTemplateFile": "/opt/spark/work-dir/podgroups/volcano-halfavailable-podgroup.yaml"
    "spark.executor.memory": "4g"

COPY --from=hadoop --chown=hdfs:root /app/hdfs/hadoop /opt/hadoop
RUN rm -rf /opt/hadoop/share/doc
ENV HADOOP_HOME=/opt/hadoop \
    HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
ENV PATH=${PATH}:${HADOOP_HOME}/bin


kubectl apply -f clusterrole-endpoints-reader-spark.yaml
kubectl create clusterrolebinding endpoints-reader-default-spark \
  --clusterrole=endpoints-reader-spark  \
  --serviceaccount=spark-operator:default
:<<EOF
kubectl delete clusterrolebinding endpoints-reader-default-spark
kubectl delete -f clusterrole-endpoints-reader-spark.yaml
EOF