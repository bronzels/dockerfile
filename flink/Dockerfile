#FROM harbor.my.org:1080/bronzels/hive-ubussh-juicefs:0.1 as hadoop
ARG FLINK_SHORT_VERSION=?
FROM flink:${FLINK_SHORT_VERSION}
#eclipse-temurin:11-jre
#ubuntu:22.04
ARG FLINK_SHORT_VERSION=?
ARG FLINKOP_VERSION=?
ARG JUICEFS_VERSION=?
ARG STARROCKS_CONNECTOR_VERSION=?
ARG SCALA_VERSION=?
ARG FLINK_VERSION=?
ARG HIVEREV=?
ARG HUDI_VERSION=?
ARG HADOOP_VERSION=?

ENV PATH=$PATH:$FLINK_HOME/bin

RUN mkdir /opt/flink/usrlib
RUN chown flink:flink /opt/flink/usrlib
#USER root

COPY --chown=flink:flink juicefs-hadoop-${JUICEFS_VERSION}-jdk11-ubuntu22.04.jar $FLINK_HOME/lib/

COPY --chown=flink:flink setting.sql $FLINK_HOME/usrlib/

COPY --chown=flink:flink conf/flink-conf.yaml $FLINK_HOME/conf/
COPY --chown=flink:flink conf/log4j.properties $FLINK_HOME/conf/
COPY --chown=flink:flink conf/log4j-console.properties $FLINK_HOME/conf/
COPY --chown=flink:flink conf/core-site.xml $FLINK_HOME/conf/
COPY --chown=flink:flink conf/hdfs-site.xml $FLINK_HOME/conf/
COPY --chown=flink:flink conf/hive-site.xml $FLINK_HOME/conf/

RUN mkdir $FLINK_HOME/hiveconf
RUN chown flink:flink $FLINK_HOME/hiveconf
COPY --chown=flink:flink conf/hive-site.xml $FLINK_HOME/hiveconf/

COPY --chown=flink:flink test/testsql $FLINK_HOME/usrlib/testsql
COPY --chown=flink:flink test/testsql-hivecat $FLINK_HOME/usrlib/testsql-hivecat

#COPY --from=hadoop --chown=flink:flink /app/hdfs/hadoop /opt/hadoop
COPY --chown=flink:flink hadoop-${HADOOP_VERSION} /opt/hadoop
ENV HADOOP_HOME=/opt/hadoop \
    HADOOP_COMMON_HOME=/opt/hadoop \
    HADOOP_HDFS_HOME=/opt/hadoop \
    HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop \
    PATH=${PATH}:/opt/hadoop/bin
ENV HADOOP_CLASSPATH=/opt/hadoop/etc/hadoop:/opt/hadoop/share/hadoop/common/lib/*:/opt/hadoop/share/hadoop/common/*:/opt/hadoop/share/hadoop/hdfs:/opt/hadoop/share/hadoop/hdfs/lib/*:/opt/hadoop/share/hadoop/hdfs/*
RUN echo "export HADOOP_CLASSPATH=/opt/hadoop/etc/hadoop:/opt/hadoop/share/hadoop/common/lib/*:/opt/hadoop/share/hadoop/common/*:/opt/hadoop/share/hadoop/hdfs:/opt/hadoop/share/hadoop/hdfs/lib/*:/opt/hadoop/share/hadoop/hdfs/*" >> $FLINK_HOME/bin/config.sh

COPY --chown=flink:flink flink-sql-connector-hive-${HIVEREV}_${SCALA_VERSION}-${FLINK_VERSION}.jar $FLINK_HOME/lib/
COPY --chown=flink:flink flink-shaded-hadoop-3-3.1.1.7.2.9.0-173-9.0.jar $FLINK_HOME/lib/

COPY --chown=flink:flink hive-exec-${HIVEREV}.jar $FLINK_HOME/lib/
COPY --chown=flink:flink flink-connector-hive_${SCALA_VERSION}-${FLINK_VERSION}.jar $FLINK_HOME/lib/
COPY --chown=flink:flink htrace-core4-4.1.0-incubating.jar $FLINK_HOME/lib/

#COPY --chown=flink:flink starrocks-connector-for-apache-flink-${STARROCKS_CONNECTOR_VERSION}/target/flink-connector-starrocks-${STARROCKS_CONNECTOR_VERSION}_flink-${FLINK_SHORT_VERSION}.jar $FLINK_HOME/lib/

#flink 1.5-16
#COPY --chown=flink:flink flink-sql-connector-kafka-${FLINK_VERSION}.jar $FLINK_HOME/lib/
#flink <= 1.4
COPY --chown=flink:flink flink-sql-connector-kafka_${SCALA_VERSION}-${FLINK_VERSION}.jar $FLINK_HOME/lib/
COPY --chown=flink:flink hudi-flink${FLINK_SHORT_VERSION}-bundle-${HUDI_VERSION}.jar $FLINK_HOME/lib/

#COPY --chown=flink:flink flink-kubernetes-operator-release-${FLINKOP_VERSION}/examples/flink-sql-runner-example/target/flink-sql-runner-example-${FLINKOP_VERSION}.jar /opt/flink/usrlib/sql-runner.jar
#COPY --chown=flink:flink flink-kubernetes-operator-release-${FLINKOP_VERSION}/examples/flink-sql-runner-example/sql-scripts /opt/flink/usrlib/sql-scripts
#USER flink






