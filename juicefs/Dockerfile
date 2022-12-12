#FROM chenseanxy/hadoop:3.2.1-nolib
FROM harbor.my.org:1080/chenseanxy/hadoop-ubussh:3.2.1-nolib
USER root

COPY mc /usr/local/bin/
RUN chmod a+x /usr/local/bin/mc

COPY miniogw /miniogw
WORKDIR /miniogw
RUN make build
RUN cp /miniogw/minio /usr/local/bin/miniogw
RUN chmod a+x /usr/local/bin/miniogw

COPY juicefs /usr/local/bin/
RUN chmod a+x /usr/local/bin/juicefs
RUN juicefs

USER hdfs
COPY --chown=hdfs:root juicefs-hadoop-1.0.2.jar $HADOOP_HOME/share/hadoop/common/lib/
COPY --chown=hdfs:root core-site.xml $HADOOP_HOME/etc/hadoop/

WORKDIR $HADOOP_HOME
