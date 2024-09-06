#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
ARG FLINK_VERSION=?
ARG TARGET_BUILT=?
FROM harbor.my.org:1080/flink/flink-juicefs-${TARGET_BUILT}:${FLINK_VERSION}

ENV NODE_VERSION=16.1.0
ENV NPM_VERSION=7.11.2
COPY node-v$NODE_VERSION-linux-x64.tar.gz ./
ARG K8S_VERSION=?
RUN tar zxvf "node-v$NODE_VERSION-linux-x64.tar.gz" -C /usr/local --strip-components=1 \
    && rm "node-v$NODE_VERSION-linux-x64.tar.gz" \
    && ln -s /usr/local/bin/node /usr/local/bin/nodejs \
    && curl -LO https://dl.k8s.io/release/v${K8S_VERSION}/bin/linux/amd64/kubectl \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

WORKDIR /streampark
COPY streampark /streampark

RUN sed -i -e 's/eval $NOHUP/eval/' bin/streampark.sh \
    && sed -i -e 's/>> "$APP_OUT" 2>&1 "&"//' bin/streampark.sh

COPY maven /usr/local/maven
COPY m2 /root/.m2

RUN sed -i 's@/archive.ubuntu.com/@/mirrors.aliyun.com/@g' /etc/apt/sources.list
RUN apt update
RUN apt install -y wget vim curl

ENV JAVA_HOME=/opt/java/openjdk
ENV MAVEN_HOME=/usr/local/maven
ENV PATH $JAVA_HOME/bin:$PATH
ENV PATH $MAVEN_HOME/bin:$PATH

RUN mkdir -p ~/.kube

EXPOSE 10000
COPY mysql-connector-java-8.0.28.jar /streampark/lib/
ARG JUICEFS_VERSION=?
RUN cp $FLINK_HOME/lib/juicefs-hadoop-${JUICEFS_VERSION}.jar $HADOOP_HOME/share/hadoop/common/lib/