ARG FLINK_VERSION
FROM flink:${FLINK_VERSION}
ARG FLINK_CDC_VERSION
ARG MYSQL_PIPELINE_CONNECTOR_VERSION
ARG STARROCKS_PIPELINE_CONNECTOR_VERSION

ADD flink-cdc-${FLINK_CDC_VERSION}-bin.tar /opt/flink/
RUN chown -R flink:flink /opt/flink/flink-cdc-${FLINK_CDC_VERSION}
RUN ln -s /opt/flink/flink-cdc-${FLINK_CDC_VERSION} /opt/flink/flink-cdc
RUN chown flink:flink /opt/flink/flink-cdc

COPY flink-cdc-pipeline-connector-mysql-${MYSQL_PIPELINE_CONNECTOR_VERSION}.jar /opt/flink/lib/
RUN chown flink:flink /opt/flink/lib/flink-cdc-pipeline-connector-mysql-${MYSQL_PIPELINE_CONNECTOR_VERSION}.jar
COPY flink-cdc-pipeline-connector-mysql-${MYSQL_PIPELINE_CONNECTOR_VERSION}.jar /opt/flink/flink-cdc/lib/
RUN chown flink:flink /opt/flink/flink-cdc/lib/flink-cdc-pipeline-connector-mysql-${MYSQL_PIPELINE_CONNECTOR_VERSION}.jar

COPY flink-cdc-pipeline-connector-starrocks-${STARROCKS_PIPELINE_CONNECTOR_VERSION}.jar /opt/flink/lib/
RUN chown flink:flink /opt/flink/lib/flink-cdc-pipeline-connector-starrocks-${STARROCKS_PIPELINE_CONNECTOR_VERSION}.jar
COPY flink-cdc-pipeline-connector-starrocks-${STARROCKS_PIPELINE_CONNECTOR_VERSION}.jar /opt/flink/flink-cdc/lib/
RUN chown flink:flink /opt/flink/flink-cdc/lib/flink-cdc-pipeline-connector-starrocks-${STARROCKS_PIPELINE_CONNECTOR_VERSION}.jar

ENV PATH="/opt/flink/flink-cdc/bin:${PATH}"