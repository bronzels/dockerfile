#FROM chenseanxy/hadoop:3.2.1-nolib
FROM harbor.my.org:1080/chenseanxy/hadoop-ubussh:3.2.1-nolib
USER root

RUN mkdir -p /cfs/bin;mkdir -p /cfs/conf
RUN echo "/cfs/bin/cfs-client -f -c /cfs/conf/fuse.json" > /cfs/bin/start.sh
RUN chmod a+x /cfs/bin/start.sh
COPY fuse.json /cfs/conf/fuse.json
ADD cubefs-img-files/chubaofs-v2.4.0-x86_64-linux.tar.gz /cfs/bin/
RUN chmod a+x /cfs/bin/*

USER hdfs

ADD --chown=hdfs:root cubefs-img-files/cubefs-2.4.0.tar.gz /app/hdfs/
WORKDIR /app/hdfs/cubefs-2.4.0
RUN ./build.sh

#RUN cp build/bin/libcfs.so $HADOOP_HOME/lib/native/
#RUN cp build/bin/libcfs.so $HADOOP_HOME/bin
#RUN chmod a+x $HADOOP_HOME/bin/libcfs.so
WORKDIR $HADOOP_HOME
RUN mkdir cubefs-hadoop-0.1.0
WORKDIR $HADOOP_HOME/cubefs-hadoop-0.1.0
COPY --chown=hdfs:root cubefs-hadoop/target/cubefs-hadoop-0.1.0.jar $HADOOP_HOME/
RUN jar xvf $HADOOP_HOME/cubefs-hadoop-0.1.0.jar
RUN mkdir linux-x86-64
RUN cp /app/hdfs/cubefs-2.4.0/build/bin/libcfs.so $HADOOP_HOME/cubefs-hadoop-0.1.0/linux-x86-64/
RUN jar cvf cubefs-hadoop-0.1.0-wso.jar *
#COPY cubefs-hadoop/target/cubefs-hadoop-0.1.0.jar $HADOOP_HOME/share/hadoop/common/lib/
RUN mv $HADOOP_HOME/cubefs-hadoop-0.1.0/cubefs-hadoop-0.1.0-wso.jar $HADOOP_HOME/share/hadoop/common/lib/
COPY --chown=hdfs:root cubefs-img-files/jna-5.6.0.jar $HADOOP_HOME/share/hadoop/common/lib/
RUN cp /app/hdfs/.m2/repository/commons-lang/commons-lang/2.1/commons-lang-2.1.jar $HADOOP_HOME/share/hadoop/common/lib/
COPY --chown=hdfs:root core-site.xml $HADOOP_HOME/etc/hadoop/
#RUN echo 'source /etc/profile' >> /app/hdfs/.bashrc

WORKDIR $HADOOP_HOME

#USER root
#RUN echo 'export PATH=${PATH}:/app/hdfs/hadoop/bin' >> /etc/profile
#USER hdfs
