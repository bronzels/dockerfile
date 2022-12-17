wget -c https://github.com/juicedata/juicefs/releases/download/v1.0.2/juicefs-1.0.2-linux-amd64.tar.gz
wget -c https://github.com/juicedata/juicefs/releases/download/v1.0.2/juicefs-hadoop-1.0.2.jar
tar xzvf juicefs-1.0.2-linux-amd64.tar.gz
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
    --access-key QR9RXSLIPZCLQCHB240V \
    --secret-key ThPMZakACdQ42AU4a8A3HgGJAotvm148hW4jpv4m \
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


cat > juicefs-test.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: juicefs-test
  labels:
    app: nginx
spec:
  containers:
    - name: juicefs-test
      image: harbor.my.org:1080/chenseanxy/hadoop-ubussh-juicefs:3.2.1-nolib
      command: ["tail"]
      args: ["-f", "/dev/null"]
      securityContext:
        privileged: true
        capabilities:
          add: ["SYS_ADMIN"]
EOF
kubectl apply -f juicefs-test.yaml
kubectl delete -f juicefs-test.yaml
kubectl exec -it juicefs-test -- /bin/bash
#kubectl run juicefs-test -it --image=harbor.my.org:1080/chenseanxy/hadoop-ubussh-juicefs:3.2.1-nolib --restart=Never --rm -- /bin/bash
  mc config host add minio https://minio.minio-tenant-1.svc.cluster.local EUQPL08FI26I3SC1QHB3 FrQ17BqUELW7kWhzVk9udlM278U9sWv98CRJlcm5
  mc mb minio/jfs
  mc ls minio/jfs
  juicefs format \
      --storage minio \
      --bucket https://minio.minio-tenant-1.svc.cluster.local/jfs?tls-insecure-skip-verify=true \
      --access-key EUQPL08FI26I3SC1QHB3 \
      --secret-key FrQ17BqUELW7kWhzVk9udlM278U9sWv98CRJlcm5 \
      "redis://:redis@my-redis-master.redis.svc.cluster.local:6379/1" \
      miniofs
  mkdir jfsmnt
  juicefs mount "redis://my-redis-ha.redis.svc.cluster.local:6379/1" jfsmnt
  export MINIO_ROOT_USER=admin
  export MINIO_ROOT_PASSWORD=12345678
  miniogw gateway juicefs --console-address ':42311' redis://my-redis-ha.redis.svc.cluster.local:6379/1 &
kubectl port-forward juicefs-test 42311:42311 &

kubectl exec -it -n hadoop my-hadoop-yarn-rm-0 -- /bin/bash
  su hdfs
    hdfs dfs -mkdir -p /jobhistory/logs
    hdfs dfs -mkdir -p /user/hdfs/yarn-logs
kubectl port-forward -n hadoop my-hadoop-yarn-rm-0 42311:42311 &


redis-cli -n 1 flushdb