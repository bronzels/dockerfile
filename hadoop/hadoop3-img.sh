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

HADOOPREV=3.2.1
HDPHOME=${MYHOME}/workspace/dockerfile/hadoop/helm-hadoop-3

wget -c http://archive.apache.org/dist/hadoop/common/hadoop-${HADOOPREV}/hadoop-${HADOOPREV}-src.tar.gz
wget -c http://archive.apache.org/dist/hadoop/common/hadoop-${HADOOPREV}/hadoop-${HADOOPREV}.tar.gz

rm -rf helm-hadoop-3
git clone https://github.com/chenseanxy/helm-hadoop-3.git
rm -rf helm-hadoop-3.bk
cp -r helm-hadoop-3 helm-hadoop-3.bk

cd $HDPHOME

cd image

docker images|grep hadoop
docker images|grep '<none>'|awk '{print $3}'|xargs docker rmi -f
docker images|grep hadoop|awk '{print $3}'|xargs docker rmi -f
docker container ps -f status=exited
docker container ps -f status=exited | cut -f 1 -d " " | tail -n +2 | xargs docker container rm
#docker
ansible all -m shell -a"docker images|grep hadoop"
ansible all -m shell -a"docker images|grep hadoop|awk '{print \$3}'|xargs docker rmi -f"
#containerd
ansible all -m shell -a"crictl images|grep hadoop"
ansible all -m shell -a"crictl images|grep hadoop|awk '{print \$3}'|xargs crictl rmi"

#hdfs
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
#其他分布式文件系统
cp ../../../helm-hadoop-3-templates-distfs/${file} ${file}.template

mkdir files
#cp -r ../../../image/iotest ./files/
cp -r ../../../image/fuse-2.9.2.tar.gz ./files/
cp -r ../../../image/go1.19.2.linux-amd64.tar.gz ./files/
cp -r ../../../image/openssl-1.1.1s.tar.gz ./files/
cp -r ../../../image/settings.xml ./files/

cp ../../sources-16.04.list sources.list

#cp ../../../../dockerfile/image/sources-16.04.list sources.list
#$SED -i '/FROM java:8-jre/a\USER root' ${file}
$SED -i 's@FROM java:8-jre@FROM paulosalgado\/oracle-java8-ubuntu-16@g' ${file}
#$SED -i 's@FROM java:8-jre@FROM harbor.my.org:1080\/base\/ubuntu22-openjdk8@g' ${file}

cp Makefile Makefile-ubussh
$SED -i 's@DOCKER_REPO = chenseanxy\/hadoop@$DOCKER_REPO = chenseanxy\/hadoop-ubussh@g' Makefile-ubussh
#$SED -i 's@$(DOCKER) build -t hadoop@$(DOCKER) build --no-cache --progress=plain -t hadoop-ubussh@g' Makefile-ubussh
#$SED -i 's@$(DOCKER) build -t hadoop@$(DOCKER) build --progress=plain -t hadoop-ubussh@g' Makefile-ubussh
$SED -i 's@$(DOCKER) build -t hadoop@$(DOCKER) build -t hadoop-ubussh@g' Makefile-ubussh
make -f Makefile-ubussh

docker tag hadoop-ubussh:${HADOOPREV}-nolib harbor.my.org:1080/chenseanxy/hadoop-ubussh:${HADOOPREV}-nolib
docker push harbor.my.org:1080/chenseanxy/hadoop-ubussh:${HADOOPREV}-nolib

rm -f hadoop-${HADOOPREV}*
rm -rf files

#worker
mkdir -p /app/hdfs/hadoop/mapred/local/

cd $HDPHOME
file=values.yaml
cp ${HDPHOME}.bk/$file $file
$SED -i 's@repository: chenseanxy/hadoop@repository: harbor.my.org:1080/chenseanxy/hadoop-ubussh@g' ${file}
$SED -i "s@tag: 3.2.1-nolib@tag: ${HADOOPREV}-nolib@g" ${file}
$SED -i "s@hadoopVersion: 3.2.1@hadoopVersion: ${HADOOPREV}@g" ${file}
$SED -i 's@pullPolicy: IfNotPresent@pullPolicy: Always@g' ${file}
cp ${file} ../helm-hadoop-3-templates-distfs/${file}.common

