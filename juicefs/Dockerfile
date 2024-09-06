#FROM chenseanxy/hadoop:3.2.1-nolib
FROM harbor.my.org:1080/chenseanxy/hadoop-ubussh:3.2.1-nolib
USER root

COPY mc /usr/local/bin/
RUN chmod a+x /usr/local/bin/mc

#COPY gopath /usr/local/gopath
#ENV GOPATH /usr/local/gopath
#ENV GOPROXY https://goproxy.cn

COPY miniogw /miniogw
WORKDIR /miniogw
RUN make build -j 12
RUN cp /miniogw/minio /usr/local/bin/miniogw
RUN chmod a+x /usr/local/bin/miniogw

#RUN rm -rf /usr/local/gopath
RUN rm -rf /miniogw

COPY juicefs-linux-amd64/juicefs /usr/local/bin/
RUN chmod a+x /usr/local/bin/juicefs
RUN juicefs

USER hdfs
ARG JUICEFS_VERSION=?
COPY --chown=hdfs:root juicefs-hadoop-${JUICEFS_VERSION}.jar $HADOOP_HOME/share/hadoop/common/lib/
COPY --chown=hdfs:root core-site.xml $HADOOP_HOME/etc/hadoop/

WORKDIR $HADOOP_HOME
