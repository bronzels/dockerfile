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

JUICEFS_PRJ_HOME=${MYHOME}/workspace/dockerfile/juicefs

#JUICEFS_VERSION=1.0.2
#JUICEFS_VERSION=1.0.3
#JUICEFS_VERSION=1.0.4
JUICEFS_VERSION=1.1.1

#csirev=0.17.4
#csirev=0.17.5
#csirev=0.19.0
csirev=0.23.1

go_path=${MYHOME}/workspace/gopath

cd ${JUICEFS_PRJ_HOME}

wget -c https://github.com/juicedata/juicefs/archive/refs/tags/v${JUICEFS_VERSION}.tar.gz -O juicefs-${JUICEFS_VERSION}.tar.gz
wget -c https://github.com/juicedata/juicefs/releases/download/v${JUICEFS_VERSION}/juicefs-${JUICEFS_VERSION}-linux-amd64.tar.gz
wget -c https://github.com/juicedata/juicefs/releases/download/v${JUICEFS_VERSION}/juicefs-hadoop-${JUICEFS_VERSION}.jar
tar xzvf juicefs-${JUICEFS_VERSION}-linux-amd64.tar.gz
docker run --privileged --name juicefs-hadoop-client -d -v /Volumes/data/workspace:/root/workspace harbor.my.org:1080/chenseanxy/hadoop-ubussh:3.2.1-nolib tail -f /dev/null
#检查/dev/fuse确认支持fuse
docker exec -it juicefs-hadoop-client /bin/bash
  ls /dev/fuse
docker stop juicefs-hadoop-client && docker rm juicefs-hadoop-client

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

#source ~/proxy.sh
#mv ${go_path} ./
#docker build ./ --progress=plain --build-arg HTTP_PROXY=${HTTP_PROXY} --build-arg HTTPS_PROXY=${HTTPS_PROXY} --build-arg NO_PROXY=${NO_PROXY} --build-arg JUICEFS_VERSION="${JUICEFS_VERSION}" -t harbor.my.org:1080/chenseanxy/hadoop-ubussh-juicefs:3.2.1-nolib
#nohup docker build ./ --progress=plain --build-arg HTTP_PROXY=${HTTP_PROXY} --build-arg HTTPS_PROXY=${HTTPS_PROXY} --build-arg NO_PROXY=${NO_PROXY} --build-arg JUICEFS_VERSION="${JUICEFS_VERSION}" -t harbor.my.org:1080/chenseanxy/hadoop-ubussh-juicefs:3.2.1-nolib > build-Dockerfile-hadoop-ubussh-juicefs.log 2>&1 &
#tail -f build-Dockerfile-hadoop-ubussh-juicefs.log
docker build ./ --progress=plain --build-arg JUICEFS_VERSION="${JUICEFS_VERSION}" -t harbor.my.org:1080/chenseanxy/hadoop-ubussh-juicefs:3.2.1-nolib
:<<EOF
RUN make build -j 12
go: downloading k8s.io/kube-openapi
这一步很慢，要耐心等，用fq proxy好像没有帮助，还不如继续用GOPROXY
EOF
#mv gopath ${MYHOME}/workspace

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

  Username: 8UO66W6IHMOVQ3377AVN 
  Password: RtiK0qLDMjzLHKhMIk3NHqsblQjMijF23AKDUltw 

kubectl run distfs-test -it --image=harbor.my.org:1080/chenseanxy/hadoop-ubussh-juicefs:3.2.1-nolib --restart=Never --rm -- /bin/bash
#kubectl exec -it distfs-test -- /bin/bash
  mc config host add minio https://minio.minio-tenant-1.svc.cluster.local 8UO66W6IHMOVQ3377AVN RtiK0qLDMjzLHKhMIk3NHqsblQjMijF23AKDUltw
  mc mb minio/jfs
  mc ls minio/jfs
  juicefs format \
      --storage minio \
      --bucket https://minio.minio-tenant-1.svc.cluster.local/jfs?tls-insecure-skip-verify=true \
      --access-key 8UO66W6IHMOVQ3377AVN \
      --secret-key RtiK0qLDMjzLHKhMIk3NHqsblQjMijF23AKDUltw \
      "redis://:redis@my-redis-master.redis.svc.cluster.local:6379/1" \
      miniofs
  #mount test use distfs-test image and modprob 1stly
  #unnecessary if only for hdfs
  #
  su
    root
    apt-get install kmod fuse -y
    mkdir -p /lib/modules/`uname -r` && depmod -a
    modprobe fuse
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
wget -c https://github.com/juicedata/juicefs-csi-driver/archive/refs/tags/v${csirev}.tar.gz -O juicefs-csi-driver-${csirev}.tar.gz
tar xzvf juicefs-csi-driver-${csirev}.tar.gz


cd ${JUICEFS_PRJ_HOME}/juicefs-csi-driver-${csirev}/docker
tar xzvf ${JUICEFS_PRJ_HOME}/juicefs-${JUICEFS_VERSION}.tar.gz
mv juicefs-${JUICEFS_VERSION} juicefs
file=ce.juicefs.Dockerfile
cp ${file} ${file}.bk
cp ${JUICEFS_PRJ_HOME}/${file} ${file}
docker build ./ -f ce.juicefs.Dockerfile --progress=plain -t harbor.my.org:1080/storage/juicedata-mount:ce-v${JUICEFS_VERSION}
docker push harbor.my.org:1080/storage/juicedata-mount:ce-v${JUICEFS_VERSION}


#docker
ansible all -m shell -a"docker images|grep juicedata-mount"
ansible all -m shell -a"docker images|grep juicedata-mount|awk '{print \$3}'|xargs docker rmi -f"
#containerd
ansible all -m shell -a"crictl images|grep juicedata-mount"
ansible all -m shell -a"crictl images|grep juicedata-mount|awk '{print \$3}'|xargs crictl rmi"


cd ${JUICEFS_PRJ_HOME}/juicefs-csi-driver-${csirev}/deploy
#安装
file=k8s.yaml
cp ${file} ${file}.bk
$SED -i "/        image: juicedata\/juicefs-csi-driver:v0.19.0/i\        - name: JUICEFS_CE_MOUNT_IMAGE\n          value: harbor.my.org:1080\/storage\/juicedata-mount:ce-v1.0.4" ${file}
kubectl apply -f k8s.yaml
kubectl patch storageclass juicefs-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl -n kube-system get pods -l app.kubernetes.io/name=juicefs-csi-driver
#升级，参考https://juicefs.com/docs/zh/csi/upgrade-csi-driver
kubectl delete -f k8s.yaml


kubectl run distfs-test -it --image=harbor.my.org:1080/chenseanxy/hadoop-ubussh-juicefs:3.2.1-nolib --restart=Never --rm -- /bin/bash
#kubectl exec -it distfs-test -- /bin/bash
  mc config host add minio https://minio.minio-tenant-1.svc.cluster.local JCTHLDGEMZM03OF5B163 DrTRA1zlIznEY5vY9rVrt68fjUO0z98ZGPCo39ZX
  mc mb minio/jfspvc
  mc ls minio/jfspvc
  juicefs format \
      --storage minio \
      --bucket https://minio.minio-tenant-1.svc.cluster.local/jfspvc?tls-insecure-skip-verify=true \
      --access-key JCTHLDGEMZM03OF5B163 \
      --secret-key DrTRA1zlIznEY5vY9rVrt68fjUO0z98ZGPCo39ZX \
      "redis://:redis@my-redis-master.redis.svc.cluster.local:6379/2" \
      miniofspvc
  export MINIO_ROOT_USER=admin
  export MINIO_ROOT_PASSWORD=12345678
  miniogw gateway juicefs --console-address ':42312' redis://:redis@my-redis-master.redis.svc.cluster.local:6379/2 &
kubectl port-forward distfs-test 42312:42312 &

cd ${JUICEFS_PRJ_HOME}
kubectl apply -f juicefs-sc-secret.yaml -n kube-system
kubectl apply -f juicefs-sc.yaml -n kube-system
:<<EOF
kubectl delete -f juicefs-sc.yaml -n kube-system
kubectl delete -f juicefs-sc-secret.yaml -n kube-system
EOF

kubectl apply -f test/jfs-test-pvc.yaml
kubectl apply -f test/jfs-test-pod.yaml

kubectl describe pod -n kube-system `kubectl get pod -n kube-system | grep juicefs | grep pvc | awk '{print $1}'`
kubectl describe pod jfs-test

kubectl describe pod jfs-test

kubectl logs jfs-test
  success
kubectl delete pod jfs-test --force --grace-period=0
kubectl apply -f test/jfs-test-pod.yaml
kubectl logs jfs-test
  success
  success

kubectl delete -f test/jfs-test-pod.yaml
kubectl delete -f test/jfs-test-pvc.yaml

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
kubectl get pod -n kube-system | grep juicefs | grep pvc | grep Terminating | awk '{print $1}' | xargs kubectl delete pod $1 -n kube-system --force --grace-period=0

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

#JUICEFS_VERSION=1.0.3
JUICEFS_VERSION=1.0.4
docker run -itd --name centos7-netutil-ccplus7-go-jdk --restart unless-stopped -v /Volumes/data/m2:/root/.m2 -v $PWD/juicefs-${JUICEFS_VERSION}:/root/workspace/juicefs -v /Volumes/data/gopath:/root/workspace/gopath harbor.my.org:1080/base/python:3.8-centos7-netutil-ccplus7-go-jdk tail -f /dev/null
docker exec -it centos7-netutil-ccplus7-go-jdk bash
  java -version
  cd /root/workspace/juicefs/sdk/java
  make
docker cp centos7-netutil-ccplus7-go-jdk:/root/workspace/juicefs/sdk/java/target/juicefs-hadoop-${JUICEFS_VERSION}.jar ./juicefs-hadoop-${JUICEFS_VERSION}-jdk11-centos7.jar
docker stop centos7-netutil-ccplus7-go-jdk && docker rm centos7-netutil-ccplus7-go-jdk

:<<EOF
docker run -itd --name debian11-ccplus-go-jdk --restart unless-stopped -v /Volumes/data/m2:/root/.m2 -v $PWD/juicefs-${JUICEFS_VERSION}:/root/juicefs -v /Volumes/data/gopath:/root/gopath harbor.my.org:1080/base/debian11:ccplus-go-jdk tail -f /dev/null
docker exec -it debian11-ccplus-go-jdk bash
  java -version
  cd /root/juicefs/sdk/java
  make
docker cp debian11-ccplus-go-jdk:/root/juicefs/sdk/java/target/juicefs-hadoop-${JUICEFS_VERSION}.jar ./juicefs-hadoop-${JUICEFS_VERSION}-jdk11-debian11.jar
EOF

docker run -itd --name ubuntu22-netutil-ccplus7-go-jdk --restart unless-stopped -v /Volumes/data/m2:/root/.m2 -v $PWD/juicefs-${JUICEFS_VERSION}:/root/juicefs -v /Volumes/data/gopath:/root/gopath harbor.my.org:1080/base/ubuntu22:netutil-ccplus7-go-jdk tail -f /dev/null
docker exec -it ubuntu22-netutil-ccplus7-go-jdk bash
  java -version
  cd /root/juicefs/sdk/java
  make
docker cp ubuntu22-netutil-ccplus7-go-jdk:/root/juicefs/sdk/java/target/juicefs-hadoop-${JUICEFS_VERSION}.jar ./juicefs-hadoop-${JUICEFS_VERSION}-jdk8-ubuntu22.jar
docker stop ubuntu22-netutil-ccplus7-go-jdk && docker rm ubuntu22-netutil-ccplus7-go-jdk

docker run -itd --name ubuntu22-netutil-ccplus7-go-jdk-11 --restart unless-stopped -v /Volumes/data/m2:/root/.m2 -v $PWD/juicefs-${JUICEFS_VERSION}:/root/juicefs -v /Volumes/data/gopath:/root/gopath harbor.my.org:1080/base/ubuntu22:netutil-ccplus7-go-jdk tail -f /dev/null
docker exec -it ubuntu22-netutil-ccplus7-go-jdk-11 bash
  java -version
  PRIORITY_JDK_11=11000
  update-alternatives --install /usr/bin/java java /usr/lib/jvm/java-11-openjdk-amd64/bin/java ${PRIORITY_JDK_11}
  update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/java-11-openjdk-amd64/bin/javac ${PRIORITY_JDK_11}
  update-alternatives --install /usr/bin/javap javap /usr/lib/jvm/java-11-openjdk-amd64/bin/javap ${PRIORITY_JDK_11}
  update-alternatives --install /usr/bin/javadoc javadoc /usr/lib/jvm/java-11-openjdk-amd64/bin/javadoc ${PRIORITY_JDK_11}
  update-alternatives --install /usr/bin/jstack jstack /usr/lib/jvm/java-11-openjdk-amd64/bin/jstack ${PRIORITY_JDK_11}
#  update-alternatives --install /usr/bin/jshell jshell /usr/lib/jvm/java-11-openjdk-amd64/bin/jshell ${PRIORITY_JDK_11}
  update-alternatives --install /usr/bin/jar jar /usr/lib/jvm/java-11-openjdk-amd64/bin/jar ${PRIORITY_JDK_11}
  update-alternatives --install /usr/bin/jstat jstat /usr/lib/jvm/java-11-openjdk-amd64/bin/jstat ${PRIORITY_JDK_11}
  java -version
  cd /root/juicefs/sdk/java
  make
docker cp ubuntu22-netutil-ccplus7-go-jdk-11:/root/juicefs/sdk/java/target/juicefs-hadoop-${JUICEFS_VERSION}.jar ./juicefs-hadoop-${JUICEFS_VERSION}-jdk11-ubuntu22.jar
docker stop ubuntu22-netutil-ccplus7-go-jdk-11 && docker rm ubuntu22-netutil-ccplus7-go-jdk-11

docker run -itd --name ubuntu20-netutil-ccplus7-go-jdk --restart unless-stopped -v /Volumes/data/m2:/root/.m2 -v $PWD/juicefs-${JUICEFS_VERSION}:/root/juicefs -v /Volumes/data/gopath:/root/gopath harbor.my.org:1080/base/ubuntu20:netutil-ccplus7-go-jdk tail -f /dev/null
docker exec -it ubuntu20-netutil-ccplus7-go-jdk bash
  java -version
  cd /root/juicefs/sdk/java
  make
docker cp ubuntu20-netutil-ccplus7-go-jdk:/root/juicefs/sdk/java/target/juicefs-hadoop-${JUICEFS_VERSION}.jar ./juicefs-hadoop-${JUICEFS_VERSION}-jdk11-ubuntu20.jar
docker stop ubuntu20-netutil-ccplus7-go-jdk && docker rm ubuntu20-netutil-ccplus7-go-jdk

#juicefs csi除了删除挂载pod以后相应的pvc pod terminating但是不删除以外，还有一些pvc pod在running状态，但是并没有对应的pvc和挂载pvc的应用pod，用csi-doctor.sh可以检查出来，这些pod都需要删除，不然逐渐累计，系统资源就不够了。
cat << \EOF > remove-running-pvc-pod-without-app.sh
#!/bin/bash

podstr=`kubectl get pod -n kube-system | grep juicefs | grep pvc | awk '{print $1}'`
OLD_IFS="$IFS"
IFS=" "
podarr=($podstr)
IFS="$OLD_IFS"
for podname in ${podarr[*]}
do
  echo "---Debug, pvc podname:$podname"
  appname=`./csi-doctor.sh get-app $podname`
  if [[ -z ${appname} ]]; then
    echo "---Debug, no app for this running pvc pod, removed"
    kubectl get pod -n kube-system | grep $podname | awk '{print $1}' | xargs kubectl delete pod -n kube-system --force --grace-period=0
    #kubectl get pod -n kube-system | grep $podname | awk '{print $1}' | xargs kubectl patch pod $1 -n kube-system -p '{"metadata":{"finalizers":null}}'
  else
    echo "---Debug, app for this running pvc pod:"
    echo ${appname}
  fi
  echo "---Debug, -----------------------------"
done  
EOF
chmod a+x remove-running-pvc-pod-without-app.sh
sudo scp ./remove-running-pvc-pod-without-app.sh dtpct:/root/

sudo ssh dtpct /root/remove-running-pvc-pod-without-app.sh
kubectl get pod -n kube-system | grep juicefs | grep pvc | grep Running

kubectl get pod -n spark-operator
sudo ssh dtpct
  ./csi-doctor.sh get-mount mysrv-sparksrv-hs-6c7594cddb-2bnd8 -n spark-operator
    spark-operator	mysrv-sparksrv-hs-6c7594cddb-2bnd8
  ./csi-doctor.sh get-app juicefs-mdubu-pvc-5c0e0bab-4f77-49cc-a925-3e300267b23d-yapmri


JUICEFS_VERSION=1.0.4
wget -c https://github.com/juicedata/juicefs/releases/download/v${JUICEFS_VERSION}/juicefs-${JUICEFS_VERSION}-linux-amd64.tar.gz
mkdir juicefs-linux-amd64
tar xzvf juicefs-${JUICEFS_VERSION}-linux-amd64.tar.gz -C juicefs-linux-amd64
ansible all -m copy -a"src=juicefs-linux-amd64/juicefs dest=/sbin/mount.juicefs"
kubectl run distfs-test -it --image=harbor.my.org:1080/chenseanxy/hadoop-ubussh-juicefs:3.2.1-nolib --restart=Never --rm -- /bin/bash
#kubectl exec -it distfs-test -- /bin/bash
  mc config host add minio https://minio.minio-tenant-1.svc.cluster.local JCTHLDGEMZM03OF5B163 DrTRA1zlIznEY5vY9rVrt68fjUO0z98ZGPCo39ZX
  mc mb minio/jfspvc4cs
  mc ls minio/jfspvc4cs
  juicefs format \
      --storage minio \
      --bucket https://minio.minio-tenant-1.svc.cluster.local/jfspvc4cs?tls-insecure-skip-verify=true \
      --access-key JCTHLDGEMZM03OF5B163 \
      --secret-key DrTRA1zlIznEY5vY9rVrt68fjUO0z98ZGPCo39ZX \
      "redis://:redis@my-redis-master.redis.svc.cluster.local:6379/4" \
      miniofspvc4cs
ansible all -m copy -a"src=juicefs-linux-amd64/juicefs dest=/sbin/mount.juicefs"
ansible all -m shell -a"mkdir -p /data/k8s"
#这种方式把k8s服务挂载到裸机，很别扭，放弃
ansible all -m shell -a"echo 'redis://:redis@my-redis-master.redis.svc.cluster.local:6379/4    /data/k8s       juicefs     _netdev,max-uploads=50,writeback,cache-size=204800     0  0' >> /etc/fstab"


#cube-studio workflow专用bucket
kubectl run distfs-test -it --image=harbor.my.org:1080/chenseanxy/hadoop-ubussh-juicefs:3.2.1-nolib --restart=Never --rm -- /bin/bash
#kubectl exec -it distfs-test -- /bin/bash
  mc config host add minio https://minio.minio-tenant-1.svc.cluster.local JCTHLDGEMZM03OF5B163 DrTRA1zlIznEY5vY9rVrt68fjUO0z98ZGPCo39ZX
  mc mb minio/cubestudio
  mc ls minio/cubestudio
