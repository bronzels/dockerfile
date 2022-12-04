#FROM chenseanxy/hadoop:3.2.1-nolib
FROM harbor.my.org:1080/chenseanxy/hadoop-ubussh:3.2.1-nolib

COPY juicefs /usr/local/bin/
COPY juicefs-hadoop-1.0.2.jar /usr/local/hadoop/share/hadoop/common/lib/
RUN which juicefs
RUN juicefs

RUN mkdir -p /data/jfs
COPY core-site.xml /usr/local/hadoop/etc/hadoop/

COPY minio /usr/local/bin/
COPY mc /usr/local/bin/

ADD fuse-2.9.2.tar.gz /usr/local/hadoop/
WORKDIR /usr/local/hadoop/fuse-2.9.2

RUN apt install -y gcc

RUN apt install -y automake autoconf libtool
RUN apt install -y make

RUN gcc --version
RUN make --version

RUN ./configure --prefix=/usr
RUN make
RUN make install

ADD go1.19.2.linux-amd64.tar.gz /usr/local/
ENV PATH /usr/local/go/bin:$PATH
ENV GO111MODULE=on
ENV GOPATH /usr/local/hadoop/gopath
ENV GOPROXY https://goproxy.cn

COPY miniogw /usr/local/hadoop/miniogw
WORKDIR /usr/local/hadoop/miniogw
RUN apt install -y git
RUN make build
RUN cp /usr/local/hadoop/miniogw/minio /usr/local/bin/miniogw

WORKDIR /usr/local/hadoop


