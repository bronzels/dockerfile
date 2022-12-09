#FROM chenseanxy/hadoop:3.2.1-nolib
FROM harbor.my.org:1080/chenseanxy/hadoop-ubussh:3.2.1-nolib

RUN mkdir -p /cfs/bin;mkdir -p /cfs/conf
RUN echo "/cfs/bin/cfs-client -f -c /cfs/conf/fuse.json" > /cfs/bin/start.sh
RUN chmod a+x /cfs/bin/start.sh
COPY fuse.json /cfs/conf/fuse.json
ADD cubefs-img-files/chubaofs-v2.4.0-x86_64-linux.tar.gz /cfs/bin/
ADD cubefs-img-files/cubefs-2.4.0.tar.gz /
WORKDIR /
WORKDIR /cubefs-2.4.0
RUN ./build.sh
RUN cp build/bin/libcfs.so /usr/local/hadoop/lib/native/
COPY cubefs-hadoop/target/cubefs-hadoop-0.1.0.jar /usr/local/hadoop/share/hadoop/common/lib/
COPY cubefs-img-files/jna-5.6.0.jar /usr/local/hadoop/share/hadoop/common/lib/
COPY core-site.xml /usr/local/hadoop/etc/hadoop/

