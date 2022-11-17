wget -c https://github.com/juicedata/juicefs/releases/download/v1.0.2/juicefs-1.0.2-linux-amd64.tar.gz
wget -c https://github.com/juicedata/juicefs/releases/download/v1.0.2/juicefs-hadoop-1.0.2.jar
tar xzvf juicefs-1.0.2-linux-amd64.tar.gz
docker run --privileged --name juicefs-hadoop-client -d -v /Volumes/data/workspace:/root/workspace chenseanxy/hadoop:3.2.1-nolib tail -f /dev/null

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

nohup docker build ./ --progress=plain -t harbor.my.org:1080/chenseanxy/hadoop-ubu-juicefs:3.2.1-nolib > build-Dockerfile-hadoop-ubu-juicefs.log 2>&1 &
tail -f build-Dockerfile-hadoop-ubu-juicefs.log
docker push harbor.my.org:1080/chenseanxy/hadoop-ubu-juicefs:3.2.1-nolib

#kubectl run juicefs-test -it --image=harbor.my.org:1080/chenseanxy/hadoop-ubu-juicefs:3.2.1-nolib --image-pull-policy="Always" --restart=Never --rm -- /bin/bash
kubectl run juicefs-test -it --image=harbor.my.org:1080/chenseanxy/hadoop-ubu-juicefs:3.2.1-nolib --restart=Never --rm -- /bin/bash
  mc config host add minio https://minio.minio-tenant-1.svc.cluster.local QR9RXSLIPZCLQCHB240V ThPMZakACdQ42AU4a8A3HgGJAotvm148hW4jpv4m
  mc mb minio/jfs
  mc ls minio/jfs
  juicefs format \
      --storage minio \
      --bucket https://minio.minio-tenant-1.svc.cluster.local/jfs?tls-insecure-skip-verify=true \
      --access-key QR9RXSLIPZCLQCHB240V \
      --secret-key ThPMZakACdQ42AU4a8A3HgGJAotvm148hW4jpv4m \
      "redis://my-redis-ha.redis.svc.cluster.local:6379/1" \
      miniofs
  mkdir jfsmnt
  juicefs mount "redis://my-redis-ha.redis.svc.cluster.local:6379/1" jfsmnt