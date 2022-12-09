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

cp -r ../../../image/iotest ./
cp -r ../../../image/fuse-2.9.2.tar.gz ./
cp -r ../../../image/fuse-2.9.2.tar.gz ./

cp ../../sources-16.04.list sources.list

#cp ../../../../dockerfile/image/sources-16.04.list sources.list
file=Dockerfile
cp ${file}.template ${file}
$SED -i '/FROM java:8-jre/a\USER root' ${file}
$SED -i 's@FROM java:8-jre@FROM paulosalgado\/oracle-java8-ubuntu-16@g' ${file}
#$SED -i 's@FROM java:8-jre@FROM harbor.my.org:1080\/base\/ubuntu22-openjdk8@g' ${file}

cat << \EOF >> ${file}

COPY sources.list /etc/apt
RUN apt-get update
RUN apt-get install -y openssh-server
RUN sed -i 's@PermitRootLogin prohibit-password@PermitRootLogin yes@g' /etc/ssh/sshd_config
RUN sed -i 's@#PubkeyAuthentication yes@PubkeyAuthentication yes@g' /etc/ssh/sshd_config
RUN sed -i 's@#PasswordAuthentication yes@PasswordAuthentication yes@g' /etc/ssh/sshd_config
RUN sed -i 's@#   StrictHostKeyChecking ask@StrictHostKeyChecking no@g' /etc/ssh/ssh_config
RUN usermod --password $(echo root | openssl passwd -1 -stdin) root

EXPOSE 22

RUN apt install -y gcc g++
RUN apt install -y make
RUN apt install -y automake autoconf libtool
RUN gcc --version
RUN make --version

WORKDIR /
ADD files/fuse-2.9.2.tar.gz /
WORKDIR /fuse-2.9.2
RUN ./configure --prefix=/usr
RUN make
RUN make install

RUN apt install -y tar zip unzip
RUN apt install -y git

WORKDIR /
COPY files/iotest/mpich-3.2.tar.gz /mpich-3.2.tar.gz
RUN tar -xzvf mpich-3.2.tar.gz
WORKDIR /mpich-3.2
RUN ./configure --disable-fortran
RUN make
RUN make install
RUN mpicc || :
ENV MPI_CC=mpicc

WORKDIR /
COPY files/iotest/mdtest-master.zip /mdtest-master.zip
RUN unzip mdtest-master.zip
WORKDIR /mdtest-master
RUN make
RUN mv mdtest /usr/local/bin
RUN mdtest || :

RUN apt-get install -y libaio-dev

WORKDIR /
COPY files/iotest/fio-fio-3.32.zip /fio-fio-3.32.zip
RUN unzip fio-fio-3.32.zip
WORKDIR fio-fio-3.32
RUN ./configure
RUN make
RUN make install
RUN fio || :

ADD files/go1.19.2.linux-amd64.tar.gz /usr/local/
ENV PATH /usr/local/go/bin:$PATH
ENV GO111MODULE=on
ENV GOPATH /usr/local/hadoop/gopath
ENV GOPROXY https://goproxy.cn

RUN useradd -d /home/hdfs hdfs
RUN mkdir /home/hdfs
RUN chown hdfs:hdfs /home/hdfs
RUN usermod --password $(echo hdfs | openssl passwd -1 -stdin) hdfs
RUN usermod -g root hdfs

RUN apt-get install -y curl

#cmake
#ubuntu
#安装libssl1.11依赖
ADD files/openssl-1.1.1s.tar.gz /
WORKDIR /openssl-1.1.1s
RUN ./config
RUN make
RUN make install
RUN ln -s /usr/local/lib/libssl.so.1.1 /usr/lib/libssl.so.1.1
RUN ln -s /usr/local/lib/libcrypto.so.1.1 /usr/lib/libcrypto.so.1.1
RUN openssl version

#然后再使用apt安装就是最新版本的cmake啦
RUN apt install -y cmake
RUN cmake --version

WORKDIR /usr/local/hadoop/

RUN apt install -y zlib1g-dev libbz2-dev
EOF

cp Makefile Makefile-ubussh
$SED -i 's@DOCKER_REPO = chenseanxy\/hadoop@$DOCKER_REPO = chenseanxy\/hadoop-ubussh@g' Makefile-ubussh
#$SED -i 's@$(DOCKER) build -t hadoop@$(DOCKER) build --no-cache --progress=plain -t hadoop-ubussh@g' Makefile-ubussh
#$SED -i 's@$(DOCKER) build -t hadoop@$(DOCKER) build --progress=plain -t hadoop-ubussh@g' Makefile-ubussh
$SED -i 's@$(DOCKER) build -t hadoop@$(DOCKER) build -t hadoop-ubussh@g' Makefile-ubussh
make -f Makefile-ubussh

docker tag hadoop-ubussh:${HADOOPREV}-nolib harbor.my.org:1080/chenseanxy/hadoop-ubussh:${HADOOPREV}-nolib
docker push harbor.my.org:1080/chenseanxy/hadoop-ubussh:${HADOOPREV}-nolib

rm -f hadoop-${HADOOPREV}*

cd $HDPHOME
file=values.yaml
cp ${HDPHOME}.bk/$file $file
$SED -i 's@repository: chenseanxy/hadoop@repository: harbor.my.org:1080/chenseanxy/hadoop-ubussh@g' ${file}
$SED -i "s@tag: 3.2.1-nolib@tag: ${HADOOPREV}-nolib@g" ${file}
$SED -i "s@hadoopVersion: 3.2.1@hadoopVersion: ${HADOOPREV}@g" ${file}
$SED -i 's@pullPolicy: IfNotPresent@pullPolicy: Always@g' ${file}
cp ${file} ${file}.common

