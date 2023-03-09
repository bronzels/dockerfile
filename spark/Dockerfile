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

RUN useradd -u 10001 -d /app/hdfs hdfs
RUN mkdir -p /app/hdfs
RUN chown hdfs:hdfs /app/hdfs
RUN usermod -g root hdfs

RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

USER hdfs

FROM base as spark
ARG SPARK_VERSION
### Download Spark Distribution ###
WORKDIR /app/hdfs

#COPY spark-${SPARK_VERSION}-bin-hadoop3.tgz /app/hdfs/
#RUN tar xzvf spark-${SPARK_VERSION}-bin-hadoop3.tgz
COPY --chown=hdfs:root spark-${SPARK_VERSION}-bin-volcano-rss.tgz /app/hdfs/
RUN tar xzvf spark-${SPARK_VERSION}-bin-volcano-rss.tgz

FROM spark as build
### Create target directories ###
RUN mkdir -p /app/hdfs/spark/jars

FROM harbor.my.org:1080/bronzels/hive-ubussh-juicefs:0.1 as hadoop

### Set Spark dir ARG for use Docker build context on root project dir ###
FROM base as final
ARG SPARK_VERSION
ARG HADOOP_VERSION
ARG HIVEREV
ARG RSS_VERSION

RUN mkdir /app/hdfs/spark

#ENV _spark_dir=/app/hdfs/spark-${SPARK_VERSION}-bin-hadoop3
ENV _spark_dir=/app/hdfs/spark-${SPARK_VERSION}-bin-volcano-rss
### Copy files from the build image ###
COPY --from=build --chown=hdfs:root ${_spark_dir}/jars /app/hdfs/spark/jars
COPY --from=build --chown=hdfs:root /app/hdfs/spark/jars /app/hdfs/spark/jars
COPY --from=build --chown=hdfs:root ${_spark_dir}/bin /app/hdfs/spark/bin
COPY --from=build --chown=hdfs:root ${_spark_dir}/sbin /app/hdfs/spark/sbin
COPY --from=build --chown=hdfs:root ${_spark_dir}/kubernetes/dockerfiles/spark/entrypoint.sh /app/hdfs/
COPY --from=build --chown=hdfs:root ${_spark_dir}/kubernetes/dockerfiles/spark/decom.sh /app/hdfs/
COPY --from=build --chown=hdfs:root ${_spark_dir}/examples /app/hdfs/spark/examples
COPY --from=build --chown=hdfs:root ${_spark_dir}/kubernetes/tests /app/hdfs/spark/tests
COPY --from=build --chown=hdfs:root ${_spark_dir}/data /app/hdfs/spark/data

ENV SPARK_HOME /app/hdfs/spark

RUN mkdir /app/hdfs/spark/work-dir
WORKDIR /app/hdfs/spark/work-dir
RUN chmod g+w /app/hdfs/spark/work-dir
RUN chmod a+x /app/hdfs/decom.sh

ENTRYPOINT [ "/app/hdfs/entrypoint.sh" ]

# Specify the User that the actual main process will run as
# USER ${spark_uid}

# Add native libs

RUN mkdir /app/hdfs/spark/conf

COPY --from=hadoop --chown=hdfs:root /app/hdfs/hadoop/share/hadoop/common/lib/juicefs-hadoop-1.0.2.jar /app/hdfs/spark/jars
#COPY --from=hadoop --chown=hdfs:root /app/hdfs/hadoop/etc/hadoop/core-site.xml /app/hdfs/spark/conf
COPY --chown=hdfs:root core-site.xml /app/hdfs/spark/conf

COPY --from=hadoop /usr/local/bin/mc /usr/local/bin/mc
COPY --from=hadoop /usr/local/bin/miniogw /usr/local/bin/miniogw
COPY --from=hadoop /usr/local/bin/juicefs /usr/local/bin/juicefs

COPY --chown=hdfs:root hive-site.xml /app/hdfs/spark/conf/
#RUN ln -s  /app/hdfs/hive/lib/mysql-connector-java.jar  /app/hdfs/spark/jars/mysql-connector-java.jar

COPY --chown=hdfs:root spark-sql-cluster-mode-3/target/my-spark-sql-cluster-3.jar /app/hdfs/spark/jars/

COPY --chown=hdfs:root celeborn-client-spark-3-shaded_2.12-${RSS_VERSION}.jar /app/hdfs/spark/jars/

COPY --chown=hdfs:root spark-defaults.conf /app/hdfs/spark/conf/spark-defaults.conf
#COPY --chown=hdfs:root spark-defaults-rss.conf /app/hdfs/spark/conf/spark-defaults.conf

#history server
COPY envsubst /usr/local/bin/
RUN mkdir ${SPARK_HOME}/logs
COPY --chown=hdfs:root hdfs-site.xml /app/hdfs/spark/conf/

ENV PATH=.:${PATH}:${SPARK_HOME}/bin
ENV TIME_ZONE Asia/Shanghai
COPY --chown=hdfs:root spark-sql-job.sh /app/hdfs/spark/work-dir/
COPY --chown=hdfs:root podgroups /app/hdfs/spark/work-dir/podgroups

WORKDIR /app/hdfs/spark/work-dir

COPY --chown=hdfs:root doris-spark-connector-master/spark-doris-connector/target/spark-doris-connector-3.3_2.12-1.0.0-SNAPSHOT.jar /app/hdfs/spark/jars/
#COPY --chown=hdfs:root starrocks-connector-for-apache-spark-main/target/starrocks-spark3_2.12-1.0.0.jar /app/hdfs/spark/jars/
