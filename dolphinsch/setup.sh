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

cd dolphinscheduler-worker/src/main/docker
tar xzvf ${MYDOLPHINSCH_HOME}/apache-dolphinscheduler-${DOLPHINSCH_REV}-src/dolphinscheduler-dist/target/apache-dolphinscheduler-${DOLPHINSCH_REV}-bin.tar.gz
file=Dockerfile
cp ${file} ${file}.bk
$SED -i '/FROM eclipse-temurin:8-jre/a\USER root' ${file}
$SED -i 's/FROM eclipse-temurin:8-jre/FROM harbor.my.org:1080\/bronzels\/spark-juicefs-volcano-rss:3.3.1/g' ${file}
$SED -i 's/CMD/ENTRYPOINT/g' ${file}
$SED -i 's@ADD ./target/worker-server@ADD apache-dolphinscheduler-${DOLPHINSCH_REV}-bin/worker-server@g' ${file}
$SED -i '/ENV DOCKER true/i\ARG DOLPHINSCH_REV=' ${file}
docker build ./ --progress=plain --build-arg DOLPHINSCH_REV="${DOLPHINSCH_REV}" --build-arg SPARK_VERSION="${SPARK_VERSION}" -t harbor.my.org:1080/dolphinsch/dolphinscheduler-worker-spark-${SPARK_VERSION}:${DOLPHINSCH_REV}
docker push harbor.my.org:1080/dolphinsch/dolphinscheduler-worker-spark-${SPARK_VERSION}:${DOLPHINSCH_REV}

#docker
ansible all -m shell -a"docker images|grep dolphinscheduler-worker-spark"
ansible all -m shell -a"docker images|grep dolphinscheduler-worker-spark|awk '{print \$3}'|xargs docker rmi -f"
#containerd
ansible all -m shell -a"crictl images|grep dolphinscheduler-worker-spark"
ansible all -m shell -a"crictl images|grep dolphinscheduler-worker-spark|awk '{print \$3}'|xargs crictl rmi"

arr=(master api alert tools)
#arr=(alert tools)
for prj in ${arr[*]}
do
  cd ${MYDOLPHINSCH_HOME}/apache-dolphinscheduler-${DOLPHINSCH_REV}-src
  if [[ "${prj}" =~ "alert" ]]; then
    cd dolphinscheduler-${prj}/dolphinscheduler-${prj}-server/src/main/docker
  else
    cd dolphinscheduler-${prj}/src/main/docker
  fi
  file=Dockerfile
  cp ${file} ${file}.bk
  tar xzf ${MYDOLPHINSCH_HOME}/apache-dolphinscheduler-${DOLPHINSCH_REV}-src/dolphinscheduler-dist/target/apache-dolphinscheduler-${DOLPHINSCH_REV}-bin.tar.gz
  if [[ "${prj}" =~ "tools" ]]; then
    $SED -i "s@ADD ./target/tools@ADD apache-dolphinscheduler-\${DOLPHINSCH_REV}-bin/tools@g" ${file}
  else
    $SED -i "s@ADD ./target/${prj}-server@ADD apache-dolphinscheduler-\${DOLPHINSCH_REV}-bin/${prj}-server@g" ${file}
  fi
  $SED -i '/ENV DOCKER true/i\ARG DOLPHINSCH_REV=' ${file}
  ls && cat Dockerfile
  docker build ./ --progress=plain --build-arg DOLPHINSCH_REV="${DOLPHINSCH_REV}" -t harbor.my.org:1080/dolphinsch/dolphinscheduler-${prj}:${DOLPHINSCH_REV}
  docker push harbor.my.org:1080/dolphinsch/dolphinscheduler-${prj}:${DOLPHINSCH_REV}
done


cd ${MYDOLPHINSCH_HOME}/apache-dolphinscheduler-${DOLPHINSCH_REV}-src
cd deploy/kubernetes/dolphinscheduler
cp -rf templates templates.bk
$SED -i 's/          image: {{ include "dolphinscheduler.image.fullname.worker" . }}/          image: {{ .Values.image.worker }}:{{ .Values.image.tag }}/g' templates/statefulset-dolphinscheduler-worker.yaml
$SED -i 's/          image: {{ include "dolphinscheduler.image.fullname.master" . }}/          image: {{ .Values.image.master }}:{{ .Values.image.tag }}/g' templates/statefulset-dolphinscheduler-master.yaml
$SED -i 's/          image: {{ include "dolphinscheduler.image.fullname.api" . }}/          image: {{ .Values.image.api }}:{{ .Values.image.tag }}/g' templates/deployment-dolphinscheduler-api.yaml
$SED -i 's/          image: {{ include "dolphinscheduler.image.fullname.alert" . }}/          image: {{ .Values.image.alert }}:{{ .Values.image.tag }}/g' templates/deployment-dolphinscheduler-alert.yaml
$SED -i 's/          image: {{ include "dolphinscheduler.image.fullname.tools" . }}/          image: {{ .Values.image.tools }}:{{ .Values.image.tag }}/g' templates/job-dolphinscheduler-schema-initializer.yaml
helm repo add bitnami https://charts.bitnami.com/bitnami
helm dependency update .
kubectl create ns dolphinsch
helm search repo dolphinscheduler

:<<EOF
helm install my bitnami/dolphinscheduler \
  --set image.worker=harbor.my.org:1080/dolphinsch/dolphinscheduler-worker-spark-${SPARK_VERSION} \
  --set image.tag=${DOLPHINSCH_REV} \
  --set common.configmap.SPARK_HOME1=/app/hdfs/spark \
  --version ${DOLPHINSCH_REV} \
  -n dolphinsch
EOF

#把mysql从Chart.yaml里删除
helm dependency build
#缺省安装报错：FATAL:  remaining connection slots are reserved for non-replication superuser connections
#据说缺省maxconnection 100，reserved 3，不知道为什么启动就没有了
cd charts
mv postgresql-10.3.18.tgz postgresql-10.3.18-bk.tgz
tar xzvf postgresql-10.3.18.tgz
file=postgresql/values.yaml
cp ${file} ${file}.bk
$SED -i 's/postgresqlMaxConnections:/postgresqlMaxConnections: 200/g' ${file}
tar czvf postgresql-10.3.18.tgz postgresql/

arr=(master api alert tools)
helm install my -n dolphinsch -f values.yaml \
  --set conf.common.resource.hdfs.root.user=hdfs \
  --set conf.common.resource.hdfs.fs.defaultFS=jfs://miniofs \
  --set image.worker=harbor.my.org:1080/dolphinsch/dolphinscheduler-worker-spark-${SPARK_VERSION} \
  --set image.master=harbor.my.org:1080/dolphinsch/dolphinscheduler-master \
  --set image.api=harbor.my.org:1080/dolphinsch/dolphinscheduler-api \
  --set image.alert=harbor.my.org:1080/dolphinsch/dolphinscheduler-alert \
  --set image.tools=harbor.my.org:1080/dolphinsch/dolphinscheduler-tools \
  --set image.tag=${DOLPHINSCH_REV} \
  --set common.configmap.SPARK_HOME1=/app/hdfs/spark \
  ./
helm uninstall my -n dolphinsch
kubectl get pod -n dolphinsch |grep Terminating |awk '{print $1}'| xargs kubectl delete pod "$1" -n dolphinsch --force --grace-period=0
watch kubectl get all -n dolphinsch
kubectl port-forward -n dolphinsch svc/my-api 12345:12345 &

kubectl run mdpostgre-postgresql-client -n dolphinsch --rm --tty -i --restart='Never' --image docker.io/bitnami/postgresql:11.11.0-debian-10-r71 --env="PGPASSWORD=root" --command -- \
  psql --host my-postgresql -U root -d dolphinscheduler -p 5432 \
  -c "SELECT version()"

#默认的用户名和密码是 admin/dolphinscheduler123
:<<EOF
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
kubectl run mdpostgre-postgresql-client -n dolphinsch --rm --tty -i --restart='Never' --image docker.io/bitnami/postgresql:11.11.0-debian-10-r71 --env="PGPASSWORD=root" --command -- \
  psql --host my-postgresql -U root -d dolphinscheduler -p 5432 \
  -c "select * from t_ds_worker_group order by update_time desc"
 id | name | addr_list | create_time | update_time | description | other_params_
json
----+------+-----------+-------------+-------------+-------------+--------------
-----
(0 rows)

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
