if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Mac detected."
    #mac
    os=darwin
    MYHOME=/Volumes/data
    SED=gsed
    bin=/Users/apple/bin
else
    echo "Assuming linux by default."
    #linux
    os=linux
    MYHOME=~
    SED=sed
    bin=/usr/local/bin
fi

WORK_HOME=${MYHOME}/workspace
PRJ_HOME=${WORK_HOME}/dockerfile
PRESTO_HOME=${PRJ_HOME}/presto

TRINO_VERSION=406
TRINO_HELM_VERSION=0.9.0

PRESTO_VERSION=0.279

JUICEFS_VERSION=1.0.2

maven_version=3.8.6

maven_home=${MYHOME}/apache-maven-${maven_version}
m2_home=${MYHOME}/m2
go_path=${MYHOME}/gopath

cd ${PRESTO_HOME}

# trino start--------------------------------------------
wget -c https://github.com/trinodb/trino/archive/refs/tags/406.zip
gunzip -x trino-${TRINO_VERSION}.zip

cd trino-${TRINO_VERSION}

#cli编译成功即可
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home
#./mvnw clean install -DskipTests
mvn clean install -DskipTests -Dmaven.test.skip=true
  mvn install:install-file -DgroupId=io.confluent -DartifactId=kafka-schema-serializer -Dversion=5.5.0 -Dpackaging=jar -Dfile=kafka-json-schema-serializer-5.5.0.jar
  mvn install:install-file -DgroupId=io.confluent -DartifactId=kafka-avro-serializer -Dversion=5.5.2 -Dpackaging=jar -Dfile=kafka-avro-serializer-5.5.2.jar
:<<EOF
    <repositories>
        <repository>
            <id>aliyun</id>
            <url>https://maven.aliyun.com/repository/public</url>
            <releases>
                <enabled>true</enabled>
            </releases>
            <snapshots>
                <enabled>false</enabled>
            </snapshots>
        </repository>
    </repositories>
    <pluginRepositories>
        <pluginRepository>
            <id>aliyun-plugin</id>
            <url>https://maven.aliyun.com/repository/public</url>
            <releases>
                <enabled>true</enabled>
            </releases>
            <snapshots>
                <enabled>false</enabled>
            </snapshots>
        </pluginRepository>
    </pluginRepositories>
    删除maven-enforcer-plugin的ndash注释
EOF

wget -c https://repo1.maven.org/maven2/io/trino/trino-server/${TRINO_VERSION}/trino-server-${TRINO_VERSION}.tar.gz

:<<EOF
tar xzvf trino-server-${TRINO_VERSION}.tar.gz
cd trino-server-${TRINO_VERSION}
EOF

cd core/docker

file=Dockerfile
#cp ${file}.bk ${file}
cp ${file} ${file}.bk
cp ${PRESTO_HOME}/trino-${TRINO_VERSION}/client/trino-cli/target/trino-cli-406-executable.jar ./

tar xzvf ${PRESTO_HOME}/trino-server-${TRINO_VERSION}.tar.gz

$SED -i '/FROM eclipse-temurin:17-jdk AS builder/i\FROM harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss:3.3.1 AS builder' ${file}
$SED -i 's@FROM eclipse-temurin:17-jdk@FROM registry.cn-hangzhou.aliyuncs.com/bronzels/eclipse-temurin-17-jdk:1.0 AS base@g' ${file}
$SED -i '/    apt-get update -q &&/i\    sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list && \\' ${file}
$SED -i 's@    apt-get install -y -q less python3 curl@    apt-get install -y -q less python3 curl dnsutils bc@g' ${file}
$SED -i 's@COPY --chown=trino:trino default/etc /etc/trino@#COPY --chown=trino:trino default/etc /etc/trino@g' ${file}
$SED -i 's@CMD \[@#CMD \[@g' ${file}

mkdir hadoopconf
cp ${PRJ_HOME}/juicefs/core-site.xml hadoopconf/
cp ${PRJ_HOME}/spark/hdfs-site.xml hadoopconf/

cp ${PRJ_HOME}/juicefs/juicefs-${JUICEFS_VERSION}.tar.gz ./
cp ${PRJ_HOME}/image/go1.19.2.linux-amd64.tar.gz ./

cat << \EOF >> ${file}
ARG JUICEFS_VERSION=
ENV MY_HOME=/usr/lib/trino
COPY --chown=trino:trino bin/* ${MY_HOME}/bin/
RUN mkdir /usr/lib/trino/hadoopconf && chown trino:trino /usr/lib/trino/hadoopconf
COPY --from=spark --chown=trino:trino juicefs-hadoop-${JUICEFS_VERSION}-jdk17.jar ${MY_HOME}/plugin/hive/
COPY --from=spark --chown=trino:trino juicefs-hadoop-${JUICEFS_VERSION}-jdk17.jar ${MY_HOME}/plugin/hudi/
COPY --from=spark --chown=trino:trino juicefs-hadoop-${JUICEFS_VERSION}-jdk17.jar ${MY_HOME}/plugin/iceberg/
COPY --from=spark --chown=trino:trino /app/hdfs/spark/conf/* /usr/lib/trino/hadoopconf/
EOF

mv ${maven_home} ./apache-maven
mkdir .m2
cp ${MYHOME}/m2/settings.xml .m2/
mv ${go_path} ./
DOCKER_BUILDKIT=1 docker build ./ --progress=plain --build-arg TRINO_VERSION="${TRINO_VERSION}" --build-arg JUICEFS_VERSION="${JUICEFS_VERSION}" -t harbor.my.org:1080/presto/trino-juicefs:${TRINO_VERSION}
docker push harbor.my.org:1080/presto/trino-juicefs:${TRINO_VERSION}
mv apache-maven ${MYHOME}/apache-maven-${maven_version}
mv gopath ${MYHOME}/

#docker
ansible all -m shell -a"docker images|grep trino-juicefs"
ansible all -m shell -a"docker images|grep trino-juicefs|awk '{print \$3}'|xargs docker rmi -f"
#containerd
ansible all -m shell -a"crictl images|grep trino-juicefs"
ansible all -m shell -a"crictl images|grep trino-juicefs|awk '{print \$3}'|xargs crictl rmi"

cd ${PRESTO_HOME}
helm repo add trino https://trinodb.github.io/charts/
helm repo update

helm pull trino/trino --version ${TRINO_HELM_VERSION}
tar xzvf trino-${TRINO_HELM_VERSION}.tgz
mv trino trino-helm-${TRINO_HELM_VERSION}

cd trino-helm-${TRINO_HELM_VERSION}

file=values.yaml
cp ${file}.bk ${file}
cp ${file} ${file}.bk
$SED -i "s/additionalCatalogs: {}/additionalCatalogs:/g" ${file}
$SED -i "/additionalCatalogs:/a\  hive: |-\n    connector.name=hive\n    hive.metastore.uri=thrift:\/\/hive-service.hadoop.svc.cluster.local:9083" ${file}

:<<EOF
for prj in {coordinator,worker}
do
  file=configmap-${prj}.yaml
  #cp templates/${file} ${file}.bk
  $SED -i "/.Values.server.${prj}ExtraConfig | indent 4/a\    hive.config.resources=/usr/lib/trino/hadoopconf/core-site.xml,/usr/lib/trino/hadoopconf/hdfs-site.xml" ${file}
done
EOF

#worker和coordinator一起启动，worker连不上coordinator出错无法恢复
file=deployment-worker.yaml
#cp templates/${file} ${file}.bk
$SED -i '/          image: /a\          command: [ "\/bin\/bash", "-ce", "until nslookup my-trino; do sleep 5; echo waiting svc ready; done && until curl http:\/\/my-trino:8080; do sleep 5; echo waiting http end ready; done && \/usr\/lib\/trino\/bin\/run-trino" ]' templates/${file}
#until nslookup my-trino; do sleep 5; echo waiting svc ready; done && until curl http://my-trino:8080; do sleep 5; echo waiting http end ready; done

:<<EOF
针对错误
Query 20230222_090824_00003_suc7t failed: class io.juicefs.JuiceFileSystemImpl$FileInputStream (in unnamed module @0x3c0403a) cannot access class sun.nio.ch.DirectBuffer (in module java.base) because module java.base does not export sun.nio.ch to unnamed module @0x3c0403a
EOF
cat << EOF > jdk17-uname.txt
    --add-opens=java.base/java.lang=ALL-UNNAMED
    --add-opens=java.base/java.lang.invoke=ALL-UNNAMED
    --add-opens=java.base/java.lang.reflect=ALL-UNNAMED
    --add-opens=java.base/java.io=ALL-UNNAMED
    --add-opens=java.base/java.net=ALL-UNNAMED
    --add-opens=java.base/java.nio=ALL-UNNAMED
    --add-opens=java.base/java.util=ALL-UNNAMED
    --add-opens=java.base/java.util.concurrent=ALL-UNNAMED
    --add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED
    --add-opens=java.base/sun.nio.ch=ALL-UNNAMED
    --add-opens=java.base/sun.nio.cs=ALL-UNNAMED
    --add-opens=java.base/sun.security.action=ALL-UNNAMED
    --add-opens=java.base/sun.util.calendar=ALL-UNNAMED
    --add-opens=java.security.jgss/sun.security.krb5=ALL-UNNAMED
EOF
for prj in {coordinator,worker}
do
  file=configmap-${prj}.yaml
  #cp templates/${file} ${file}.bk
  $SED -i '/    -server/r jdk17-uname.txt' templates/${file}
done

file=configmap-catalog.yaml
#cp templates/${file} ${file}.bk
cat << EOF >> ${file}
    connector.name=hive
    hive.metastore.uri=thrift://hive-service.hadoop.svc.cluster.local:9083
    hive.config.resources=/usr/lib/trino/hadoopconf/core-site.xml,/usr/lib/trino/hadoopconf/hdfs-site.xml
EOF

kubectl create ns presto

helm install my -n presto -f values.yaml \
  --set server.workers=3 \
  --set server.config.query.maxMemory=24GB \
  --set server.config.query.maxMemoryPerNode=8GB \
  --set coordinator.jvm.maxHeapSize=24G \
  --set worker.jvm.maxHeapSize=16G \
  --set image.repository=harbor.my.org:1080/presto/trino-juicefs \
  --set image.tag=${TRINO_VERSION} \
  ./

watch kubectl get all -n presto
kubectl get all -n presto -o wide

helm uninstall my -n presto
kubectl get pod -n presto |grep -v Running |awk '{print $1}'| xargs kubectl delete pod "$1" -n presto --force --grace-period=0

kubectl get cm -n presto my-trino-coordinator -o yaml | grep hive.config.resources
kubectl get cm -n presto my-trino-worker -o yaml | grep hive.config.resources

kubectl port-forward -n presto svc/my-trino 8080:8080 &

kubectl logs -n presto `kubectl get pod -n presto | grep trino-coordinator | awk '{print $1}'`
kubectl get pod -n presto | grep trino-worker | awk '{print $1}' | xargs kubectl logs -n presto
kubectl logs -n presto my-trino-worker-76fdd9f886-bsqhf

kubectl cp -n presto `kubectl get pod -n presto | grep Running | grep coordinator | awk '{print $1}'`:/usr/lib/trino/plugin/hive/juicefs-hadoop-1.0.2-jdk17.jar ${PRJ_HOME}/juicefs/juicefs-hadoop-1.0.2-jdk17.jar

kubectl exec -it -n presto `kubectl get pod -n presto | grep Running | grep trino-coordinator | awk '{print $1}'` -- \
bash
kubectl exec -it -n presto `kubectl get pod -n presto | grep Running | grep trino-coordinator | awk '{print $1}'` -- \
  trino --server my-trino:8080 --catalog hive --schema tpcds_bin_partitioned_orc_10
    SHOW TABLES;
    SELECT * FROM time_dim LIMIT 5;

kubectl exec -it -n presto `kubectl get pod -n presto | grep Running | grep trino-coordinator | awk '{print $1}'` -- \
bash

kubectl exec -it -n presto my-trino-worker-76fdd9f886-bsqhf -- bash


:<<EOF
  --set pullPolicy=Always \
  --set pullPolicy=IfNotPresent \

NAME: my
LAST DEPLOYED: Tue Feb 14 17:00:55 2023
NAMESPACE: presto
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace presto -l "app=trino,release=my,component=coordinator" -o jsonpath="{.items[0].metadata.name}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl port-forward $POD_NAME 8080:8080
EOF
# trino end--------------------------------------------


#cli编译成功即可
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-11.0.17.jdk/Contents/Home
mvn clean install -DskipTests -Dmaven.test.skip=true
  mvn install:install-file -DgroupId=io.confluent -DartifactId=kafka-schema-serializer -Dversion=5.5.0 -Dpackaging=jar -Dfile=kafka-json-schema-serializer-5.5.0.jar
  mvn install:install-file -DgroupId=io.confluent -DartifactId=kafka-avro-serializer -Dversion=5.5.2 -Dpackaging=jar -Dfile=kafka-avro-serializer-5.5.2.jar
:<<EOF
    <repositories>
        <repository>
            <id>aliyun</id>
            <url>https://maven.aliyun.com/repository/public</url>
            <releases>
                <enabled>true</enabled>
            </releases>
            <snapshots>
                <enabled>false</enabled>
            </snapshots>
        </repository>
    </repositories>
    <pluginRepositories>
        <pluginRepository>
            <id>aliyun-plugin</id>
            <url>https://maven.aliyun.com/repository/public</url>
            <releases>
                <enabled>true</enabled>
            </releases>
            <snapshots>
                <enabled>false</enabled>
            </snapshots>
        </pluginRepository>
    </pluginRepositories>
EOF


# presto official start--------------------------------------------
wget -c https://prestodb.io/docs/current/installation/deployment.html#:~:text=presto%2Dserver%2D${PRESTO_VERSION}.tar.gz -o presto-server-${PRESTO_VERSION}.tar.gz
wget -c https://github.com/prestodb/presto/archive/refs/tags/0.279.tar.gz -o presto-${PRESTO_VERSION}.tar.gz
#tar xzvf presto-server-${PRESTO_VERSION}.tar.gz
tar xzvf presto-${PRESTO_VERSION}.tar.gz

cd presto-${PRESTO_VERSION}

cd docker

#server bin package
tar xzvf ${PRESTO_HOME}/presto-server-${PRESTO_VERSION}.tar.gz
cp ${PRJ_HOME}/juicefs/juicefs-hadoop-${JUICEFS_VERSION}-jdk11.jar presto-server-${PRESTO_VERSION}/plugin/hive-hadoop2/
mkdir presto-server-${PRESTO_VERSION}/hadoopconf
cp ${PRJ_HOME}/juicefs/core-site.xml presto-server-${PRESTO_VERSION}/hadoopconf/
cp ${PRJ_HOME}/spark/hdfs-site.xml presto-server-${PRESTO_VERSION}/hadoopconf/
tar czvf presto-server-${PRESTO_VERSION}.tar.gz presto-server-${PRESTO_VERSION}/
rm -rf presto-server-${PRESTO_VERSION}
mv presto-server-${PRESTO_VERSION} ${PRESTO_HOME}/
#client jar
cp ${PRESTO_HOME}/presto-${PRESTO_VERSION}/presto-cli/target/presto-cli-${PRESTO_VERSION}-SNAPSHOT-executable.jar ./presto-cli-${PRESTO_VERSION}-executable.jar
#os repo
cp ${PRJ_HOME}/image/Centos-7.repo ./

file=Dockerfile
#cp ${file}.bk ${file}
cp ${file} ${file}.bk
#$SED -i 's@FROM centos:centos7.9.2009@FROM registry.cn-hangzhou.aliyuncs.com/bronzels/centos-centos7.9.2009::1.0@g' ${file}
$SED -i '/RUN yum install tar gzip java-11-amazon-corretto less procps/i\RUN rm -f /etc/yum.repos.d/CentOS-Base.repo\nCOPY Centos-7.repo /etc/yum.repos.d/Centos-7.repo\nRUN yum clean all && yum makecache && yum -y update' ${file}
$SED -i 's@RUN yum install tar gzip java-11-amazon-corretto less procps@RUN yum install tar gzip java-11-amazon-corretto less procps bind-utils bc@g' ${file}
$SED -i 's/COPY etc /#COPY etc /g' ${file}
$SED -i 's/COPY entrypoint.sh /#COPY entrypoint.sh /g' ${file}
$SED -i 's/ENTRYPOINT /#ENTRYPOINT /g' ${file}
$SED -i '/mkdir -p $PRESTO_HOME\/etc /,+d' ${file}
$SED -i '/mkdir -p $PRESTO_HOME\/etc\/catalog /,+d' ${file}

docker build ./ --progress=plain --build-arg PRESTO_VERSION="${PRESTO_VERSION}" -t harbor.my.org:1080/presto/presto-juicefs:${PRESTO_VERSION}
docker push harbor.my.org:1080/presto/presto-juicefs:${PRESTO_VERSION}

#docker
ansible all -m shell -a"docker images|grep 'presto-juicefs '"
ansible all -m shell -a"docker images|grep 'presto-juicefs '|awk '{print \$3}'|xargs docker rmi -f"
#containerd
ansible all -m shell -a"crictl images|grep 'presto-juicefs '"
ansible all -m shell -a"crictl images|grep 'presto-juicefs '|awk '{print \$3}'|xargs crictl rmi"

cd ${PRESTO_HOME}
#git clone git@github.com:dnskr/presto.git presto-helm


#下载presto-official_helm_chart.zip
unzip -x presto-official_helm_chart.zip
cd presto-official_helm_chart/charts/presto

file=values.yaml
cp ${file} ${file}.bk
cat << EOF >> ${file}
  hive: |-
    connector.name=hive
    hive.metastore.uri=thrift://hive-service.hadoop.svc.cluster.local:9083
    hive.config.resources=/opt/presto-server/hadoopconf/core-site.xml,/opt/presto-server/hadoopconf/hdfs-site.xml
EOF

$SED -i 's/  command: /  # command: /g' ${file}
$SED -i '/  # Command to launch coordinator/a\  command: \["sh", "-c", "\$PRESTO_HOME\/bin\/launcher start && tail -f /dev/null"\]' ${file}
$SED -i '/  # Command to launch worker/a\  command: \["sh", "-c", "until nslookup my-trino; do sleep 5; echo waiting svc ready; done && until curl http:\/\/my-presto:8080; do sleep 5; echo waiting http end ready; done && \$PRESTO_HOME\/bin\/launcher start && tail -f \/dev\/null"\]' ${file}
for prj in {coordinator,worker}
do
  file=deployment-${prj}.yaml
  #cp templates/${file} ${file}.bk
  #$SED -i '/        - name: catalog/i\            defaultMode: 493' templates/${file}
  $SED -i 's/etc/pre-etc/g' templates/${file}
done
  $SED -i '/concat .Values.volumes .Values./d' templates/${file}
  $SED -i '/concat .Values.volumeMounts .Values./d' templates/${file}
  $SED -i '/- with \$volumeMounts /,+2d' templates/${file}
  $SED -i '/- with $volumes /,+2d' templates/${file}

helm install my -n presto -f values.yaml \
  --set worker.replicas=3 \
  --set image.repository=harbor.my.org:1080/presto/presto-juicefs \
  --set image.tag=${PRESTO_VERSION} \
  ./
# presto official end--------------------------------------------

# presto 2h-kim start--------------------------------------------
cd ${PRESTO_HOME}
#git clone git@github.com:2h-kim/presto-cluster.git
unzip -x presto-cluster-main.zip

cd presto-cluster-main

file=Dockerfile
#cp ${file}.bk ${file}
cp ${file} ${file}.bk

$SED -i 's/ARG PRESTO_VERSION=0.276.1/ARG PRESTO_VERSION=0.279/g' ${file}
$SED -i '/RUN apt-get update /i\RUN sed -i s@\/archive.ubuntu.com\/@\/mirrors.aliyun.com\/@g \/etc\/apt\/sources.list' ${file}
$SED -i 's/CMD /#CMD /g' ${file}
$SED -i 's/apt-get install wget/apt-get install wget dnsutils curl bc/g' ${file}

mkdir catalog
cat << EOF > catalog/hive.properties
connector.name=hive
hive.metastore.uri=thrift://hive-service.hadoop.svc.cluster.local:9083
hive.config.resources=//home/presto/presto-server/hadoopconf/core-site.xml,/home/presto/presto-server/hadoopconf/hdfs-site.xml
EOF

mkdir hadoopconf
cp ${PRJ_HOME}/juicefs/core-site.xml hadoopconf/
cp ${PRJ_HOME}/spark/hdfs-site.xml hadoopconf/

$SED -i 's/FROM ubuntu:latest/FROM ubuntu:latest AS base/g' ${file}
cp ${PRJ_HOME}/juicefs/juicefs-${JUICEFS_VERSION}.tar.gz ./
cp ${PRJ_HOME}/image/go1.19.2.linux-amd64.tar.gz ./
$SED -i 's@COPY ./scripts /home/presto/scripts@COPY --chown=presto:presto ./scripts /home/presto/scripts@g' ${file}
cat << \EOF >> ${file}

ENV MY_HOME=/home/presto

USER root
COPY --chown=presto:presto ./hadoopconf ${MY_HOME}/hadoopconf
ARG PRESTO_CLI_JAR=presto-cli-$PRESTO_VERSION-executable.jar
COPY --chown=presto:presto $PRESTO_CLI_JAR ${PRESTO_SERVER_HOME}/bin/presto-cli
RUN chmod +x ${PRESTO_SERVER_HOME}/bin/presto-cli
USER presto
WORKDIR ${MY_HOME}

FROM base as juicefs
ARG JUICEFS_VERSION=?
COPY --chown=presto:presto go1.19.2.linux-amd64.tar.gz ./
RUN tar xzvf go1.19.2.linux-amd64.tar.gz
ENV PATH ${MY_HOME}/go/bin:$PATH
ENV GOPROXY https://goproxy.cn

COPY --chown=presto:presto juicefs-${JUICEFS_VERSION}.tar.gz ./
RUN tar xzvf juicefs-${JUICEFS_VERSION}.tar.gz

USER root
RUN apt install -y gcc-7 g++-7
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 100
RUN update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-7 100
RUN gcc --version
RUN apt install -y make
RUN make --version

COPY --chown=presto:presto gopath ${MY_HOME}/gopath
ENV GOPATH ${MY_HOME}/gopath
COPY --chown=presto:presto apache-maven ${MY_HOME}/maven
COPY --chown=presto:presto .m2 ${MY_HOME}/.m2
USER presto

WORKDIR ${MY_HOME}/juicefs-${JUICEFS_VERSION}/sdk/java
ENV PATH ${MY_HOME}/maven/bin:$PATH
#RUN ls -la ${MY_HOME}
RUN sed -i 's/-Dmaven.test.skip=true/-Dmaven.test.skip=true -Dmaven.javadoc.skip=true/g' Makefile
RUN make

FROM base as final
ARG JUICEFS_VERSION=?
USER root
COPY --from=juicefs --chown=presto:presto ${MY_HOME}/juicefs-${JUICEFS_VERSION}/sdk/java/target/juicefs-hadoop-${JUICEFS_VERSION}.jar ${PRESTO_SERVER_HOME}/plugin/hive-hadoop2/juicefs-hadoop-${JUICEFS_VERSION}-jdk11.jar
COPY --from=juicefs --chown=presto:presto ${MY_HOME}/juicefs-${JUICEFS_VERSION}/sdk/java/target/juicefs-hadoop-${JUICEFS_VERSION}.jar ${PRESTO_SERVER_HOME}/plugin/hudi/juicefs-hadoop-${JUICEFS_VERSION}-jdk11.jar
COPY --from=juicefs --chown=presto:presto ${MY_HOME}/juicefs-${JUICEFS_VERSION}/sdk/java/target/juicefs-hadoop-${JUICEFS_VERSION}.jar ${PRESTO_SERVER_HOME}/plugin/iceberg/juicefs-hadoop-${JUICEFS_VERSION}-jdk11.jar
USER presto

USER root
RUN apt install -y less

EOF

#client jar, build in jdk11
#cp ${PRESTO_HOME}/presto-${PRESTO_VERSION}/presto-cli/target/presto-cli-${PRESTO_VERSION}-SNAPSHOT-executable.jar ./presto-cli-${PRESTO_VERSION}-executable.jar
wget -c https://repo1.maven.org/maven2/com/facebook/presto/presto-cli/0.279/presto-cli-0.279-executable.jar

mv scripts/start-presto.sh scripts/start-presto-coordinator.sh
cat << \EOF > scripts/start-presto-worker.sh
#!/usr/bin/env bash
service_name=$1
until nslookup ${service_name}; do sleep 5; echo waiting svc ready; done && until curl http://${service_name}:8080; do sleep 5; echo waiting http end ready; done && ${PRESTO_SERVER_HOME}/bin/launcher run
EOF
chmod a+x scripts/start-presto-worker.sh

$SED -i 's/COPY .\/catalog/#COPY .\/catalog/g' ${file}
$SED -i '/    && mkdir -p ${PRESTO_SERVER_HOME}\/etc\/catalog/,+d' ${file}

:<<EOF
mv ${maven_home} ./apache-maven
#mv ${m2_home} ./
mv ${go_path} ./
DOCKER_BUILDKIT=1 docker build ./ --progress=plain --build-arg PRESTO_VERSION="${PRESTO_VERSION}" --build-arg JUICEFS_VERSION="${JUICEFS_VERSION}" -t harbor.my.org:1080/presto/presto-juicefs-new:${PRESTO_VERSION}
docker push harbor.my.org:1080/presto/presto-juicefs-new:${PRESTO_VERSION}
mv apache-maven ${MYHOME}/apache-maven-${maven_version}
#mv m2 ${MYHOME}/
mv ${go_path} ${MYHOME}/
chown -R $USER ${maven_home}
chown -R $USER ${m2_home}
chown -R $USER ${go_path}
EOF

mv ${maven_home} ./apache-maven
mv ${go_path} ./
mkdir .m2
cp ${MYHOME}/m2/settings.xml .m2/
DOCKER_BUILDKIT=1 docker build ./ --progress=plain --build-arg JUICEFS_VERSION="${JUICEFS_VERSION}" -t harbor.my.org:1080/presto/presto-juicefs-new:${PRESTO_VERSION}
docker push harbor.my.org:1080/presto/presto-juicefs-new:${PRESTO_VERSION}
mv apache-maven ${MYHOME}/apache-maven-${maven_version}
mv gopath ${MYHOME}/

#docker
ansible all -m shell -a"docker images|grep presto-juicefs-new"
ansible all -m shell -a"docker images|grep presto-juicefs-new|awk '{print \$3}'|xargs docker rmi -f"
#containerd
ansible all -m shell -a"crictl images|grep presto-juicefs-new"
ansible all -m shell -a"crictl images|grep presto-juicefs-new|awk '{print \$3}'|xargs crictl rmi"

cd ${PRESTO_HOME}
git clone git@github.com:2h-kim/presto-kube.git
cd presto-kube
:<<EOF
#worker和coordinator一起启动，worker连不上coordinator出错无法恢复
file=deployment-worker.yaml
cp templates/${file} ${file}.bk
$SED -i '/          image: /a\          command: [ "\/bin\/bash", "-ce", "until nslookup my-presto-kube; do sleep 5; echo waiting svc ready; done && until curl http:\/\/my-presto-kube:8080; do sleep 5; echo waiting http end ready; done && \/home\/presto\/scripts\/start-presto-worker.sh" ]' templates/${file}
EOF
for prj in {coordinator,worker}
do
  file=deployment-${prj}.yaml
  #cp templates/${file} ${file}.bk
  $SED -i "/          image: /a\          args: [ \"\${PRESTO_SERVER_HOME}/common/start-presto.sh\" ]" templates/${file}
  if [[ "${prj}" == "worker" ]]; then
    $SED -i '/          envFrom:/i\          env:\n            - name: MY_SERVICE_NAME\n              value: my-presto-kube' templates/${file}
  fi
cat << \EOF >> templates/${file}

          volumeMounts:
            - mountPath: {{ .Values.server.config.path }}/catalog
              name: catalog
            - mountPath: ${PRESTO_SERVER_HOME}/common
              name: catalog
      volumes:
        - name: catalog
          configMap:
            name: {{ .Release.Name }}-catalog
        - name: common
          configMap:
            name: {{ .Release.Name }}-common
EOF
done

for prj in {coordinator,worker}
do
  file=configmap-${prj}.yaml
  cp templates/${file} ${file}.bk
  $SED -i "/  PRESTO_CONF_QUERY_MAX_MEMORY_PER_NODE/a\  PRESTO_CONF_QUERY_MAX_TOTAL_MEMORY_PER_NODE: \"{{ .Values.server.config.query.maxTotalMemoryPerNode }}\"" templates/${file}
done


cp ${PRESTO_HOME}/configmap-catalog.yaml templates/
cp ${PRESTO_HOME}/configmap-common.yaml templates/

file=values.yaml
cp ${file} ${file}.bk
cat << \EOF >> ${file}
# Catalogs
catalog:
  hive: |-
    connector.name=hive-hadoop2
    hive.metastore.uri=thrift://hive-service.hadoop.svc.cluster.local:9083
    hive.config.resources=/home/presto/hadoopconf/core-site.xml,/home/presto/hadoopconf/hdfs-site.xml
EOF
$SED -i '/      maxMemoryPerNode: "2GB"/a\      maxTotalMemoryPerNode: "4GB"' ${file}

helm install my -n presto -f values.yaml \
  --set server.workers=3 \
  --set server.config.query.maxMemory=24GB \
  --set server.config.query.maxMemoryPerNode=8GB \
  --set server.config.query.maxTotalMemoryPerNode=16GB \
  --set server.jvm.memory=24G \
  --set server.config.path=/home/presto/presto-server/etc \
  --set image.repository=harbor.my.org:1080/presto/presto-juicefs-new \
  --set image.tag=${PRESTO_VERSION} \
  --set server.log.level=DEBUG \
  ./
# 2h-kim end--------------------------------------------

watch kubectl get all -n presto

kubectl get all -n presto -o wide

helm uninstall my -n presto
kubectl get pod -n presto |grep -v Running |awk '{print $1}'| xargs kubectl delete pod "$1" -n presto --force --grace-period=0

kubectl get cm -n presto my-coordinator -o yaml | grep hive.config.resources
kubectl get cm -n presto my-worker -o yaml | grep hive.config.resources

kubectl port-forward -n presto svc/my 8080:8080 &

kubectl logs -n presto `kubectl get pod -n presto | grep coordinator | awk '{print $1}'`
kubectl get pod -n presto | grep worker | awk '{print $1}' | xargs kubectl logs -n presto
kubectl logs -n presto my-worker-54d4fb89c6-6fdsd
kubectl logs -n presto my-worker-54d4fb89c6-mx4xk
kubectl logs -n presto my-worker-54d4fb89c6-qlss7

kubectl cp -n presto `kubectl get pod -n presto | grep Running | grep coordinator | awk '{print $1}'`:/home/presto/presto-server/plugin/hive-hadoop2/juicefs-hadoop-1.0.2-jdk11.jar ${PRJ_HOME}/juicefs/juicefs-hadoop-1.0.2-jdk11.jar

kubectl exec -it -n presto `kubectl get pod -n presto | grep Running | grep coordinator | awk '{print $1}'` -- \
presto-server/bin/presto-cli --server my-presto-kube:8080 --catalog hive --schema tpcds_bin_partitioned_orc_10
  SHOW TABLES;
  SELECT * FROM date_dim LIMIT 5;

:<<EOF

NAME: my
LAST DEPLOYED: Sat Feb 18 12:08:42 2023
NAMESPACE: presto
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The chart has been installed!
Please keep in mind that some time is needed for the release to be fully deployed.

In order to check the release status, use:
  helm status my -n presto
    or for more detailed info
  helm get all my -n presto

Accessing deployed release:
- To access my service within the cluster, use the following URL:
    my.presto.svc.cluster.local
- To access my service from outside the cluster for debugging, run the following command:
    kubectl port-forward svc/my 8080:8080 -n presto
  and then open the browser on 127.0.0.1:8080

EOF
