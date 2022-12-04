HADOOPREV=3.2.1
wget -c http://archive.apache.org/dist/hadoop/common/hadoop-${HADOOPREV}/hadoop-${HADOOPREV}-src.tar.gz
wget -c http://archive.apache.org/dist/hadoop/common/hadoop-${HADOOPREV}/hadoop-${HADOOPREV}.tar.gz

rm -rf helm-hadoop-3
git clone https://github.com/chenseanxy/helm-hadoop-3.git
rm -rf helm-hadoop-3.bk
cp -r helm-hadoop-3 helm-hadoop-3.bk
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Mac detected."
    #mac
    HDPHOME=/Volumes/data/workspace/dockerfile/hadoop/helm-hadoop-3
    SED=gsed
else
    echo "Assuming linux by default."
    #linux
    HDPHOME=~/helm-hadoop-3
    SED=sed
fi

cd $HDPHOME

cd image

docker images|grep hadoop
docker images|grep hadoop|awk '{print $3}'|xargs docker rmi -f
#docker
ansible all -m shell -a"docker images|grep hadoop"
ansible all -m shell -a"docker images|grep hadoop|awk '{print \$3}'|xargs docker rmi -f"
#containerd
ansible all -m shell -a"crictl images|grep hadoop"
ansible all -m shell -a"crictl images|grep hadoop|awk '{print \$3}'|xargs crictl rmi"

file=Dockerfile
cp ../../helm-hadoop-3.bk/image/${file} ${file}.template
$SED -i 's/HADOOP_PREFIX/HADOOP_HOME/g' ${file}.template
$SED -i '/    YARN_CONF_DIR/a\    YARN_HOME=/usr/local/hadoop \\' ${file}.template

cp ${file}.template ${file}
#$SED -i 's@FROM java:8-jre@FROM anapsix\/alpine-java@g' ${file}
#替换为alpine以后，datanode/nodemanager不能启动

file=Makefile
cp ../../helm-hadoop-3.bk/image/${file} ${file}
$SED -i "s@HADOOP_30_VERSION = 3.2.1@HADOOP_30_VERSION = ${HADOOPREV}@g" ${file}

cp ../../hadoop-3.2.1* ./

make
#helm install错误kubernetes Error: create: failed to create: Request entity too large: limit is 3145728
#rm hadoop-${HADOOPREV}.tar.gz

docker tag hadoop:${HADOOPREV}-nolib harbor.my.org:1080/chenseanxy/hadoop:${HADOOPREV}-nolib
docker push harbor.my.org:1080/chenseanxy/hadoop:${HADOOPREV}-nolib

file=Dockerfile
cp ${file}.template ${file}
$SED -i '/FROM java:8-jre/a\USER root' ${file}
#$SED -i 's@FROM java:8-jre@FROM registry.cn-hangzhou.aliyuncs.com\/bronzels\/duxinglangzi-alpine-java8:1.0@g' ${file}
$SED -i 's@FROM java:8-jre@FROM duxinglangzi\/alpine-java11@g' ${file}

cat << \EOF >> ${file}

RUN apk --update --no-cache add fuse
EOF


cp Makefile Makefile-alp315j11
$SED -i 's@DOCKER_REPO = chenseanxy\/hadoop@$DOCKER_REPO = chenseanxy\/hadoop-alp315j11@g' Makefile-alp315j11
#$SED -i 's@$(DOCKER) build -t hadoop@$(DOCKER) build --no-cache --progress=plain -t hadoop-alp315j11@g' Makefile-alp315j11
$SED -i 's@$(DOCKER) build -t hadoop@$(DOCKER) build -t hadoop-alp315j11@g' Makefile-alp315j11
make -f Makefile-alp315j11

docker tag hadoop-alp315j11:${HADOOPREV}-nolib harbor.my.org:1080/chenseanxy/hadoop-alp315j11:${HADOOPREV}-nolib
docker push harbor.my.org:1080/chenseanxy/hadoop-alp315j11:${HADOOPREV}-nolib

rm -f hadoop-${HADOOPREV}*

cd $HDPHOME
file=values.yaml
cp ${HDPHOME}.bk/$file $file
$SED -i 's@repository: chenseanxy/hadoop@repository: harbor.my.org:1080/chenseanxy/hadoop-alp315j11@g' ${file}
$SED -i "s@tag: 3.2.1-nolib@tag: ${HADOOPREV}-nolib@g" ${file}
$SED -i "s@hadoopVersion: 3.2.1@hadoopVersion: ${HADOOPREV}@g" ${file}
$SED -i 's@pullPolicy: IfNotPresent@pullPolicy: Always@g' ${file}

