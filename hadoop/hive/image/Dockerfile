FROM harbor.my.org:1080/chenseanxy/hadoop-ubu16ssh:3.2.1-nolib

ARG HIVEREV

ADD apache-hive-${HIVEREV}-bin.tar.gz /usr/local/
RUN ln -s /usr/local/apache-hive-${HIVEREV}-bin /usr/local/hive
ADD mysql-connector-java.jar /usr/local/hive/lib
RUN rm -f /usr/local/hive/lib/guava*.jar
RUN cp ${HADOOP_HOME}/share/hadoop/common/lib/guava*.jar /usr/local/hive/lib/

ENV HIVE_HOME /usr/local/hive
ENV PATH $HIVE_HOME/bin:$PATH
