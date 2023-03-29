if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Mac detected."
    #mac
    os=darwin
    MYHOME=/Volumes/data
    SED=gsed
    bin=/Users/apple/bin
else
    echo "Assuming linux by default."
    #linux
    os=linux
    MYHOME=~
    SED=sed
    bin=/usr/local/bin
fi

MYDOLPHINSCH_HOME=${MYHOME}/workspace/dockerfile/dolphinsch
DOLPHINSCH_REV=3.1.3
SPARK_VERSION=3.3.1

cd ${MYDOLPHINSCH_HOME}

kubectl create ns dophinsch

wget -c https://www.apache.org/dyn/closer.lua/dolphinscheduler/${DOLPHINSCH_REV}/apache-dolphinscheduler-${DOLPHINSCH_REV}-src.tar.gz
tar -zxvf apache-dolphinscheduler-${DOLPHINSCH_REV}-src.tar.gz

cd ${MYDOLPHINSCH_HOME}/apache-dolphinscheduler-${DOLPHINSCH_REV}-src
:<<EOF
file=mvnw
chmod a+x ${file}
cp ${file} ${file}.bk
$SED -i 's@darwin=false;@darwin=true;@g' ${file}
export M2_HOME=/Volumes/data/m2
./mvnw clean install -Prelease

wget -c https://gitee.com/link?target=https%3A%2F%2Frepo1.maven.org%2Fmaven2%2Fcom%2Fgoogle%2Ferrorprone%2Fjavac-shaded%2F9%2B181-r4173-1%2Fjavac-shaded-9%2B181-r4173-1.jar
mvn install:install-file -DgroupId=com.google.errorprone -DartifactId=javac-shaded -Dversion=9+181-r4173-1 -Dpackaging=jar -Dfile=javac-shaded-9+181-r4173-1.jar
EOF
file=pom.xml
cp ${file} ${file}.bk
:<<EOF
禁用这个代码风格修正插件
                <groupId>com.diffplug.spotless</groupId>
                <artifactId>spotless-maven-plugin</artifactId>
EOF

mvn install clean -Prelease -DskipTests
#package没法编译

#docker
ansible all -m shell -a"docker images|grep dolphinscheduler"
ansible all -m shell -a"docker images|grep dolphinscheduler|awk '{print \$3}'|xargs docker rmi -f"
#containerd
ansible all -m shell -a"crictl images|grep dolphinscheduler"
ansible all -m shell -a"crictl images|grep dolphinscheduler |awk '{print \$3}'|xargs crictl rmi"

cd ${MYDOLPHINSCH_HOME}/apache-dolphinscheduler-${DOLPHINSCH_REV}-src
cd deploy/docker
tar xzvf ${MYDOLPHINSCH_HOME}/apache-dolphinscheduler-${DOLPHINSCH_REV}-src/dolphinscheduler-dist/target/apache-dolphinscheduler-${DOLPHINSCH_REV}-bin.tar.gz


cat << \EOF > p1.2
ARG DOLPHINSCH_REV=
ENV DOCKER true
ENV TZ Asia/Shanghai
ENV DOLPHINSCHEDULER_HOME /opt/dolphinscheduler

WORKDIR $DOLPHINSCHEDULER_HOME

ARG DOLPHINSCH_REV=

EOF

arr=(worker master api alert tools)
for prj in ${arr[*]}
do

  if [[ "${prj}" =~ "worker" || "${prj}" =~ "api" ]]; then
cat << EOF > p1.1
FROM harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss:3.3.1 AS spark

FROM eclipse-temurin:8-jre AS final

EOF
  else
cat << EOF > p1.1
FROM eclipse-temurin:8-jre

EOF
  fi

  if [[ "${prj}" =~ "worker" ]]; then
cat << EOF > p2
RUN sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list

RUN set -ex && \
    apt-get update && \
    ln -s /lib /lib64 && \
    apt install -y bash tini libc6 libpam-modules krb5-user libnss3 procps net-tools sudo && \
    rm /bin/sh && \
    ln -sv /bin/bash /bin/sh && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    rm -rf /var/cache/apt/* && rm -rf /var/lib/apt/lists/*

RUN useradd -d /app/hdfs hdfs
RUN mkdir -p /app/hdfs
RUN chown hdfs:hdfs /app/hdfs
RUN usermod -g root hdfs

RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
ENV TIME_ZONE Asia/Shanghai

COPY --from=spark --chown=hdfs:root /app/hdfs/spark /app/hdfs/spark
ENV SPARK_HOME /app/hdfs/spark

COPY --from=spark --chown=hdfs:root /app/hdfs/decom.sh /app/hdfs/decom.sh

COPY --from=spark /usr/local/bin/mc /usr/local/bin/mc
COPY --from=spark /usr/local/bin/miniogw /usr/local/bin/miniogw
COPY --from=spark /usr/local/bin/juicefs /usr/local/bin/juicefs

EOF
  elif [[ "${prj}" =~ "api" ]]; then
cat << EOF > p2
RUN useradd -d /app/hdfs hdfs
RUN mkdir -p /app/hdfs
RUN chown hdfs:hdfs /app/hdfs
RUN usermod -g root hdfs

RUN mkdir /app/hdfs/spark
RUN chown hdfs:root /app/hdfs/spark
COPY --from=spark --chown=hdfs:root /app/hdfs/spark/conf /app/hdfs/spark/conf
ENV HADOOP_CONF_DIR /app/hdfs/spark/conf

EOF
  else
    echo "" > p2
  fi

  if [[ "${prj}" =~ "tools" ]]; then
cat << EOF > p3
ADD apache-dolphinscheduler-\${DOLPHINSCH_REV}-bin/${prj} \$DOLPHINSCHEDULER_HOME/tools
EOF
  elif [[ "${prj}" =~ "api" ]]; then
cat << EOF > p3
ADD apache-dolphinscheduler-\${DOLPHINSCH_REV}-bin/${prj}-server \$DOLPHINSCHEDULER_HOME
COPY --from=spark --chown=hdfs:root /app/hdfs/spark/jars/juicefs-hadoop-1.0.2.jar \$DOLPHINSCHEDULER_HOME/libs
EOF
  else
cat << EOF > p3
ADD apache-dolphinscheduler-\${DOLPHINSCH_REV}-bin/${prj}-server \$DOLPHINSCHEDULER_HOME
EOF
  fi

  if [[ "${prj}" =~ "worker" ]]; then
cat << \EOF > p4
EXPOSE 1235
EOF
  elif [[ "${prj}" =~ "master" ]]; then
cat << \EOF > p4
EXPOSE 12345
EOF
  elif [[ "${prj}" =~ "api" ]]; then
cat << \EOF > p4
EXPOSE 12345 25333
EOF
  elif [[ "${prj}" =~ "alert" ]]; then
cat << \EOF > p4
EXPOSE 50052 50053
EOF
  else
    echo "" > p4
  fi

  if [[ "${prj}" =~ "tools" ]]; then
cat << \EOF > p5
ENTRYPOINT [ "/bin/bash" ]
EOF
  else
cat << \EOF > p5
CMD [ "/bin/bash", "./bin/start.sh" ]
EOF
  fi

  file=Dockerfile.${prj}
  cat p1.1 > ${file}
  cat p1.2 >> ${file}
  cat p2 >> ${file}
  cat p3 >> ${file}
  cat p4 >> ${file}
  cat p5 >> ${file}
  cat ${file}

done
rm -f p*

#设置HADOOP_CONF_DIR，但还是读不到core-site.xml，修改启动脚本，加入juicefs相关hdfs conf到cp
#加到最前面会被后面hadoop相关jar的空配置文件覆盖，要加到最后面
arr=(api worker)
for prj in ${arr[*]}
do
  file=apache-dolphinscheduler-${DOLPHINSCH_REV}-bin/${prj}-server/bin/start.sh
  #cp ${file} ${file}.bk
  $SED -i 's/*"/*":"$HADOOP_CONF_DIR"/g' ${file}
done


#wget -c https://cdn.mysql.com//archives/mysql-connector-java-8.0/mysql-connector-java-8.0.16.zip
arr=(worker master api alert tools)
for prj in ${arr[*]}
do
  if [[ "${prj}" =~ "tools" ]]; then
    mydir=apache-dolphinscheduler-${DOLPHINSCH_REV}-bin/${prj}/libs
  else
    mydir=apache-dolphinscheduler-${DOLPHINSCH_REV}-bin/${prj}-server/libs
  fi
  cp ~/.m2/repository/mysql/mysql-connector-java/8.0.16/mysql-connector-java-8.0.16.jar ${mydir}/
  ls ${mydir}/mysql-connector-java-8.0.16.jar
done


arr=(worker master api alert tools)
#arr=(worker)
for prj in ${arr[*]}
do
  if [[ "${prj}" =~ "worker" ]]; then
    docker build ./ -f Dockerfile.${prj} --progress=plain --build-arg DOLPHINSCH_REV="${DOLPHINSCH_REV}" --build-arg SPARK_VERSION="${SPARK_VERSION}" -t harbor.my.org:1080/dolphinsch/dolphinscheduler-worker-spark-${SPARK_VERSION}:${DOLPHINSCH_REV}
    docker push harbor.my.org:1080/dolphinsch/dolphinscheduler-worker-spark-${SPARK_VERSION}:${DOLPHINSCH_REV}
  elif [[ "${prj}" =~ "api" ]]; then
    docker build ./ -f Dockerfile.${prj} --progress=plain --build-arg DOLPHINSCH_REV="${DOLPHINSCH_REV}" -t harbor.my.org:1080/dolphinsch/dolphinscheduler-api-juicefs:${DOLPHINSCH_REV}
    docker push harbor.my.org:1080/dolphinsch/dolphinscheduler-api-juicefs:${DOLPHINSCH_REV}
  else
    docker build ./ -f Dockerfile.${prj} --progress=plain --build-arg DOLPHINSCH_REV="${DOLPHINSCH_REV}" -t harbor.my.org:1080/dolphinsch/dolphinscheduler-${prj}:${DOLPHINSCH_REV}
    docker push harbor.my.org:1080/dolphinsch/dolphinscheduler-${prj}:${DOLPHINSCH_REV}
  fi
done

cd ${MYDOLPHINSCH_HOME}/apache-dolphinscheduler-${DOLPHINSCH_REV}-src
cd deploy/kubernetes/dolphinscheduler

cp -rf templates templates.bk
$SED -i 's/          image: {{ include "dolphinscheduler.image.fullname.worker" . }}/          image: {{ .Values.image.worker }}:{{ .Values.image.tag }}/g' templates/statefulset-dolphinscheduler-worker.yaml
$SED -i 's/          image: {{ include "dolphinscheduler.image.fullname.master" . }}/          image: {{ .Values.image.master }}:{{ .Values.image.tag }}/g' templates/statefulset-dolphinscheduler-master.yaml
$SED -i 's/          image: {{ include "dolphinscheduler.image.fullname.api" . }}/          image: {{ .Values.image.api }}:{{ .Values.image.tag }}/g' templates/deployment-dolphinscheduler-api.yaml
$SED -i 's/          image: {{ include "dolphinscheduler.image.fullname.alert" . }}/          image: {{ .Values.image.alert }}:{{ .Values.image.tag }}/g' templates/deployment-dolphinscheduler-alert.yaml
$SED -i 's/          image: {{ include "dolphinscheduler.image.fullname.tools" . }}/          image: {{ .Values.image.tools }}:{{ .Values.image.tag }}/g' templates/job-dolphinscheduler-schema-initializer.yaml

file=values.yaml
cp ${file} ${file}.bk
$SED -i 's@    resource.hdfs.fs.defaultFS: hdfs://mycluster:8020@    resource.hdfs.fs.defaultFS: jfs://miniofs@g' ${file}
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- bash
  hadoop fs -mkdir -p /k8sup/dolphinsch
$SED -i 's@    resource.storage.upload.base.path: /dolphinscheduler@    resource.storage.upload.base.path: jfs://miniofs/k8sup/dolphinsch@g' ${file}
#$SED -i 's@    storageClass: "-"@    storageClass: "juicefs-sc"@g' ${file}

helm repo add bitnami https://charts.bitnami.com/bitnami
helm dependency update .
kubectl create ns dolphinsch
helm search repo dolphinscheduler


:<<EOF
helm install my bitnami/dolphinscheduler \
  --set image.worker=harbor.my.org:1080/dolphinsch/dolphinscheduler-worker-spark-${SPARK_VERSION} \
  --set image.api=harbor.my.org:1080/dolphinsch/dolphinscheduler-api-juicefs \
  --set image.tag=${DOLPHINSCH_REV} \
  --set common.configmap.SPARK_HOME1=/app/hdfs/spark \
  --version ${DOLPHINSCH_REV} \
  -n dolphinsch
EOF

#把mysql从Chart.yaml里删除
helm dependency build
:<<EOF
#缺省安装报错：FATAL:  remaining connection slots are reserved for non-replication superuser connections
#据说缺省maxconnection 100，reserved 3，不知道为什么启动就没有了
cd charts
mv postgresql-10.3.18.tgz postgresql-10.3.18-bk.tgz
tar xzvf postgresql-10.3.18.tgz
file=postgresql/values.yaml
cp ${file} ${file}.bk
$SED -i 's/postgresqlMaxConnections:/postgresqlMaxConnections: 200/g' ${file}
tar czvf postgresql-10.3.18.tgz postgresql/
mv charts/postgresql-10.3.18.tgz charts/postgresql-10.3.18-new.tgz
mv charts/postgresql-10.3.18-bk.tgz charts/postgresql-10.3.18.tgz
EOF
#image中配置环境变量会被覆盖，helm install需要重新配置
#重启以后数据库里查不到表，可能是emptydir的pv重新创建以后数据没了，api启动也异常
#改用juicefs的pvc后，重启系统无异常，但是重启以后负责这postgresql的pvc的juicefs pod（kube-system）需要恢复正常，postgresql pod才能正常mount，可能需要手工删除重新mount
helm install my -n dolphinsch -f values.yaml \
  --set common.configmap.HADOOP_CONF_DIR=/app/hdfs/spark/conf \
  --set common.configmap.SPARK_HOME1=/app/hdfs/spark \
  --set image.worker=harbor.my.org:1080/dolphinsch/dolphinscheduler-worker-spark-${SPARK_VERSION} \
  --set image.master=harbor.my.org:1080/dolphinsch/dolphinscheduler-master \
  --set image.api=harbor.my.org:1080/dolphinsch/dolphinscheduler-api-juicefs \
  --set image.alert=harbor.my.org:1080/dolphinsch/dolphinscheduler-alert \
  --set image.tools=harbor.my.org:1080/dolphinsch/dolphinscheduler-tools \
  --set image.tag=${DOLPHINSCH_REV} \
  --set postgresql.persistence.enabled=true \
  --set postgresql.persistence.storageClass=juicefs-sc \
  --set zookeeper.persistence.enabled=true \
  --set zookeeper.persistence.storageClass=juicefs-sc \
  ./
helm uninstall my -n dolphinsch
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- bash
  hadoop fs -rm -r -f /k8sup/dolphinsch
kubectl get pod -n dolphinsch |grep -v Running |awk '{print $1}'| xargs kubectl delete pod "$1" -n dolphinsch --force --grace-period=0
watch kubectl get all -n dolphinsch
kubectl get pvc -n dolphinsch | awk '{print $1}' | xargs kubectl delete pvc -n dolphinsch
kubectl get pv | grep dolphinsch
kubectl port-forward -n dolphinsch svc/my-api 12345:12345 &

kubectl run mdpostgre-postgresql-client -n dolphinsch --rm --tty -i --restart='Never' --image docker.io/bitnami/postgresql:11.11.0-debian-10-r71 --env="PGPASSWORD=root" --command -- \
  psql --host my-postgresql -U root -d dolphinscheduler -p 5432 \
  -c "SELECT version()"

#默认的用户名和密码是 admin/dolphinscheduler123

kubectl logs -n dolphinsch `kubectl get pod -n dolphinsch | grep Running | grep my-api | awk '{print $1}'`
kubectl exec -it -n dolphinsch `kubectl get pod -n dolphinsch | grep Running | grep my-api | awk '{print $1}'` -- bash
  ps -ef|grep dolphinscheduler
root         9     1  7 16:15 ?        00:01:18 /opt/java/openjdk/bin/java -Xms512m -Xmx512m -Xmn256m -XX:-UseContainerSupport -cp /opt/dolphinscheduler/conf:/opt/dolphinscheduler/libs/* org.apache.dolphinscheduler.api.ApiApplicationServer
root       753   108  0 16:32 pts/0    00:00:00 grep --color=auto dolphinscheduler

  lsof -p 9 | grep juicefs
java      9 root  mem       REG               8,32           874771180 /opt/dolphinscheduler/libs/juicefs-hadoop-1.0.2.jar (path dev=0,482)
java      9 root  409r      REG              0,482 123976192 874771180 /opt/dolphinscheduler/libs/juicefs-hadoop-1.0.2.jar

:<<EOF
sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list
apt update
apt install -y sudo

改到juicefs 做pvc以后不再报类似错误
  --set postgresql.postgresqlMaxConnections=200 \

和目录无关，和HADOOP_HOME无关
  --set common.configmap.HADOOP_CONF_DIR=/app/hdfs/hadoop/etc/hadoop \

set没用，直接修改values
  --set conf.common.resource.hdfs.root.user=hdfs \
  --set conf.common.resource.hdfs.fs.defaultFS=jfs://miniofs \

  --set common.resource.hdfs.root.user=hdfs \
  --set common.resource.hdfs.fs.defaultFS=jfs://miniofs \
  --set common.resource.storage.upload.base.path=jfs://miniofs/tmp/k8sup \

postgresql有个错误提示
2023-01-30 08:50:27.751 GMT [164] ERROR:  relation "t_ds_worker_group" does not exist at character 23
2023-01-30 08:50:27.751 GMT [164] STATEMENT:  select *
	        from t_ds_worker_group
	        order by update_time desc
2023-01-30 08:50:27.840 GMT [169] LOG:  incomplete startup packet
2023-01-30 08:50:36.240 GMT [185] ERROR:  relation "t_ds_worker_group" does not exist at character 23
2023-01-30 08:50:36.240 GMT [185] STATEMENT:  select *
	        from t_ds_worker_group
	        order by update_time desc


但是查询这个表又显示有
kubectl run postgresql-client -n dolphinsch --rm --tty -i --restart='Never' --image docker.io/bitnami/postgresql:11.11.0-debian-10-r71 --env="PGPASSWORD=root" --command -- \
  psql --host my-postgresql -U root -d dolphinscheduler -p 5432 \
  -c "SELECT * FROM pg_tables WHERE tablename NOT LIKE 'pg%' AND tablename NOT LIKE 'sql_%' ORDER BY tablename"
 schemaname |               tablename                | tableowner | tablespace | hasindexes | hasrules | hastriggers | rowsecurity
------------+----------------------------------------+------------+------------+------------+----------+-------------+-------------
 public     | qrtz_blob_triggers                     | root       |            | t          | f        | f           | f
 public     | qrtz_calendars                         | root       |            | t          | f        | f           | f
 public     | qrtz_cron_triggers                     | root       |            | t          | f        | f           | f
 public     | qrtz_fired_triggers                    | root       |            | t          | f        | f           | f
 public     | qrtz_job_details                       | root       |            | t          | f        | f           | f
 public     | qrtz_locks                             | root       |            | t          | f        | f           | f
 public     | qrtz_paused_trigger_grps               | root       |            | t          | f        | f           | f
 public     | qrtz_scheduler_state                   | root       |            | t          | f        | f           | f
 public     | qrtz_simple_triggers                   | root       |            | t          | f        | f           | f
 public     | qrtz_simprop_triggers                  | root       |            | t          | f        | f           | f
 public     | qrtz_triggers                          | root       |            | t          | f        | f           | f
 public     | t_ds_access_token                      | root       |            | t          | f        | f           | f
 public     | t_ds_alert                             | root       |            | t          | f        | f           | f
 public     | t_ds_alert_plugin_instance             | root       |            | t          | f        | f           | f
 public     | t_ds_alert_send_status                 | root       |            | t          | f        | f           | f
 public     | t_ds_alertgroup                        | root       |            | t          | f        | f           | f
 public     | t_ds_audit_log                         | root       |            | t          | f        | f           | f
 public     | t_ds_cluster                           | root       |            | t          | f        | f           | f
 public     | t_ds_command                           | root       |            | t          | f        | f           | f
 public     | t_ds_datasource                        | root       |            | t          | f        | f           | f
 public     | t_ds_dq_comparison_type                | root       |            | t          | f        | f           | f
 public     | t_ds_dq_execute_result                 | root       |            | t          | f        | f           | f
 public     | t_ds_dq_rule                           | root       |            | t          | f        | f           | f
 public     | t_ds_dq_rule_execute_sql               | root       |            | t          | f        | f           | f
 public     | t_ds_dq_rule_input_entry               | root       |            | t          | f        | f           | f
 public     | t_ds_dq_task_statistics_value          | root       |            | t          | f        | f           | f
 public     | t_ds_environment                       | root       |            | t          | f        | f           | f
 public     | t_ds_environment_worker_group_relation | root       |            | t          | f        | f           | f
 public     | t_ds_error_command                     | root       |            | t          | f        | f           | f
 public     | t_ds_fav_task                          | root       |            | t          | f        | f           | f
 public     | t_ds_k8s                               | root       |            | t          | f        | f           | f
 public     | t_ds_k8s_namespace                     | root       |            | t          | f        | f           | f
 public     | t_ds_plugin_define                     | root       |            | t          | f        | f           | f
 public     | t_ds_process_definition                | root       |            | t          | f        | f           | f
 public     | t_ds_process_definition_log            | root       |            | t          | f        | f           | f
 public     | t_ds_process_instance                  | root       |            | t          | f        | f           | f
 public     | t_ds_process_task_relation             | root       |            | t          | f        | f           | f
 public     | t_ds_process_task_relation_log         | root       |            | t          | f        | f           | f
 public     | t_ds_project                           | root       |            | t          | f        | f           | f
 public     | t_ds_queue                             | root       |            | t          | f        | f           | f
 public     | t_ds_relation_datasource_user          | root       |            | t          | f        | f           | f
 public     | t_ds_relation_namespace_user           | root       |            | t          | f        | f           | f
 public     | t_ds_relation_process_instance         | root       |            | t          | f        | f           | f
 public     | t_ds_relation_project_user             | root       |            | t          | f        | f           | f
 public     | t_ds_relation_resources_user           | root       |            | t          | f        | f           | f
 public     | t_ds_relation_rule_execute_sql         | root       |            | t          | f        | f           | f
 public     | t_ds_relation_rule_input_entry         | root       |            | t          | f        | f           | f
 public     | t_ds_relation_udfs_user                | root       |            | t          | f        | f           | f
 public     | t_ds_resources                         | root       |            | t          | f        | f           | f
 public     | t_ds_schedules                         | root       |            | t          | f        | f           | f
 public     | t_ds_session                           | root       |            | t          | f        | f           | f
 public     | t_ds_task_definition                   | root       |            | t          | f        | f           | f
 public     | t_ds_task_definition_log               | root       |            | t          | f        | f           | f
 public     | t_ds_task_group                        | root       |            | t          | f        | f           | f
 public     | t_ds_task_group_queue                  | root       |            | t          | f        | f           | f
 public     | t_ds_task_instance                     | root       |            | t          | f        | f           | f
 public     | t_ds_tenant                            | root       |            | t          | f        | f           | f
 public     | t_ds_udfs                              | root       |            | t          | f        | f           | f
 public     | t_ds_user                              | root       |            | t          | f        | f           | f
 public     | t_ds_version                           | root       |            | t          | f        | f           | f
 public     | t_ds_worker_group                      | root       |            | t          | f        | f           | f
(61 rows)

NAME: my
LAST DEPLOYED: Sun Jan 29 20:14:11 2023
NAMESPACE: dolphinsch
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

** Please be patient while the chart DolphinScheduler 3.1.3 is being deployed **

Access DolphinScheduler UI URL by:

  kubectl port-forward -n dolphinsch svc/my-api 12345:12345

  DolphinScheduler UI URL: http://127.0.0.1:12345/dolphinscheduler
EOF

kubectl exec -it -n dolphinsch `kubectl get pod -n dolphinsch | grep Running | grep worker-0 | awk '{print $1}'` -- bash