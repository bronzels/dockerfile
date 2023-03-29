#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
ARG java_image_tag=17-jre

FROM eclipse-temurin:${java_image_tag} as base

# ARG spark_uid=185

# Before building the docker image, first build and make a Spark distribution following
# the instructions in http://spark.apache.org/docs/latest/building-spark.html.
# If this docker file is being used in the context of building your images from a Spark
# distribution, the docker build command should be invoked from the top level directory
# of the Spark distribution. E.g.:
# docker build -t spark:latest -f kubernetes/dockerfiles/spark/Dockerfile .

RUN sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list

RUN set -ex && \
    apt-get update && \
    ln -s /lib /lib64 && \
    apt install -y bash tini libc6 libpam-modules krb5-user libnss3 procps net-tools && \
    rm /bin/sh && \
    ln -sv /bin/bash /bin/sh && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    rm -rf /var/cache/apt/* && rm -rf /var/lib/apt/lists/*

RUN useradd -u 10001 -d /opt/spark hdfs
RUN mkdir -p /opt/spark
RUN chown hdfs:hdfs /opt/spark
RUN usermod -g root hdfs

RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

USER hdfs

FROM base as spark

### Download Spark Distribution ###
WORKDIR /opt/spark

ARG SPARK_VERSION=?
#COPY spark-${SPARK_VERSION}-bin-hadoop3.tgz /opt/spark/
#RUN tar xzvf spark-${SPARK_VERSION}-bin-hadoop3.tgz
COPY --chown=hdfs:root spark-${SPARK_VERSION}-bin-volcano-rss.tgz /opt/spark/
RUN tar xzvf spark-${SPARK_VERSION}-bin-volcano-rss.tgz

FROM spark as build
### Create target directories ###
RUN mkdir -p /opt/spark/jars

FROM harbor.my.org:1080/bronzels/hive-ubussh-juicefs:0.1 as hadoop

### Set Spark dir ARG for use Docker build context on root project dir ###
FROM base as final
ENV SPARK_HOME /opt/spark

RUN mkdir ${SPARK_HOME}/logs
RUN mkdir ${SPARK_HOME}/work-dir

USER root

ARG SPARK_VERSION=?
#ENV _spark_dir=/opt/spark-${SPARK_VERSION}-bin-hadoop3
ENV _spark_dir=/opt/spark/spark-${SPARK_VERSION}-bin-volcano-rss
### Copy files from the build image ###
COPY --from=build --chown=hdfs:root ${_spark_dir}/jars /opt/spark/jars
COPY --from=build --chown=hdfs:root /opt/spark/jars /opt/spark/jars
COPY --from=build --chown=hdfs:root ${_spark_dir}/bin /opt/spark/bin
COPY --from=build --chown=hdfs:root ${_spark_dir}/sbin /opt/spark/sbin
COPY --from=build --chown=hdfs:root ${_spark_dir}/kubernetes/dockerfiles/spark/decom.sh /opt/spark/
COPY --from=build --chown=hdfs:root ${_spark_dir}/examples /opt/spark/examples
COPY --from=build --chown=hdfs:root ${_spark_dir}/kubernetes/tests /opt/spark/tests
COPY --from=build --chown=hdfs:root ${_spark_dir}/data /opt/spark/data

WORKDIR /opt/spark/work-dir
RUN chmod g+w /opt/spark/work-dir
RUN chmod a+x /opt/spark/decom.sh

ENTRYPOINT [ "/opt/spark/entrypoint.sh" ]

# Specify the User that the actual main process will run as
# USER ${spark_uid}

# Add native libs

#RUN mkdir /opt/spark/imgconf
#ENV SPARK_CONF_DIR=/opt/spark/imgconf

ARG JUICEFS_VERSION=?
COPY --chown=hdfs:root juicefs-hadoop-${JUICEFS_VERSION}.jar /opt/spark/jars/
COPY --chown=hdfs:root core-site.xml /opt/spark/conf/
COPY --chown=hdfs:root hdfs-site.xml /opt/spark/conf/

COPY --from=hadoop /usr/local/bin/mc /usr/local/bin/
COPY --from=hadoop /usr/local/bin/miniogw /usr/local/bin/
COPY --from=hadoop /usr/local/bin/juicefs /usr/local/bin/

COPY --chown=hdfs:root hive-site.xml /opt/spark/imgconf/
COPY --chown=hdfs:root hive-site.xml /opt/spark/conf/
#RUN ln -s  /opt/spark/hive/lib/mysql-connector-java.jar  /opt/spark/jars/mysql-connector-java.jar

COPY --chown=hdfs:root spark-sql-cluster-mode-3/target/my-spark-sql-cluster-3.jar /opt/spark/work-dir/

ARG SCALA_VERSION=?
ARG SPARK_SHORTEST_VERSION=?
ARG RSS_VERSION=?
COPY --chown=hdfs:root celeborn-client-spark-${SPARK_SHORTEST_VERSION}-shaded_${SCALA_VERSION}-${RSS_VERSION}.jar /opt/spark/jars/

COPY --chown=hdfs:root spark-defaults.conf /opt/spark/imgconf/
COPY --chown=hdfs:root spark-defaults.conf /opt/spark/conf/
#COPY --chown=hdfs:root spark-defaults-rss.conf /opt/spark/imgconf/spark-defaults.conf

#history server
COPY envsubst /usr/local/bin/

ENV PATH=.:${PATH}:${SPARK_HOME}/bin
ENV TIME_ZONE Asia/Shanghai
COPY --chown=hdfs:root spark-sql-delta.sh /opt/spark/work-dir/
COPY --chown=hdfs:root podgroups /opt/spark/work-dir/podgroups

WORKDIR /opt/spark/work-dir

ARG SPARK_SHORT_VERSION=?
COPY --chown=hdfs:root doris-spark-connector-master/spark-doris-connector/target/spark-doris-connector-${SPARK_SHORT_VERSION}_${SCALA_VERSION}-1.0.0-SNAPSHOT.jar /opt/spark/jars/
#COPY --chown=hdfs:root starrocks-connector-for-apache-spark-main/target/starrocks-spark${SPARK_SHORTEST_VERSION}_${SCALA_VERSION}-1.0.0.jar /opt/spark/jars/

COPY --chown=hdfs:root entrypoint.sh /opt/spark/entrypoint.sh
USER hdfs

ARG TARGET_BUILT=?
ARG HUDI_VERSION=?
COPY hudibk/${TARGET_BUILT}/hudi-spark${SPARK_SHORT_VERSION}-bundle_${SCALA_VERSION}-${HUDI_VERSION}.jar /opt/spark/jars/
