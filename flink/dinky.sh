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

DINKY_VERSION=0.7.2
PRJ_MYSQL_HOME=${PRJ_HOME}/mysql

SCALA_VERSION=2.12

#wget -c https://github.com/DataLinkDC/dinky/releases/download/v${DINKY_VERSION}/dlink-release-${DINKY_VERSION}.tar.gz
wget -c https://github.com/DataLinkDC/dinky/archive/refs/tags/v${DINKY_VERSION}.tar.gz
tar xzvf dinky-${DINKY_VERSION}.tar.gz
cd dinky-${DINKY_VERSION}
#安装node.js
#export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-11.0.17.jdk/Contents/Home
npm config set registry https://registry.npm.taobao.org
#mvn spotless:apply
mvn clean install -DskipTests=true -Dmaven.test.skip=true  -Dmaven.javadoc.skip=true -P aliyun,nexus,prod,scala-2.12,web,flink-1.15,flink-1.16 -Dspotless.check.skip=true

file=Dockerfile
cp ${file} ${file}.bk
$SED -i '/CMD  .\/auto.sh/i\COPY auto.sh /opt/dinky/auto.sh' ${file}
DOCKER_BUILDKIT=1 docker build ./ --progress=plain\
 --build-arg DINKY_VERSION="${DINKY_VERSION}"\
 -t harbor.my.org:1080/flink/dinky:${DINKY_VERSION}
docker push harbor.my.org:1080/flink/dinky:${DINKY_VERSION}

file=auto.sh
cp ${PRJ_FLINK_HOME}/auto-${DINKY_VERSION}.sh ${file}

#$SED -i '/restart() {/a\  cp /opt/dlink/config/application.yml.customize /opt/dlink/config/application.yml' ${file}
$SED -i 's/CLASS_PATH="/CLASS_PATH=".\/config\/*:/g' ${file}

file=${PRJ_FLINK_HOME}/DinkyFlinkDockerfile
cp ${file} ${file}.bk
$SED -i 's/ARG FLINK_VERSION=1.14.5/ARG FLINK_VERSION=1.15.4/g' ${file}
$SED -i "/ARG FLINK_VERSION=1.15.4/a\ARG TARGET_BUILT=${TARGET_BUILT}" ${file}
$SED -i 's/FROM flink/FROM harbor.my.org:1080\/flink\/flink-juicefs-\${TARGET_BUILT}/g' ${file}
$SED -i 's/1.16/1.15/g' ${file}
cp ${file} ./

cp ${PRJ_FLINK_HOME}/flink-shaded-hadoop-3-3.1.1.7.2.9.0-173-9.0.jar ./
file=DockerfileDinkyFlink
cp ${file} ${file}.bk
$SED -i '/FROM flink/i\ARG TARGET_BUILT=?' ${file}
$SED -i 's/FROM flink/FROM harbor.my.org:1080\/flink\/flink-juicefs-\${TARGET_BUILT}/g' ${file}
cat << \EOF > ${file}
COPY DinkyFlinkDockerfile /opt/dinky/config/
ARG SCALA_VERSION=?
ARG FLINK_VERSION=?
#COPY --from=reqired-stage  /opt/flink/opt/*.jar  /opt/dinky/plugins/flink${FLINK_BIG_VERSION}
COPY --from=reqired-stage  /opt/flink/opt/flink-table-planner_${SCALA_VERSION}-${FLINK_VERSION}.jar /opt/dinky/plugins/flink${FLINK_BIG_VERSION}
RUN rm -f /opt/dinky/plugins/flink${FLINK_BIG_VERSION}/flink-table-planner-loader-${FLINK_VERSION}.jar
RUN rm -f /opt/dinky/plugins/flink${FLINK_BIG_VERSION}/calcite-core-1.14.0.jar
COPY --from=reqired-stage /opt/flink/conf /opt/dinky/flinkconf
RUN mkdir /opt/flink
COPY --from=reqired-stage /opt/flink/hiveconf /opt/flink/hiveconf
COPY --from=reqired-stage /opt/flink/hadoopconf /opt/flink/hadoopconf
COPY --from=reqired-stage /opt/hadoop/share/hadoop/common/lib/* /opt/dinky/plugins/flink${FLINK_BIG_VERSION}/
COPY --from=reqired-stage /opt/hadoop/share/hadoop/common/* /opt/dinky/plugins/flink${FLINK_BIG_VERSION}/
COPY --from=reqired-stage /opt/hadoop/share/hadoop/hdfs/lib/* /opt/dinky/plugins/flink${FLINK_BIG_VERSION}/
COPY --from=reqired-stage /opt/hadoop/share/hadoop/hdfs/* /opt/dinky/plugins/flink${FLINK_BIG_VERSION}/
COPY --from=reqired-stage /opt/hadoop/share/hadoop/mapreduce/* /opt/dinky/plugins/flink${FLINK_BIG_VERSION}/
COPY --from=reqired-stage /opt/hadoop/share/hadoop/yarn/lib/* /opt/dinky/plugins/flink${FLINK_BIG_VERSION}/
COPY --from=reqired-stage /opt/hadoop/share/hadoop/yarn/* /opt/dinky/plugins/flink${FLINK_BIG_VERSION}/
EOF

DINKY_IMAGE=harbor.my.org:1080/flink/dinky:${DINKY_VERSION}
DOCKER_BUILDKIT=1 docker build ./ -f DockerfileDinkyFlink --progress=plain\
 --build-arg DINKY_IMAGE="${DINKY_IMAGE}"\
 --build-arg FLINK_BIG_VERSION="${FLINK_BIG_VERSION}"\
 --build-arg FLINK_VERSION="${FLINK_VERSION}"\
 --build-arg SCALA_VERSION="${SCALA_VERSION}"\
 --build-arg TARGET_BUILT="${TARGET_BUILT}"\
 -t harbor.my.org:1080/flink/dinky-flink:${DINKY_VERSION}_${FLINK_VERSION}
docker push harbor.my.org:1080/flink/dinky-flink:${DINKY_VERSION}_${FLINK_VERSION}


#docker
ansible all -m shell -a"docker images|grep dinky-flink"
ansible all -m shell -a"docker images|grep dinky-flink|awk '{print \$3}'|xargs docker rmi -f"
#containerd
ansible all -m shell -a"crictl images|grep dinky-flink"
ansible all -m shell -a"crictl images|grep dinky-flink|awk '{print \$3}'|xargs crictl rmi"

#CREATE初始化脚本改造，/**/的licence说明要删掉
#INSERT初始化脚本改造，;要替换成###SEP###
cd ${PRJ_FLINK_HOME}
mkdir init-database-dinky
file=init-database/execute.sql
cat << \EOF > ${file}
-- create database
CREATE DATABASE IF NOT EXISTS dlink DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
-- create user and grant authorization
GRANT ALL ON dlink.* TO 'dlink'@'%' IDENTIFIED BY '${USER_IDENTIFIER}';
USE dlink;

EOF
cat dinky-${DINKY_VERSION}/dlink-doc/sql/dinky.sql >> ${file}
$SED -i '/DROP TABLE IF EXISTS /d' ${file}
$SED -i 's/CREATE TABLE /CREATE TABLE IF NOT EXISTS /g' ${file}
#根据以下临时存储过程判断表里无数据再插入，手工修改所有INSERT语句段，前后加入相关存储过程代码
docker exec -it mysql-binlog2 mysql -h127.0.0.1 -uroot -p123456 -P3306
    DROP PROCEDURE IF EXISTS insert_record; 
    DELIMITER $$
    CREATE PROCEDURE insert_record() 
    BEGIN
    DECLARE num INT;
    select count(*) into num from `orders`;
    if num = 0
    then
    INSERT INTO orders VALUES (default, '2020-07-30 10:08:22', 'Jark', 50.50, 102, false);
    INSERT INTO orders VALUES (default, '2020-07-30 10:11:09', 'Sally', 15.00, 105, false);
    INSERT INTO orders VALUES (default, '2020-07-30 12:00:30', 'Edward', 25.25, 106, false);
    end if;
    
    END
    $$
    DELIMITER ;
    call insert_record();

#只有数字的可以，类似dlinkpw只有字符的k8s secret转换有问题，都用开头大写字母，中间有@，最后用数字结尾没问题
echo -n 'Dlink@1234' | base64
echo 'RGxpbmtAMTIzNA=='|base64 --decode

#启动1台工作节点的docker，设置远程访问
file=/usr/lib/systemd/system/docker.service 
cp ${file} ${file}.bk
sed -i "s@ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock@ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock -H tcp://0.0.0.0:2375@g" ${file}
systemctl daemon-reload 
systemctl restart docker
curl http://192.168.3.6:2375/version

kubectl create cm init-database-dinky -n flink --from-file=init-database-dinky
kubectl apply -f dinky-yaml/dlink-configmap.yaml -n flink
kubectl apply -f dinky-yaml/dlink-deployment.yaml -n flink
kubectl apply -f dinky-yaml/dlink-service.yaml -n flink

kubectl get all -n flink
watch kubectl get pod -n flink
kubectl get pod -n flink

kubectl get cm init-database-dinky -n flink -o yaml

kubectl describe pod -n flink `kubectl get pod -n flink |grep dlink |awk '{print $1}'`


kubectl logs -n flink `kubectl get pod -n flink |grep dlink |awk '{print $1}'` init-database

kubectl logs -n flink `kubectl get pod -n flink |grep dlink |awk '{print $1}'` dlink-flink
kubectl logs -n flink `kubectl get pod -n flink |grep dlink |grep Running |awk '{print $1}'` dlink-flink

kubectl port-forward -n flink svc/dlink 8888:8888 &
kubectl port-forward -n flink `kubectl get pod -n flink |grep dlink |grep Running |awk '{print $1}'` 8888:8888 &

#卸载
kubectl delete -f dinky-yaml/dlink-deployment.yaml -n flink
kubectl delete -f dinky-yaml/dlink-service.yaml -n flink
kubectl delete -f dinky-yaml/dlink-configmap.yaml -n flink
kubectl delete cm init-database-dinky -n flink

kubectl get pod -n flink |grep dlink |grep -v Running |awk '{print $1}'| xargs kubectl delete pod "$1" -n flink --force --grace-period=0

kubectl exec -it -n flink `kubectl get pod -n flink |grep dlink | grep Running | awk '{print $1}'` -c dlink-flink -- bash
kubectl exec -it -n flink `kubectl get pod -n flink |grep dlink | grep Running | awk '{print $1}'` -c dlink-flink -- cat logs/dlink.log  
kubectl exec -it -n flink `kubectl get pod -n flink |grep dlink | grep Running | awk '{print $1}'` -c dlink-flink -- tail -f logs/dlink.log  

kubectl exec -it -n flink `kubectl get pod -n flink |grep dlink | grep Running | awk '{print $1}'` -c dlink-flink -- cat config/DinkyFlinkDockerfile
kubectl exec -it -n flink `kubectl get pod -n flink |grep dlink | grep Running | awk '{print $1}'` -c dlink-flink -- cat auto.sh

kubectl exec -it -n mysql `kubectl get pod -n mysql | grep Running | awk '{print $1}'` -- mysql -h127.0.0.1 -udlink -pDlink@1234 -e"SHOW DATABASES"
kubectl exec -it -n mysql `kubectl get pod -n mysql | grep Running | awk '{print $1}'` -- mysql -h127.0.0.1 -udlink -pdlinkpw -e"SELECT * FROM dlink_flink_document"


