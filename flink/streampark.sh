if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Mac detected."
    #mac
    MYHOME=/Volumes/data
    SED=gsed
else
    echo "Assuming linux by default."
    #linux
    MYHOME=~
    SED=sed
fi

WORK_HOME=${MYHOME}/workspace
PRJ_HOME=${WORK_HOME}/dockerfile

PRJ_FLINK_HOME=${PRJ_HOME}/flink

FLINK_VERSION=1.15.4
FLINK_SHORT_VERSION=1.15

FLINK_BIG_VERSION=1.15

#TARGET_BUILT=hadoop2hive2
TARGET_BUILT=hadoop3hive3

:<<EOF
FLINK_VERSION=1.17.0
FLINK_SHORT_VERSION=1.17

FLINK_VERSION=1.16.1
FLINK_SHORT_VERSION=1.16

FLINK_VERSION=1.15.4
FLINK_SHORT_VERSION=1.15
EOF

STREAMPARK_VERSION=2.0.0
PRJ_MYSQL_HOME=${PRJ_HOME}/mysql

SCALA_VERSION=2.12

maven_version=3.8.6

maven_home=${MYHOME}/apache-maven-${maven_version}
m2_home=${MYHOME}/m2

K8S_VERSION=1.21.14

JUICEFS_VERSION=1.0.3

wget -c https://www.apache.org/dyn/closer.lua/incubator/streampark/${STREAMPARK_VERSION}/apache-streampark-${STREAMPARK_VERSION}-incubating-src.tar.gz
wget -c https://www.apache.org/dyn/closer.lua/incubator/streampark/${STREAMPARK_VERSION}/apache-streampark_${SCALA_VERSION}-${STREAMPARK_VERSION}-incubating-bin.tar.gz
tar xzvf apache-streampark-${STREAMPARK_VERSION}-incubating-src.tar.gz
tar xzvf apache-streampark_${SCALA_VERSION}-${STREAMPARK_VERSION}-incubating-bin.tar.gz

cp apache-streampark-${STREAMPARK_VERSION}-incubating-src/deploy/docker/Dockerfile Dockerfile-streampark-${STREAMPARK_VERSION}
#修改定制Dockerfile，以flink image为基础，copy二进制包，copy maven/.m2 到镜像中
cd ${PRJ_FLINK_HOME}/apache-streampark-${STREAMPARK_VERSION}-incubating-src/deploy/docker/
cp Dockerfile Dockerfile.bk
cp ${PRJ_FLINK_HOME}/Dockerfile-streampark-${STREAMPARK_VERSION} Dockerfile
cp -r ${maven_home} maven
mkdir m2
cp -r ${m2_home}/settings.xml m2/
mv ${PRJ_FLINK_HOME}/apache-streampark_${SCALA_VERSION}-${STREAMPARK_VERSION}-incubating-bin streampark

DOCKER_BUILDKIT=1 docker build ./ --progress=plain\
 --build-arg FLINK_VERSION="${FLINK_VERSION}"\
 --build-arg TARGET_BUILT="${TARGET_BUILT}"\
 --build-arg K8S_VERSION="${K8S_VERSION}"\
 --build-arg JUICEFS_VERSION="${JUICEFS_VERSION}"\
 -t harbor.my.org:1080/flink/streampark:${STREAMPARK_VERSION}
docker push harbor.my.org:1080/flink/streampark:${STREAMPARK_VERSION}


#docker
ansible all -m shell -a"docker images|grep streampark"
ansible all -m shell -a"docker images|grep streampark|awk '{print \$3}'|xargs docker rmi -f"
#containerd
ansible all -m shell -a"crictl images|grep streampark"
ansible all -m shell -a"crictl images|grep streampark|awk '{print \$3}'|xargs crictl rmi"


cd ${PRJ_FLINK_HOME}
mkdir init-database-streampark
file=init-database-streampark/execute01.sql
cat << \EOF > ${file}
-- create database
CREATE DATABASE IF NOT EXISTS streamx DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
-- create user and grant authorization
GRANT ALL ON streamx.* TO 'streamx'@'%' IDENTIFIED BY '${USER_IDENTIFIER}';
USE streamx;
EOF

cd ${PRJ_FLINK_HOME}/apache-streampark-${STREAMPARK_VERSION}-incubating-src/deploy/helm/streampark/
mkdir conf/init-database
cp ${PRJ_FLINK_HOME}/init-database-streampark/execute01.sql conf/init-database/
#类似conf/streampark-console-config，configmap.yaml，streamParkDefaultConfiguration，增加初始化sql对应的configmap
cp values.yaml values.yaml.bk
cat << \EOF > templates/configma-init-database.yaml
{{- if .Values.streamParkInitDatabase.create }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: init-database
  namespace: {{ .Release.Namespace }}
  labels:
  {{- include "streampark.labels" . | nindent 4 }}
data:
  execute.sql: |+
{{- if .Values.streamParkInitDatabase.append }}
    {{- $.Files.Get "conf/init-database/execute.sql"  | nindent 4 -}}
{{- end }}
{{- if index (.Values.streamParkInitDatabase) "execute.sql" }}
    {{- index (.Values.streamParkInitDatabase) "execute.sql" | nindent 4 -}}
{{- end }}
{{- end }}
EOF
#只有数字的可以，类似dlinkpw只有字符的k8s secret转换有问题，都用开头大写字母，中间有@，最后用数字结尾没问题
echo -n 'Streamx@1234' | base64
echo 'U3RyZWFteEAxMjM0'|base64 --decode
cat << \EOF > templates/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: streampark-secret
  labels:
    app: streamx
type: Opaque
data:
  database-dba-password: MTIzNDU2
  database-user-password: U3RyZWFteEAxMjM0
EOF
cp templates/configmap.yaml configmap.yaml.bk
#删除configmap里h2 postgresql，只保留mysql
#修改application.yml里的缺省数据库配置：
cp conf/streampark-console-config/application.yml application.yml.bk
:<<EOF
  profiles.active: h2 #[h2,pgsql,mysql]
  --->
  profiles.active: mysql #[h2,pgsql,mysql]
EOF
cp templates/streampark.yml streampark.yml.bk
#CREATE初始化脚本改造，/**/的licence说明要删掉
cp ${PRJ_FLINK_HOME}/apache-streampark-${STREAMPARK_VERSION}-incubating-src/streampark-console/streampark-console-service/src/main/assembly/script/schema/mysql-schema.sql ${PRJ_FLINK_HOME}/init-database-streampark/execute02.sql
$SED -i 's/streampark/streamx/g' ${PRJ_FLINK_HOME}/init-database-streampark/execute02.sql
cp ${PRJ_FLINK_HOME}/init-database-streampark/execute02.sql conf/init-database/
#INSERT初始化脚本改造，;要替换成###SEP###
cp ${PRJ_FLINK_HOME}/apache-streampark-${STREAMPARK_VERSION}-incubating-src/streampark-console/streampark-console-service/src/main/assembly/script/data/mysql-data.sql ${PRJ_FLINK_HOME}/init-database-streampark/procedure.sql
cp ${PRJ_FLINK_HOME}/init-database-streampark/procedure.sql conf/init-database/
#增加init-database的initcontainer
:<<EOF
      initContainers:
        - name: init-database
          image:  harbor.my.org:1080/bronzels/database-tools:1.0
          env:
            - name: DRIVER_NAME
              value: "com.mysql.jdbc.Driver"
            - name: URL
              value: "jdbc:mysql://mysql-svc.mysql:3306/mysql?useUnicode=true&characterEncoding=utf8&useSSL=false"
            - name: USERNAME
              value: "root"
            - name: PASSWORD
              valueFrom:
                secretKeyRef:
                  name: streampark-secret
                  key: database-dba-password
            - name: USER_IDENTIFIER
              valueFrom:
                secretKeyRef:
                  name: streampark-secret
                  key: database-user-password
          volumeMounts:
            - name: init-database-volume
              mountPath: /root/db_tools/script

删除
              - key: application-h2.yml
                path: application-h2.yml
              - key: application-pgsql.yml
                path: application-pgsql.yml


...
        - configMap:
            name: init-database
          name: init-database-volume                    
EOF
#把/var/run/docker.sock修改为/run/containerd/containerd.sock
mv conf/streampark-console-config/application-h2.yml ./
mv conf/streampark-console-config/application-mysql.yml ./
mv conf/streampark-console-config/application-pgsql.yml ./
cat << \EOF > conf/streampark-console-config/application-mysql.yml
spring:
  datasource:
    username: ${MYSQL_USERNAME:streampark}
    password: ${MYSQL_PASSWORD:streampark}
    driver-class-name: com.mysql.cj.jdbc.Driver
    url: jdbc:mysql://${MYSQL_ADDR:127.0.0.1:3306}/${MYSQL_DATABASE:streampark}?useSSL=false&useUnicode=true&characterEncoding=UTF-8&allowPublicKeyRetrieval=false&useJDBCCompliantTimezoneShift=true&useLegacyDatetimeCode=false&serverTimezone=GMT%2B8
EOF
#给指定节点安装了docker
:<<EOF
values.yaml
  nodeSelector: 
    kubernetes.io/hostname: 'mdlapubu'
EOF
#安装
#declare -A myMap=(["hostname"]="mdlapubu")
#  --set spec.nodeSelector=myMap \

kubectl create clusterrolebinding endpoints-reader-default-flink-streampark \
  --clusterrole=endpoints-reader-flink  \
  --serviceaccount=flink:streampark

#  --set streamParkServiceAccount.name=default \
#不能指定已经存在的sa
helm install streamx -n flink -f values.yaml \
  --set image.repository=harbor.my.org:1080/flink/streampark \
  --set image.tag=${STREAMPARK_VERSION} \
  ./
:<<EOF
NAME: streamx
LAST DEPLOYED: Sun Apr  2 11:28:35 2023
NAMESPACE: flink
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

** Please be patient while the chart StreamPark 2.0.0 is being deployed **

Access StreamPark UI URL by:

ChartVersion:2.0.0[refers to the release version]
appVersion:2.0.0[refers to the code version]

You can try the following command to get the ip, port of StreamPark:
kubectl get no -n flink -o jsonpath="{.items[0].status.addresses[0].address}"
kubectl get svc streampark-service -n flink -o jsonpath="{.spec.ports[0].nodePort}"
EOF

#登录admin/streampark

#卸载
helm uninstall streamx -n flink
kubectl get pod -n flink |grep streampark |grep -v Running |awk '{print $1}'| xargs kubectl delete pod "$1" -n flink --force --grace-period=0

kubectl get all -n flink
watch kubectl get pod -n flink
kubectl get pod -n flink

kubectl describe pod -n flink `kubectl get pod -n flink |grep streamx |awk '{print $1}'`


kubectl logs -n flink `kubectl get pod -n flink |grep streampark |awk '{print $1}'` init-database
kubectl logs -f -n flink `kubectl get pod -n flink |grep streampark |awk '{print $1}'` init-database
kubectl logs -n flink `kubectl get pod -n flink |grep streampark |awk '{print $1}'` streampark
kubectl logs -f -n flink `kubectl get pod -n flink |grep streampark |awk '{print $1}'` streampark

kubectl logs -n flink `kubectl get pod -n flink |grep streampark |awk '{print $1}'` dlink-flink
kubectl logs -n flink `kubectl get pod -n flink |grep streampark |grep Running |awk '{print $1}'` dlink-flink

kubectl port-forward -n flink svc/streampark-service 10000:10000 &
kubectl port-forward -n flink `kubectl get pod -n flink |grep streampark |grep Running |awk '{print $1}'` 8888:8888 &


kubectl exec -it -n flink `kubectl get pod -n flink |grep streampark | grep Running | awk '{print $1}'` -c streampark -- bash

kubectl exec -it -n mysql `kubectl get pod -n mysql | grep Running | awk '{print $1}'` -- mysql -h127.0.0.1 -ustreamx -pStreamx@1234 -e"SHOW DATABASES"
kubectl exec -it -n mysql `kubectl get pod -n mysql | grep Running | awk '{print $1}'` -- mysql -h127.0.0.1 -ustreamx -pStreamx@1234 -e"USE streamx;SHOW TABLES"
kubectl exec -it -n mysql `kubectl get pod -n mysql | grep Running | awk '{print $1}'` -- mysql -h127.0.0.1 -ustreamx -pStreamx@1234 -e"USE streamx;SELECT * FROM t_menu"

mv ${PRJ_FLINK_HOME}/apache-streampark-${STREAMPARK_VERSION}-incubating-src/deploy/docker/streampark ${PRJ_FLINK_HOME}/apache-streampark_${SCALA_VERSION}-${STREAMPARK_VERSION}-incubating-bin

