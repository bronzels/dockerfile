FROM java:8-jre

USER root

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


RUN apt install -y tar zip unzip
RUN apt install -y git

ADD files/go1.19.2.linux-amd64.tar.gz /usr/local/
ENV PATH /usr/local/go/bin:$PATH
ENV GO111MODULE=on
ENV GOPATH /usr/local/hadoop/gopath
ENV GOPROXY https://goproxy.cn

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

RUN apt install -y zlib1g-dev libbz2-dev
RUN apt install -y maven
RUN apt install -y jq


RUN useradd -d /app/hdfs hdfs
RUN mkdir -p /app/hdfs
RUN chown hdfs:hdfs /app/hdfs
RUN usermod --password $(echo hdfs | openssl passwd -1 -stdin) hdfs
RUN usermod -g root hdfs

USER hdfs
WORKDIR /app/hdfs

# Add native libs
ARG HADOOP_VERSION=
COPY hadoop-${HADOOP_VERSION}.tar.gz /app/hdfs/
RUN tar xzvf hadoop-${HADOOP_VERSION}.tar.gz
# Ignore native libs
# ADD hadoop-native-${HADOOP_VERSION}.tar /usr/local/hadoop-${HADOOP_VERSION}/lib/native

ENV HADOOP_HOME=/app/hdfs/hadoop \
    HADOOP_COMMON_HOME=/app/hdfs/hadoop \
    HADOOP_HDFS_HOME=/app/hdfs/hadoop \
    HADOOP_MAPRED_HOME=/app/hdfs/hadoop \
    HADOOP_YARN_HOME=/app/hdfs/hadoop \
    HADOOP_CONF_DIR=/app/hdfs/hadoop/etc/hadoop \
    YARN_CONF_DIR=/app/hdfs/hadoop/etc/hadoop \
    YARN_HOME=/app/hdfs/hadoop \
    PATH=${PATH}:/app/hdfs/hadoop/bin

RUN \
  cd /app/hdfs && ln -s ./hadoop-${HADOOP_VERSION} hadoop && \
  rm -f ${HADOOP_HOME}/logs/*

WORKDIR ${HADOOP_HOME}

# Hdfs ports
EXPOSE 50010 50020 50070 50075 50090 8020 9000
# Mapred ports
EXPOSE 19888
#Yarn ports
EXPOSE 8030 8031 8032 8033 8040 8042 8088
#Other ports
EXPOSE 49707 2122

RUN mkdir /app/hdfs/.m2
COPY files/settings.xml /app/hdfs/.m2/
ENV REPOHOME=/app/hdfs/.m2/repository

RUN mkdir -p /app/hdfs/hadoop/mapred/local/
RUN mkdir /app/hdfs/hadoop/tmpdir/