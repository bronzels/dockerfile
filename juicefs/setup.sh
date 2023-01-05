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
  mc config host add minio https://minio.minio-tenant-1.svc.cluster.local BCRG2IUBDWMKLQD76NWZ KRKbToTPOaZtBEceFicW1Iako5YXpZaquVqzKdBC
  mc mb minio/jfs
  mc ls minio/jfs
  juicefs format \
      --storage minio \
      --bucket https://minio.minio-tenant-1.svc.cluster.local/jfs?tls-insecure-skip-verify=true \
      --access-key BCRG2IUBDWMKLQD76NWZ \
      --secret-key KRKbToTPOaZtBEceFicW1Iako5YXpZaquVqzKdBC \
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