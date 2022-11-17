#FROM chenseanxy/hadoop:3.2.1-nolib
FROM harbor.my.org:1080/chenseanxy/hadoop-ubu16ssh:3.2.1-nolib

COPY juicefs /usr/local/bin/
COPY juicefs-hadoop-1.0.2.jar /usr/local/hadoop/share/hadoop/common/lib/
RUN which juicefs
RUN juicefs

RUN mkdir -p /data/jfs
COPY core-site.xml /usr/local/hadoop/etc/hadoop/

COPY minio /usr/local/bin/
COPY mc /usr/local/bin/

RUN apt-get install -y software-properties-common
RUN add-apt-repository ppa:ubuntu-toolchain-r/test
RUN apt-get update
RUN apt install -y gcc-7 g++-7
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 100
RUN update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-7 100

RUN apt install -y automake autoconf libtool
RUN apt install -y make

RUN gcc --version
RUN make --version

ADD fuse-3.1.1.tar.gz /usr/local/hadoop/
RUN cd fuse-3.1.1/
WORKDIR /usr/local/hadoop/fuse-3.1.1
RUN ./configure
RUN make
RUN make install

RUN apt-get install -y kmod
RUN apt-get update
RUN modprobe fuse
RUN ls /dev/fuse


