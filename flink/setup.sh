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

cd ${FLINK_HOME}/

#2 libs for starrrocks spark connector
tar xzvf starrocks-connector-for-apache-flink-1.2.5.tar.gz
cd starrocks-connector-for-apache-flink-1.2.5
cd starrocks-stream-load-sdk/
mvn clean install -DskipTests -Dmaven.test.skip=true -Dmaven.javadoc.skip=true
cd ..
cd starrocks-thrift-sdk/
file=pom.xml
cp ${file} ${file}.bk
#$SED -i '/<build>/a\<pluginManagement>' ${file}
#$SED -i '/<\/build>/i\<\/pluginManagement>' ${file}
file=pom.xml
cp ${file} ${file}.bk
$SED -i 's/<phase>package<\/phase>/<phase>install<\/phase>/g' ${file}
#./build-thrift.sh
thrift -r -gen java gensrc/StarrocksExternalService.thrift
if [ ! -d "src/main/java/com/starrocks/thrift" ]; then
    mkdir -p src/main/java/com/starrocks/thrift
else
    rm -rf src/main/java/com/starrocks/thrift/*
fi
cp -r gen-java/com/starrocks/thrift/* src/main/java/com/starrocks/thrift
rm -rf gen-java
#出现失败maven-gpg-plugin gpg: no default secret key: No secret key
#gpg --gen-key
#mvn clean install -DskipTests -Dmaven.test.skip=true -Dgpg.skip -Dmaven.javadoc.skip=true
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
cp ${PRJ_HOME}/juicefs/juicefs-hadoop-${JUICEFS_VERSION}-jdk11-debian11.jar ./
cp ${PRJ_HOME}/juicefs/core-site.xml ./
cp ${PRJ_HOME}/spark/hdfs-site.xml ./
cp ${PRJ_HOME}/spark/hive-site.xml ./

DOCKER_BUILDKIT=1 docker build ./ --progress=plain --build-arg FLINK_SHORT_VERSION="${FLINK_SHORT_VERSION}" --build-arg FLINKOP_VERSION="${FLINKOP_VERSION}" --build-arg JUICEFS_VERSION="${JUICEFS_VERSION}" --build-arg STARROCKS_CONNECTOR_VERSION="${STARROCKS_CONNECTOR_VERSION}" -t harbor.my.org:1080/flink/flink-juicefs:${FLINK_VERSION}
docker push harbor.my.org:1080/flink/flink-juicefs:${FLINK_VERSION}

#docker
ansible all -m shell -a"docker images|grep flink-kubernetes-operator-juicefs"
ansible all -m shell -a"docker images|grep flink-kubernetes-operator-juicefs|awk '{print \$3}'|xargs docker rmi -f"
#containerd
ansible all -m shell -a"crictl images|grep flink-kubernetes-operator-juicefs"
ansible all -m shell -a"crictl images|grep flink-kubernetes-operator-juicefs|awk '{print \$3}'|xargs crictl rmi"
