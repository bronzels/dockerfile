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

WORK_HOME=${MYHOME}/workspace
PRJ_HOME=${WORK_HOME}/dockerfile
SPARK_HOME=${PRJ_HOME}/spark

SPARK_VERSION=3.3.1

#KYUUBI_VERSION=1.6.1-incubating
KYUUBI_VERSION=1.7.0
KYUUBI_HOME=${SPARK_HOME}/apache-kyuubi-${KYUUBI_VERSION}-bin

BASE_IMAGE=harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss:${SPARK_VERSION}


cd ${SPARK_HOME}

#wget -c https://archive.apache.org/dist/incubator/kyuubi/kyuubi-1.6.1-incubating/apache-kyuubi-1.6.1-incubating-bin.tgz
wget -c https://dlcdn.apache.org/kyuubi/kyuubi-1.7.0/apache-kyuubi-1.7.0-bin.tgz


tar xzvf apache-kyuubi-${KYUUBI_VERSION}-bin.tgz
cd ${KYUUBI_HOME}
cp ${SPARK_HOME}/spark-defaults.conf ./
$SED -i '/spark.kubernetes.scheduler.name volcano/,+2d' spark-defaults.conf
$SED -i '/spark.kubernetes.driver.volumes.persistentVolumeClaim.juicefsvol.mount.path/,+5d' spark-defaults.conf

file=docker/Dockerfile
cp ${file} ${file}.bk
#$SED -i 's/spark-binary/\/app\/hdfs\/spark/g' ${file}
#$SED -i '/    rm -rf \/var\/cache\/apt/i\    mkdir ${KYUUBI_WORK_DIR_ROOT}/kyuubi && chmod a+rwx -R ${KYUUBI_WORK_DIR_ROOT}/kyuubi && \\' ${file}
#$SED -i '/    rm -rf \/var\/cache\/apt/i\    mkdir ${KYUUBI_WORK_DIR_ROOT}/hdfs && chown hdfs:hdfs -R ${KYUUBI_WORK_DIR_ROOT}/hdfs && chmod a+rwx -R ${KYUUBI_WORK_DIR_ROOT}/hdfs && \\' ${file}

$SED -i "/USER \${kyuubi_uid}/i\COPY --chown=hdfs:root spark-defaults.conf \${SPARK_HOME}/conf/spark-defaults.conf" ${file}
#built-in
:<<EOF
$SED -i 's/spark-binary/spark/g' ${file}
$SED -i '/COPY LICENSE NOTICE RELEASE/i\RUN chown -R kyuubi:root ${SPARK_HOME}' ${file}

kubectl cp -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep spark-test | awk '{print $1}'`:/app/hdfs/spark park
chmod a+x spark/bin/*
chmod a+x spark/sbin/*
file=spark/conf/core-site.xml
EOF
#built-in
$SED -i "s@</configuration>@@g" ${file}
cat << EOF >> ${file}
    <property>
        <name>hadoop.proxyuser.kyuubi.hosts</name>
        <value>*</value>
    </property>
    <property>
        <name>hadoop.proxyuser.kyuubi.users</name>
        <value>*</value>
    </property>
    <property>
        <name>hadoop.proxyuser.kyuubi.groups</name>
        <value>*</value>
    </property>
</configuration>
EOF

DOCKER_BUILDKIT=1 docker build ./ -f docker/Dockerfile --progress=plain --build-arg spark_provided="spark_provided" --build-arg spark_home_in_docker="/app/hdfs/spark" --build-arg BASE_IMAGE="${BASE_IMAGE}" -t harbor.my.org:1080/sqlengine/kyuubi-juicefs-volcano-rss:${KYUUBI_VERSION}
#built-in
#DOCKER_BUILDKIT=1 docker build ./ -f docker/Dockerfile --progress=plain -t harbor.my.org:1080/sqlengine/kyuubi-juicefs-volcano-rss:${KYUUBI_VERSION}
docker push harbor.my.org:1080/sqlengine/kyuubi-juicefs-volcano-rss:${KYUUBI_VERSION}

#docker
ansible all -m shell -a"docker images|grep kyuubi"
ansible all -m shell -a"docker images|grep kyuubi|awk '{print \$3}'|xargs docker rmi -f"
#containerd
ansible all -m shell -a"crictl images|grep kyuubi"
ansible all -m shell -a"crictl images|grep kyuubi|awk '{print \$3}'|xargs crictl rmi"

kubectl create ns sqlengine

#cd ${KYUUBI_HOME}/docker/helm
cd ${KYUUBI_HOME}/charts/kyuubi
file=kyuubi-configmap.yaml
cp templates/${file} ${file}.bk
$SED -i "s@    kyuubi.frontend.bind.host=localhost@    kyuubi.frontend.bind.host=0.0.0.0@g" templates/${file}
$SED -i "/    kyuubi.frontend.protocols/a\    spark.kubernetes.container.image=harbor.my.org:1080\/bronzels\/spark-juicefs-volcano-rss:3.3.1\n    spark.kubernetes.scheduler.volcano.podGroupTemplateFile=\/app\/hdfs\/spark\/work-dir\/podgroups\/volcano-halfavailable-podgroup.yaml\n    spark.kubernetes.scheduler.name=volcano\n    spark.kubernetes.driver.pod.featureSteps=org.apache.spark.deploy.k8s.features.VolcanoFeatureStep\n    spark.kubernetes.executor.pod.featureSteps=org.apache.spark.deploy.k8s.features.VolcanoFeatureStep\n    spark.submit.deployMode=cluster\n    kyuubi.ha.zookeeper.quorum=zk-zookeeper\n    kyuubi.engine.share.level=CONNECTION" templates/${file}

file=values.yaml
cp ${file} ${file}.bk
$SED -i '/    - apiGroups: \[""\]/,+3d' ${file}
$SED -i "/  rules:/a\  - apiGroups: [\"\"]\n    resources: [\"endpoints\"]\n    verbs: [\"get\", \"watch\", \"list\"]\n  - apiGroups: [\"\"]\n    resources: [\"pods\"]\n    verbs: [\"create\", \"delete\", \"update\", \"get\", \"watch\", \"list\"]\n  - apiGroups: [\"\"]\n    resources: [\"configmaps\"]\n    verbs: [\"create\", \"delete\", \"update\", \"get\", \"watch\", \"list\"]\n  - apiGroups: [\"\"]\n    resources: [\"services\"]\n    verbs: [\"create\", \"delete\", \"update\", \"get\", \"watch\", \"list\"]\n  - apiGroups: [\"\"]\n    resources: [\"persistentvolumeclaims\"]\n    verbs: [\"create\", \"delete\", \"update\", \"get\", \"watch\", \"list\"]\n  - apiGroups: [\"scheduling.volcano.sh\"]\n    resources: [\"podgroups\"]\n    verbs: [\"create\", \"delete\", \"update\", \"get\", \"watch\", \"list\"]\n" ${file}
#后来确认只能在spark-defaults里定义，这里定义了没用
#$SED -i "s/volumes: \[\]/volumes:\n  - name: juicefsvol\n    persistentVolumeClaim:\n      claimName: rss-juicefs-pvc/g" ${file}
#$SED -i "s/volumeMounts: \[\]/volumeMounts:\n  - mountPath: \/tmp\/sparklogs\n    name: juicefsvol/g" ${file}
#加到这里转换到kyuubi-defaults.conf里没有回车，只好直接修改configmap里的kyuubi-defaults.conf部分
#$SED -i "s/  kyuubiDefaults: ~/  kyuubiDefaults:\n    spark.kubernetes.container.image=harbor.my.org:1080\/bronzels\/spark-juicefs-volcano-rss:3.3.1\n    spark.kubernetes.scheduler.volcano.podGroupTemplateFile=\/app\/hdfs\/spark\/work-dir\/podgroups\/volcano-halfavailable-podgroup.yaml\n    spark.kubernetes.scheduler.name=volcano\n    spark.kubernetes.driver.pod.featureSteps=org.apache.spark.deploy.k8s.features.VolcanoFeatureStep\n    spark.kubernetes.executor.pod.featureSteps=org.apache.spark.deploy.k8s.features.VolcanoFeatureStep/g" ${file}

helm install zk bitnami/zookeeper -n spark-operator \
  --set image.registry=registry.cn-hangzhou.aliyuncs.com \
  --set image.repository=bronzels/bitnami-zookeeper-3.8.1-debian-11-r0 \
  --set image.tag=1.0 \
  --set replicaCount=1 \
  --set auth.enabled=false \
  --set allowAnonymousLogin=true \
  --set persistence.storageClass=nfs-client
helm uninstall zk -n spark-operator
kubectl get pod -n spark-operator |grep -v Running | grep zk | awk '{print $1}'| xargs kubectl delete pod "$1" -n spark-operator --force --grace-period=0
:<<EOF
NAME: zk
LAST DEPLOYED: Thu Mar  9 18:48:03 2023
NAMESPACE: spark-operator
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: zookeeper
CHART VERSION: 11.1.2
APP VERSION: 3.8.1

** Please be patient while the chart is being deployed **

ZooKeeper can be accessed via port 2181 on the following DNS name from within your cluster:

    zk-zookeeper.spark-operator.svc.cluster.local

To connect to your ZooKeeper server run the following commands:

    export POD_NAME=$(kubectl get pods --namespace spark-operator -l "app.kubernetes.io/name=zookeeper,app.kubernetes.io/instance=zk,app.kubernetes.io/component=zookeeper" -o jsonpath="{.items[0].metadata.name}")
    kubectl exec -it $POD_NAME -- zkCli.sh

To connect to your ZooKeeper server from outside the cluster execute the following commands:

    kubectl port-forward --namespace spark-operator svc/zk-zookeeper 2181:2181 &
    zkCli.sh 127.0.0.1:2181
EOF

helm install kyuubisrv -n spark-operator -f values.yaml \
  --set image.repository=harbor.my.org:1080/sqlengine/kyuubi-juicefs-volcano-rss \
  --set image.tag=${KYUUBI_VERSION} \
  --set replicaCount=1 \
  ./
:<<EOF
NAME: my
LAST DEPLOYED: Thu Mar  9 12:19:14 2023
NAMESPACE: sqlengine
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The chart has been installed!

In order to check the release status, use:
  helm status my -n spark-operator
    or for more detailed info
  helm get all my -n spark-operator

************************
******* Services *******
************************
THRIFT_BINARY:
- To access my-thrift-binary service within the cluster, use the following URL:
    my-thrift-binary.sqlengine.svc.cluster.local
- To access my-thrift-binary service from outside the cluster for debugging, run the following command:
    kubectl port-forward svc/my-thrift-binary 10009:10009 -n spark-operator
  and use 127.0.0.1:10009
EOF

watch kubectl get all -n spark-operator
kubectl get all -n spark-operator

helm uninstall kyuubisrv -n spark-operator
kubectl get pod -n spark-operator |grep -v Running | grep kyuubisrv | awk '{print $1}'| xargs kubectl delete pod "$1" -n spark-operator --force --grace-period=0

kubectl get pod -n spark-operator |grep -v Running | grep kyuubi | awk '{print $1}'| xargs kubectl delete pod "$1" -n spark-operator --force --grace-period=0

kubectl logs -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep kyuubisrv | awk '{print $1}'`
kubectl logs -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep kyuubi-connection-spark-sql | awk '{print $1}'`
kubectl exec -it -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep kyuubisrv | awk '{print $1}'` -- tail -f /opt/kyuubi/work/hdfs/kyuubi-spark-sql-engine.log.0
kubectl exec -it -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep kyuubisrv | awk '{print $1}'` -- cat /opt/kyuubi/work/hdfs/kyuubi-spark-sql-engine.log.0


:<<EOF
NAME: my
LAST DEPLOYED: Mon Feb 27 08:18:12 2023
NAMESPACE: kyuubi
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
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

Get kyuubi expose URL by running these commands:
  export NODE_PORT=$(kubectl get --namespace kyuubi -o jsonpath="{.spec.ports[0].nodePort}" services my-kyuubi-nodeport)
  export NODE_IP=$(kubectl get nodes --namespace kyuubi -o jsonpath="{.items[0].status.addresses[0].address}")
  echo $NODE_IP:$NODE_PORT
EOF

kubectl exec -it -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep kyuubisrv | awk '{print $1}'` -- bash
kubectl exec -it -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep kyuubisrv | awk '{print $1}'` -- cat conf/kyuubi-defaults.conf

kubectl get pod -n spark-operator |grep Running | grep kyuubi-connection-spark-sql | awk '{print $1}'| xargs kubectl delete pod "$1" -n spark-operator --force --grace-period=0
kubectl get pod -n spark-operator |grep Running | grep exec | awk '{print $1}'| xargs kubectl delete pod "$1" -n spark-operator --force --grace-period=0
kubectl get pod -n spark-operator |grep -v Running | grep kyuubi-connection-spark-sql | awk '{print $1}'| xargs kubectl delete pod "$1" -n spark-operator --force --grace-period=0

:<<EOF
不设置kyuubi.engine.share.level=CONNECTION，缺省在USER模式，一个-n USER会复用1个driver Pod一直在Running状态
设置了CONNECTION level后，driver从Running到Completed状态，executor pod会Terminated被删除

如果不把kyuubi提交任务模式explicitly设置为cluster，会默认用client方式运行，会遇到和spark集成volcano测试时client模式一样的错误
    spark.submit.deployMode=cluster
23/03/09 06:55:17 WARN ExecutorPodsSnapshotsStoreImpl: Exception when notifying snapshot subscriber.
io.fabric8.kubernetes.client.KubernetesClientException: Failure executing: POST at: https://kubernetes.default.svc.cluster.local/api/v1/namespaces/spark-operator/pods. Message: admission webhook "validatepod.volcano.sh" denied the request: failed to get PodGroup for pod <spark-operator/kyuubi-a3fcecd5-cbba-40b6-a5d3-bdfce7bfa87f-exec-4>: podgroups.scheduling.volcano.sh "spark-cf4135d392c14122add6a8f10fa1511e-podgroup" not found. Received status: Status(apiVersion=v1, code=400, details=null, kind=Status, message=admission webhook "validatepod.volcano.sh" denied the request: failed to get PodGroup for pod <spark-operator/kyuubi-a3fcecd5-cbba-40b6-a5d3-bdfce7bfa87f-exec-4>: podgroups.scheduling.volcano.sh "spark-cf4135d392c14122add6a8f10fa1511e-podgroup" not found, metadata=ListMeta(_continue=null, remainingItemCount=null, resourceVersion=null, selfLink=null, additionalProperties={}), reason=null, status=Failure, additionalProperties={}).
23/01/30 10:12:51 WARN ExecutorPodsSnapshotsStoreImpl: Exception when notifying snapshot subscriber.
io.fabric8.kubernetes.client.KubernetesClientException: Failure executing: POST at: https://kubernetes.default.svc.cluster.local/api/v1/namespaces/spark-operator/pods. Message: admission webhook "validatepod.volcano.sh" denied the request: failed to get PodGroup for pod <spark-operator/spark-sql-job-test-manual-10-q1-89a4df860229efaa-exec-3>: podgroups.scheduling.volcano.sh "spark-0f19d22bb4564761a869067c3c54eb51-podgroup" not found. Received status: Status(apiVersion=v1, code=400, details=null, kind=Status, message=admission webhook "validatepod.volcano.sh" denied the request: failed to get PodGroup for pod <spark-operator/spark-sql-job-test-manual-10-q1-89a4df860229efaa-exec-3>: podgroups.scheduling.volcano.sh "spark-0f19d22bb4564761a869067c3c54eb51-podgroup" not found, metadata=ListMeta(_continue=null, remainingItemCount=null, resourceVersion=null, selfLink=null, additionalProperties={}), reason=null, status=Failure, additionalProperties={}).

日志里有kyuubi组装的spark-submit语句，调试时优先看这个是否配置在kyuubi-defaults.conf的配置是否会转换出现在这里，提交时间被用来判断任务超时，调试时可以删掉
	--conf spark.kyuubi.engine.submit.time=1678355305394 \
/app/hdfs/spark/bin/spark-submit \
	--class org.apache.kyuubi.engine.spark.SparkSQLEngine \
	--conf spark.hive.server2.thrift.resultset.default.fetch.size=1000 \
	--conf spark.kyuubi.client.ipAddress=100.110.242.107 \
	--conf spark.kyuubi.frontend.protocols=THRIFT_BINARY \
	--conf spark.kyuubi.ha.addresses=kyuubi-89757bf65-kwrht:2181 \
	--conf spark.kyuubi.ha.engine.ref.id=e49c3107-8ae0-4844-a403-dfd99a1a0841 \
	--conf spark.kyuubi.ha.namespace=/kyuubi_1.7.0_USER_SPARK_SQL/hdfs/default \
	--conf spark.kyuubi.ha.zookeeper.auth.type=NONE \
	--conf spark.kyuubi.kubernetes.namespace=spark-operator \
	--conf spark.kyuubi.server.ipAddress=0.0.0.0 \
	--conf spark.kyuubi.session.connection.url=0.0.0.0:10009 \
	--conf spark.kyuubi.session.real.user=hdfs \
	--conf spark.app.name=kyuubi_USER_SPARK_SQL_hdfs_default_e49c3107-8ae0-4844-a403-dfd99a1a0841 \
	--conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss:3.3.1 \
	--conf spark.kubernetes.driver.label.kyuubi-unique-tag=e49c3107-8ae0-4844-a403-dfd99a1a0841 \
	--conf spark.kubernetes.driver.pod.featureSteps=org.apache.spark.deploy.k8s.features.VolcanoFeatureStep \
	--conf spark.kubernetes.executor.pod.featureSteps=org.apache.spark.deploy.k8s.features.VolcanoFeatureStep \
	--conf spark.kubernetes.scheduler.name=volcano \
	--conf spark.kubernetes.scheduler.volcano.podGroupTemplateFile=/app/hdfs/spark/work-dir/podgroups/volcano-halfavailable-podgroup.yaml \
	--conf spark.submit.deployMode=cluster \
	--conf spark.kubernetes.driverEnv.SPARK_USER_NAME=hdfs \
	--conf spark.executorEnv.SPARK_USER_NAME=hdfs \
	--proxy-user hdfs /opt/kyuubi/externals/engines/spark/kyuubi-spark-sql-engine_2.12-1.7.0.jar

EOF
