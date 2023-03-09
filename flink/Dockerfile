FROM flink:1.15
ARG FLINKOP_VERSION=?
ARG JUICEFS_VERSION=?
ARG STARROCKS_CONNECTOR_VERSION=?
ARG FLINK_SHORT_VERSION=?

RUN mkdir /opt/flink/usrlib
ADD flink-kubernetes-operator-release-${FLINKOP_VERSION}/examples/flink-sql-runner-example/target/flink-sql-runner-example-*.jar /opt/flink/usrlib/sql-runner.jar
ADD flink-kubernetes-operator-release-${FLINKOP_VERSION}/examples/flink-sql-runner-example/sql-scripts /opt/flink/usrlib/sql-scripts

USER root
COPY --chown=flink:flink core-site.xml $FLINK_HOME/conf/core-site.xml
COPY --chown=flink:flink hdfs-site.xml $FLINK_HOME/conf/hdfs-site.xml
COPY --chown=flink:flink hive-site.xml $FLINK_HOME/conf/hive-site.xml
COPY --chown=flink:flink juicefs-hadoop-${JUICEFS_VERSION}-jdk11-ubuntu22.04.jar $FLINK_HOME/plugins/juicefs-hadoop-${JUICEFS_VERSION}-jdk11-ubuntu22.04.jar

COPY --chown=flink:flink starrocks-connector-for-apache-flink-${STARROCKS_CONNECTOR_VERSION}/target/flink-connector-starrocks-${STARROCKS_CONNECTOR_VERSION}_flink-${FLINK_SHORT_VERSION}.jar $FLINK_HOME/plugins/
USER flink
