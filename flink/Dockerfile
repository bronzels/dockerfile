FROM harbor.my.org:1080/bronzels/hive-ubussh-juicefs:0.1 as hadoop
FROM flink:1.15
#eclipse-temurin:11-jre
#ubuntu:22.04
ARG FLINKOP_VERSION=?
ARG JUICEFS_VERSION=?
ARG STARROCKS_CONNECTOR_VERSION=?
ARG FLINK_SHORT_VERSION=?
ARG SCALA_VERSION=?
ARG FLINK_VERSION=?
ARG HIVEREV=?
ARG HUDI_VERSION=?

ENV PATH=$PATH:$FLINK_HOME/bin

RUN mkdir /opt/flink/usrlib
USER root
COPY --chown=flink:flink flink-kubernetes-operator-release-${FLINKOP_VERSION}/examples/flink-sql-runner-example/target/flink-sql-runner-example-*.jar /opt/flink/usrlib/sql-runner.jar
COPY --chown=flink:flink flink-kubernetes-operator-release-${FLINKOP_VERSION}/examples/flink-sql-runner-example/sql-scripts /opt/flink/usrlib/sql-scripts

COPY --chown=flink:flink hive-site.xml $FLINK_HOME/conf/hive-site.xml
COPY --chown=flink:flink juicefs-hadoop-${JUICEFS_VERSION}-jdk11-ubuntu22.04.jar $FLINK_HOME/lib/

COPY --chown=flink:flink starrocks-connector-for-apache-flink-${STARROCKS_CONNECTOR_VERSION}/target/flink-connector-starrocks-${STARROCKS_CONNECTOR_VERSION}_flink-${FLINK_SHORT_VERSION}.jar $FLINK_HOME/lib/

COPY --from=hadoop --chown=flink:flink /app/hdfs/hadoop /opt/hadoop
ENV HADOOP_HOME=/opt/hadoop \
    HADOOP_COMMON_HOME=/opt/hadoop \
    HADOOP_HDFS_HOME=/opt/hadoop \
    HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop \
    PATH=${PATH}:/opt/hadoop/bin
ENV HADOOP_CLASSPATH=/opt/hadoop/etc/hadoop:/opt/hadoop/share/hadoop/common/lib/*:/opt/hadoop/share/hadoop/common/*:/opt/hadoop/share/hadoop/hdfs:/opt/hadoop/share/hadoop/hdfs/lib/*:/opt/hadoop/share/hadoop/hdfs/*
#COPY --chown=flink:flink flink-conf.yaml $FLINK_HOME/conf/
RUN echo "export HADOOP_CLASSPATH=/opt/hadoop/etc/hadoop:/opt/hadoop/share/hadoop/common/lib/*:/opt/hadoop/share/hadoop/common/*:/opt/hadoop/share/hadoop/hdfs:/opt/hadoop/share/hadoop/hdfs/lib/*:/opt/hadoop/share/hadoop/hdfs/*" >> $FLINK_HOME/bin/config.sh
COPY --chown=flink:flink setting.sql $FLINK_HOME/conf/
COPY --chown=flink:flink flink-sql-connector-hive-${HIVEREV}_${SCALA_VERSION}-${FLINK_VERSION}.jar $FLINK_HOME/lib/
COPY --chown=flink:flink flink-shaded-hadoop-3-3.1.1.7.2.9.0-173-9.0.jar $FLINK_HOME/lib/

COPY --chown=flink:flink flink-sql-connector-kafka-${FLINK_VERSION}.jar $FLINK_HOME/lib/
COPY --chown=flink:flink hudi-flink${FLINK_SHORT_VERSION}-bundle-${HUDI_VERSION}.jar $FLINK_HOME/lib/

USER flink
