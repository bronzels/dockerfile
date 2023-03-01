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

JUICEFS_HOME=${MYHOME}/workspace/dockerfile/juicefs

JUICEFS_VERSION=1.0.2

wget -c https://github.com/juicedata/juicefs/releases/download/v${JUICEFS_VERSION}/juicefs-${JUICEFS_VERSION}-linux-amd64.tar.gz
wget -c https://github.com/juicedata/juicefs/releases/download/v${JUICEFS_VERSION}/juicefs-hadoop-${JUICEFS_VERSION}.jar
tar xzvf juicefs-${JUICEFS_VERSION}-linux-amd64.tar.gz
docker run --privileged --name juicefs-hadoop-client -d -v /Volumes/data/workspace:/root/workspace harbor.my.org:1080/chenseanxy/hadoop-ubussh:3.2.1-nolib tail -f /dev/null
#检查/dev/fuse确认支持fuse

:<<EOF
#client
#mac
#下载安装osxfuse
brew tap juicedata/homebrew-tap
brew install juicefs
#local mnt test
juicefs format \
    --storage minio \
    --bucket https://localhost:1443/rtc \
    --access-key BCRG2IUBDWMKLQD76NWZ \
    --secret-key KRKbToTPOaZtBEceFicW1Iako5YXpZaquVqzKdBC \
    "redis://localhost:6379/1" \
    miniofs
EOF

wget -c https://github.com/libfuse/libfuse/releases/download/fuse_3_12_0/fuse-3.12.0.tar.gz
wget -c https://github.com/libfuse/libfuse/releases/download/fuse_2_9_4/fuse-2.9.2.tar.gz
git clone git@github.com:juicedata/minio.git miniogw

nohup docker build ./ --progress=plain -t harbor.my.org:1080/chenseanxy/hadoop-ubussh-juicefs:3.2.1-nolib > build-Dockerfile-hadoop-ubussh-juicefs.log 2>&1 &
tail -f build-Dockerfile-hadoop-ubussh-juicefs.log
#docker build ./ --progress=plain -t harbor.my.org:1080/chenseanxy/hadoop-ubussh-juicefs:3.2.1-nolib
docker push harbor.my.org:1080/chenseanxy/hadoop-ubussh-juicefs:3.2.1-nolib

docker run --privileged --name juicefs-hadoop-client -it --rm -v /Volumes/data/workspace:/root/workspace harbor.my.org:1080/chenseanxy/hadoop-ubussh-juicefs:3.2.1-nolib /bin/bash

#precondition
  #a nfs server, such as one on cp
  #k8s nfs provisioner
  #redis

#each
rpm -qa | grep fuse
yum install -y fuse
#fuse-2.9.2
modprobe fuse
ls /dev/fuse

#kubectl run juicefs-test -it --image=harbor.my.org:1080/chenseanxy/hadoop-ubu-juicefs:3.2.1-nolib --image-pull-policy="Always" --restart=Never --rm -- /bin/bash
#kubectl run juicefs-test -it --image=harbor.my.org:1080/chenseanxy/hadoop-ubussh-juicefs:3.2.1-nolib --restart=Never --rm -- /bin/bash

kubectl exec -it distfs-test -- /bin/bash
  mc config host add minio https://minio.minio-tenant-1.svc.cluster.local 4UFXGHAUY3W02Z2OM247 MCzN5DsK1o8TF5tzQ2TkjQRv39IoLiqc8FaKFEWP
  mc mb minio/jfs
  mc ls minio/jfs
  juicefs format \
      --storage minio \
      --bucket https://minio.minio-tenant-1.svc.cluster.local/jfs?tls-insecure-skip-verify=true \
      --access-key 4UFXGHAUY3W02Z2OM247 \
      --secret-key MCzN5DsK1o8TF5tzQ2TkjQRv39IoLiqc8FaKFEWP \
      "redis://:redis@my-redis-master.redis.svc.cluster.local:6379/1" \
      miniofs
  #mount test use distfs-test image and modprob 1stly
  #unnecessary if only for hdfs
  mkdir jfsmnt
  juicefs mount "redis://:redis@my-redis-master.redis.svc.cluster.local:6379/1" jfsmnt
  export MINIO_ROOT_USER=admin
  export MINIO_ROOT_PASSWORD=12345678
  miniogw gateway juicefs --console-address ':42311' redis://:redis@my-redis-master.redis.svc.cluster.local:6379/1 &
kubectl port-forward distfs-test 42311:42311 &

kubectl exec -it -n hadoop my-hadoop-yarn-rm-0 -- /bin/bash
  hdfs dfs -mkdir -p /jobhistory/logs
  hdfs dfs -mkdir -p /user/hdfs/yarn-logs
kubectl port-forward -n hadoop my-hadoop-yarn-rm-0 42311:42311 &


redis-cli -n 1 flushdb

:<<EOF
kubectl -n kube-system create secret generic juicefs-sc-secret \
  --from-literal=name=miniofs \
  --from-literal=metaurl=redis://:redis@my-redis-master.redis.svc.cluster.local:6379/1 \
  --from-literal=storage=minio \
  --from-literal=bucket=https://minio.minio-tenant-1.svc.cluster.local/jfs?tls-insecure-skip-verify=true \
  --from-literal=access-key BCRG2IUBDWMKLQD76NWZ \
  --from-literal=secret-key KRKbToTPOaZtBEceFicW1Iako5YXpZaquVqzKdBC \
EOF
#all k8s node
ctr -n k8s.io image import juicedata-juicefs-csi-driver-v0.17.4.tar
ctr -n k8s.io image import juicedata-mount-v${JUICEFS_VERSION}-4.8.3.tar
#csirev=0.17.4
csirev=0.17.5
wget -c https://github.com/juicedata/juicefs-csi-driver/archive/refs/tags/v${csirev}.tar.gz -O juicefs-csi-driver-${csirev}.tar.gz
tar xzvf juicefs-csi-driver-${csirev}.tar.gz
ln -s juicefs-csi-driver-${csirev} juicefs-csi-driver
cd juicefs-csi-driver/deploy
#安装
kubectl apply -f k8s.yaml
kubectl -n kube-system get pods -l app.kubernetes.io/name=juicefs-csi-driver
#升级，参考https://juicefs.com/docs/zh/csi/upgrade-csi-driver

kubectl exec -it distfs-test -- /bin/bash
  mc config host add minio https://minio.minio-tenant-1.svc.cluster.local 4UFXGHAUY3W02Z2OM247 MCzN5DsK1o8TF5tzQ2TkjQRv39IoLiqc8FaKFEWP
  mc mb minio/jfspvc
  mc ls minio/jfspvc
  juicefs format \
      --storage minio \
      --bucket https://minio.minio-tenant-1.svc.cluster.local/jfspvc?tls-insecure-skip-verify=true \
      --access-key 4UFXGHAUY3W02Z2OM247 \
      --secret-key MCzN5DsK1o8TF5tzQ2TkjQRv39IoLiqc8FaKFEWP \
      "redis://:redis@my-redis-master.redis.svc.cluster.local:6379/2" \
      miniofspvc
  export MINIO_ROOT_USER=admin
  export MINIO_ROOT_PASSWORD=12345678
  miniogw gateway juicefs --console-address ':42312' redis://:redis@my-redis-master.redis.svc.cluster.local:6379/2 &
kubectl port-forward distfs-test 42312:42312 &
kubectl apply -f juicefs-sc-secret.yaml -n kube-system
kubectl apply -f juicefs-sc.yaml -n kube-system
:<<EOF
kubectl delete -f juicefs-sc.yaml -n kube-system
kubectl delete -f juicefs-sc-secret.yaml -n kube-system
EOF

wget -c https://github.com/juicedata/juicefs/archive/refs/tags/v${JUICEFS_VERSION}.tar.gz -o juicefs-${JUICEFS_VERSION}.tar.gz
tar xzvf juicefs-${JUICEFS_VERSION}.tar.gz
cd juicefs-${JUICEFS_VERSION}/sdk/java

#修改Makefile，增加 -Dmaven.javadoc.skip=true

export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home
mv target/juicefs-hadoop-${JUICEFS_VERSION}.jar ${JUICEFS_HOME}/juicefs-hadoop-${JUICEFS_VERSION}-jdk17.jar

export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-11.0.17.jdk/Contents/Home
file=Makefile
cp ${file} ${file}.bk
$SED -i 's/-Dmaven.test.skip=true/-Dmaven.test.skip=true -Dmaven.javadoc.skip=true/g' ${file}
mv target/juicefs-hadoop-${JUICEFS_VERSION}.jar ${JUICEFS_HOME}/juicefs-hadoop-${JUICEFS_VERSION}-jdk11.jar

#/var/jfsCache会在集群某个机器上累计很大

:<<EOF
spark作业无法提交是因为因为history保存挂载的pvc pod 忽然Terminating， driver pod卡在ContainerCreating状态
juicefs群恢复：
  可能跟这个问题有关 https://github.com/juicedata/juicefs-csi-driver/issues/537 在 0.17.5 里修复了，你升级一下 csi 试试
  看日志是 CSI 连接 ApiServer 删除 mount pod 的 finalizer 的时候超时了
EOF
kubectl get pod -n kube-system | grep juicefs | grep pvc | grep Terminating | awk '{print $1}' | xargs kubectl patch pod $1 -n kube-system -p '{"metadata":{"finalizers":null}}'

wget https://raw.githubusercontent.com/juicedata/juicefs-csi-driver/master/scripts/csi-doctor.sh
#在集群中任意一台可以执行 kubectl 的节点上，安装诊断脚本
chmod a+x csi-doctor.sh
#诊断脚本中最为常用的功能，就是方便地获取 Mount Pod 相关信息。假设应用 Pod 为 default 命名空间下的 my-app-pod：
# 获取指定应用 Pod 所用的 Mount Pod
./csi-doctor.sh get-mount tmp-mpp-doris-ingestion-test-db-web-sales-sql-707b20869b5b23bf-driver -n spark-operator
# 获取使用指定 Mount Pod 的所有应用 Pod
./csi-doctor.sh get-app juicefs-mdlapubu-pvc-5c0e0bab-4f77-49cc-a925-3e300267b23d-dvnxlr
./csi-doctor.sh debug tmp-mpp-doris-ingestion-test-db-web-sales-sql-707b20869b5b23bf-driver -n spark-operator
:<<EOF
## CSI Controller Image: juicedata/juicefs-csi-driver:v0.17.4 quay.io/k8scsi/csi-provisioner:v1.6.0 quay.io/k8scsi/livenessprobe:v1.1.0
## Application Pod Event
LAST SEEN   TYPE      REASON        OBJECT                                                                      MESSAGE
5m28s       Warning   FailedMount   pod/tmp-mpp-doris-ingestion-test-db-web-sales-sql-707b20869b5b23bf-driver   MountVolume.SetUp failed for volume "pvc-5c0e0bab-4f77-49cc-a925-3e300267b23d" : rpc error: code = Internal desc = Could not mount juicefs: context deadline exceeded
24m         Warning   FailedMount   pod/tmp-mpp-doris-ingestion-test-db-web-sales-sql-707b20869b5b23bf-driver   Unable to attach or mount volumes: unmounted volumes=[juicefsvol], unattached volumes=[juicefsvol spark-local-dir-1 spark-conf-volume-driver kube-api-access-px52j]: timed out waiting for the condition
42m         Warning   FailedMount   pod/tmp-mpp-doris-ingestion-test-db-web-sales-sql-707b20869b5b23bf-driver   Unable to attach or mount volumes: unmounted volumes=[juicefsvol], unattached volumes=[spark-conf-volume-driver kube-api-access-px52j juicefsvol spark-local-dir-1]: timed out waiting for the condition
11m         Warning   FailedMount   pod/tmp-mpp-doris-ingestion-test-db-web-sales-sql-707b20869b5b23bf-driver   Unable to attach or mount volumes: unmounted volumes=[juicefsvol], unattached volumes=[kube-api-access-px52j juicefsvol spark-local-dir-1 spark-conf-volume-driver]: timed out waiting for the condition
33m         Warning   FailedMount   pod/tmp-mpp-doris-ingestion-test-db-web-sales-sql-707b20869b5b23bf-driver   Unable to attach or mount volumes: unmounted volumes=[juicefsvol], unattached volumes=[spark-local-dir-1 spark-conf-volume-driver kube-api-access-px52j juicefsvol]: timed out waiting for the condition
## CSI Node Log: juicefs-csi-node-r54j5
E0301 05:15:14.165355       7 reconciler.go:103] Driver check pod juicefs-mdlapubu-pvc-defd96d1-71a2-4ac8-bf1a-83e6096ddb5f-nczkkg error: Operation cannot be fulfilled on  "juicefs-mdlapubu-pvc-defd96d1-71a2-4ac8-bf1a-83e6096ddb5f-nczkkg": can not delete pod
I0301 05:15:14.165644       7 pod_driver.go:271] Pod juicefs-mdlapubu-pvc-5c0e0bab-4f77-49cc-a925-3e300267b23d-dvnxlr in namespace kube-system is to be deleted.
E0301 05:15:14.165707       7 pod.go:128] Patch pod err:context canceled
E0301 05:15:14.165713       7 pod_driver.go:281] remove pod finalizer err:context canceled
E0301 05:15:14.165716       7 reconciler.go:103] Driver check pod juicefs-mdlapubu-pvc-5c0e0bab-4f77-49cc-a925-3e300267b23d-dvnxlr error: context canceled
I0301 05:15:19.180397       7 pod_driver.go:271] Pod juicefs-mdlapubu-pvc-5c0e0bab-4f77-49cc-a925-3e300267b23d-dvnxlr in namespace kube-system is to be deleted.
E0301 05:15:19.180438       7 pod_driver.go:84] check pod juicefs-mdlapubu-pvc-defd96d1-71a2-4ac8-bf1a-83e6096ddb5f-nczkkg annotations err: Operation cannot be fulfilled on  "juicefs-mdlapubu-pvc-defd96d1-71a2-4ac8-bf1a-83e6096ddb5f-nczkkg": can not delete pod
E0301 05:15:19.180447       7 reconciler.go:103] Driver check pod juicefs-mdlapubu-pvc-defd96d1-71a2-4ac8-bf1a-83e6096ddb5f-nczkkg error: Operation cannot be fulfilled on  "juicefs-mdlapubu-pvc-defd96d1-71a2-4ac8-bf1a-83e6096ddb5f-nczkkg": can not delete pod
E0301 05:15:19.180489       7 pod.go:128] Patch pod err:Patch "https://10.96.0.1:443/api/v1/namespaces/kube-system/pods/juicefs-mdlapubu-pvc-5c0e0bab-4f77-49cc-a925-3e300267b23d-dvnxlr?timeout=10s": context canceled
E0301 05:15:19.180500       7 pod_driver.go:281] remove pod finalizer err:Patch "https://10.96.0.1:443/api/v1/namespaces/kube-system/pods/juicefs-mdlapubu-pvc-5c0e0bab-4f77-49cc-a925-3e300267b23d-dvnxlr?timeout=10s": context canceled
E0301 05:15:19.180507       7 reconciler.go:103] Driver check pod juicefs-mdlapubu-pvc-5c0e0bab-4f77-49cc-a925-3e300267b23d-dvnxlr error: Patch "https://10.96.0.1:443/api/v1/namespaces/kube-system/pods/juicefs-mdlapubu-pvc-5c0e0bab-4f77-49cc-a925-3e300267b23d-dvnxlr?timeout=10s": context canceled
I0301 05:15:20.823078       7 node.go:78] NodePublishVolume: volume_id is pvc-5c0e0bab-4f77-49cc-a925-3e300267b23d
I0301 05:15:20.823092       7 node.go:89] NodePublishVolume: volume_capability is mount:<fs_type:"ext4" > access_mode:<mode:MULTI_NODE_MULTI_WRITER >
I0301 05:15:20.824279       7 node.go:95] NodePublishVolume: creating dir /var/lib/kubelet/pods/27bb0318-b663-4f7b-9e2c-72737df5911f/volumes/kubernetes.io~csi/pvc-5c0e0bab-4f77-49cc-a925-3e300267b23d/mount
I0301 05:15:20.824338       7 node.go:110] NodePublishVolume: volume context: map[storage.kubernetes.io/csiProvisionerIdentity:1674613358878-8081-csi.juicefs.com subPath:pvc-5c0e0bab-4f77-49cc-a925-3e300267b23d]
I0301 05:15:20.824354       7 node.go:120] NodePublishVolume: mounting juicefs with secret [secret-key storage access-key bucket envs metaurl name], options []
I0301 05:15:20.824618       7 setting.go:253] VolCtx got in config: map[storage.kubernetes.io/csiProvisionerIdentity:1674613358878-8081-csi.juicefs.com subPath:pvc-5c0e0bab-4f77-49cc-a925-3e300267b23d]
I0301 05:15:20.824635       7 juicefs.go:725] ceFormat cmd: [/usr/local/bin/juicefs format --storage=minio --bucket=https://minio.minio-tenant-1.svc.cluster.local/jfspvc?tls-insecure-skip-verify=true --access-key=4UFXGHAUY3W02Z2OM247 --secret-key=${secretkey} ${metaurl} miniofspvc]
E0301 05:15:24.195692       7 pod_driver.go:84] check pod juicefs-mdlapubu-pvc-defd96d1-71a2-4ac8-bf1a-83e6096ddb5f-nczkkg annotations err: Operation cannot be fulfilled on  "juicefs-mdlapubu-pvc-defd96d1-71a2-4ac8-bf1a-83e6096ddb5f-nczkkg": can not delete pod
E0301 05:15:24.195703       7 reconciler.go:103] Driver check pod juicefs-mdlapubu-pvc-defd96d1-71a2-4ac8-bf1a-83e6096ddb5f-nczkkg error: Operation cannot be fulfilled on  "juicefs-mdlapubu-pvc-defd96d1-71a2-4ac8-bf1a-83e6096ddb5f-nczkkg": can not delete pod
EOF
# 提前将应用 pod 信息存为环境变量
APP_NS=spark-operator  # 应用所在的 Kubernetes 命名空间
APP_POD_NAME=tmp-mpp-doris-ingestion-test-db-web-sales-sql-707b20869b5b23bf-driver
# 通过应用 pod 找到节点名
NODE_NAME=$(kubectl -n $APP_NS get po $APP_POD_NAME -o jsonpath='{.spec.nodeName}')
# 打印出所有 CSI Node pods
kubectl -n kube-system get po -l app=juicefs-csi-node
# 打印应用 pod 所在节点的 CSI Node pod
kubectl -n kube-system get po -l app=juicefs-csi-node --field-selector spec.nodeName=$NODE_NAME
# 将下方 $CSI_NODE_POD 替换为上一条命令获取到的 CSI Node pod 名称，检查日志，确认有无异常
CSI_NODE_POD=juicefs-csi-node-r54j5
kubectl -n kube-system logs $CSI_NODE_POD -c juicefs-plugin
:<<EOF
E0301 05:23:41.178732       7 pod_driver.go:281] remove pod finalizer err:context canceled
E0301 05:23:41.178749       7 reconciler.go:103] Driver check pod juicefs-mdlapubu-pvc-5c0e0bab-4f77-49cc-a925-3e300267b23d-dvnxlr error: context canceled
I0301 05:23:46.197713       7 pod_driver.go:271] Pod juicefs-mdlapubu-pvc-5c0e0bab-4f77-49cc-a925-3e300267b23d-dvnxlr in namespace kube-system is to be deleted.
E0301 05:23:46.197867       7 pod_driver.go:84] check pod juicefs-mdlapubu-pvc-defd96d1-71a2-4ac8-bf1a-83e6096ddb5f-nczkkg annotations err: Operation cannot be fulfilled on  "juicefs-mdlapubu-pvc-defd96d1-71a2-4ac8-bf1a-83e6096ddb5f-nczkkg": can not delete pod
E0301 05:23:46.197880       7 reconciler.go:103] Driver check pod juicefs-mdlapubu-pvc-defd96d1-71a2-4ac8-bf1a-83e6096ddb5f-nczkkg error: Operation cannot be fulfilled on  "juicefs-mdlapubu-pvc-defd96d1-71a2-4ac8-bf1a-83e6096ddb5f-nczkkg": can not delete pod
E0301 05:23:46.197925       7 pod.go:128] Patch pod err:Patch "https://10.96.0.1:443/api/v1/namespaces/kube-system/pods/juicefs-mdlapubu-pvc-5c0e0bab-4f77-49cc-a925-3e300267b23d-dvnxlr?timeout=10s": context canceled
E0301 05:23:46.197943       7 pod_driver.go:281] remove pod finalizer err:Patch "https://10.96.0.1:443/api/v1/namespaces/kube-system/pods/juicefs-mdlapubu-pvc-5c0e0bab-4f77-49cc-a925-3e300267b23d-dvnxlr?timeout=10s": context canceled
E0301 05:23:46.197952       7 reconciler.go:103] Driver check pod juicefs-mdlapubu-pvc-5c0e0bab-4f77-49cc-a925-3e300267b23d-dvnxlr error: Patch "https://10.96.0.1:443/api/v1/namespaces/kube-system/pods/juicefs-mdlapubu-pvc-5c0e0bab-4f77-49cc-a925-3e300267b23d-dvnxlr?timeout=10s": context canceled
(base) [root@dtpct ~]#
EOF