#FROM chenseanxy/hadoop:3.2.1-nolib
FROM harbor.my.org:1080/chenseanxy/hadoop-ubussh:3.2.1-nolib
USER root
RUN mkdir /cfs
RUN chown hdfs:root /cfs

USER hdfs
RUN mkdir /cfs/bin;mkdir /cfs/conf
RUN echo "/cfs/bin/cfs-client -f -c /cfs/conf/fuse.json" > /cfs/bin/start.sh
RUN chmod a+x /cfs/bin/start.sh
#ADD cubefs-img-files/chubaofs-v2.4.0-x86_64-linux.tar.gz /cfs/bin/

ARG rev
COPY --chown=hdfs:root cubefs-img-files/cubefs-${rev}.tar.gz /app/hdfs/
WORKDIR /app/hdfs/
RUN tar xzvf /app/hdfs/cubefs-${rev}.tar.gz
WORKDIR /app/hdfs/cubefs-${rev}
RUN ./build.sh

RUN cp /app/hdfs/cubefs-${rev}/build/bin/cfs-cli* /cfs/bin/
RUN chmod a+x /cfs/bin/*
COPY --chown=hdfs:root cubefs-hadoop $HADOOP_HOME/cubefs-hadoop
WORKDIR $HADOOP_HOME/cubefs-hadoop/
RUN ls
RUN mvn package -DskipTests
WORKDIR $HADOOP_HOME
RUN mkdir cubefs-hadoop-0.1.0
RUN cp $HADOOP_HOME/cubefs-hadoop/target/cubefs-hadoop-0.1.0.jar $HADOOP_HOME/cubefs-hadoop-0.1.0/
WORKDIR $HADOOP_HOME/cubefs-hadoop-0.1.0/
RUN jar xvf cubefs-hadoop-0.1.0.jar
RUN mkdir linux-x86-64
RUN cp /app/hdfs/cubefs-${rev}/build/bin/libcfs.so $HADOOP_HOME/cubefs-hadoop-0.1.0/linux-x86-64/
RUN jar cvf cubefs-hadoop-0.1.0-wso.jar *
ENV _HADOOP_COMMON_LIB=$HADOOP_HOME/share/hadoop/common/lib/
RUN mv $HADOOP_HOME/cubefs-hadoop-0.1.0/cubefs-hadoop-0.1.0-wso.jar $_HADOOP_COMMON_LIB
RUN cp $REPOHOME/net/java/dev/jna/jna/5.6.0/jna-5.6.0.jar $_HADOOP_COMMON_LIB
RUN cp $REPOHOME/commons-lang/commons-lang/2.6/commons-lang-2.6.jar $_HADOOP_COMMON_LIB

COPY fuse.json /cfs/conf/fuse.json
COPY --chown=hdfs:root core-site.xml $HADOOP_HOME/etc/hadoop/

WORKDIR $HADOOP_HOME
