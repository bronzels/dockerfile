if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Mac detected."
    #mac
    MVNREPOHOME=/Volumes/data/m2/repository
    SED=gsed
else
    echo "Assuming linux by default."
    #linux
    MVNREPOHOME=~/m2repository
    SED=sed
fi

git clone https://github.com/cubefs/cubefs-hadoop.git
#in idea
mvn package -Dmaven.test.skip=true

wget -c https://github.com/cubefs/cubefs/releases/download/v2.4.0/chubaofs-v2.4.0-x86_64-linux.tar.gz -P ../cubefs-img-files/
#wget -c https://github.com/cubefs/cubefs/archive/refs/tags/v2.4.0.tar.gz -P ../cubefs-img-files/
wget -c https://github.com/cubefs/cubefs/archive/refs/tags/v3.2.0.tar.gz -P ../cubefs-img-files/

mv ../cubefs-img-files ./

#rev=2.4.0
rev=3.2.0
nohup docker build ./ --progress=plain --build-arg rev="${rev}" -t harbor.my.org:1080/chenseanxy/hadoop-ubussh-cubefs:3.2.1-nolib > build-Dockerfile-hadoop-ubussh-cubefs.log 2>&1 &
tail -f build-Dockerfile-hadoop-ubussh-cubefs.log
#docker build ./ --progress=plain --build-arg rev="${rev}" -t harbor.my.org:1080/chenseanxy/hadoop-ubussh-cubefs:3.2.1-nolib
docker push harbor.my.org:1080/chenseanxy/hadoop-ubussh-cubefs:3.2.1-nolib
ansible all -m shell -a"crictl images|grep hadoop-ubussh-cubefs"
ansible all -m shell -a"crictl images|grep hadoop-ubussh-cubefs|awk '{print \$3}'|xargs crictl rmi"

docker run --privileged --name cubefs-hadoop-client -it --rm -v /Volumes/data/workspace:/root/workspace harbor.my.org:1080/chenseanxy/hadoop-ubussh-cubefs:3.2.1-nolib /bin/bash

mv ./cubefs-img-files ../

git clone https://github.com/cubefs/cubefs-helm
cd cubefs-helm/cubefs
cp ~/.kube/config config/kubeconfig

kubectl label node dtpct component.cubefs.io/master=enabled
kubectl label node mdlapubu component.cubefs.io/master=enabled
kubectl label node mdubu component.cubefs.io/master=enabled

kubectl label node dtpct component.cubefs.io/metanode=enabled
kubectl label node mdlapubu component.cubefs.io/metanode=enabled
kubectl label node mdubu component.cubefs.io/metanode=enabled

kubectl label node dtpct component.cubefs.io/datanode=enabled
kubectl label node mdlapubu component.cubefs.io/datanode=enabled
kubectl label node mdubu component.cubefs.io/datanode=enabled

kubectl label node dtpct component.cubefs.io/objectnode=enabled
kubectl label node mdlapubu component.cubefs.io/objectnode=enabled
kubectl label node mdubu component.cubefs.io/objectnode=enabled

kubectl label node dtpct cubefs-csi-node=enabled
kubectl label node mdlapubu cubefs-csi-node=enabled
kubectl label node mdubu cubefs-csi-node=enabled

#每个数据节点节点
lsblk
umount -l /dev/sdb5
mkfs.xfs -f /dev/sdb5
mkdir /data0
mount /dev/sdb5 /data0
ls -l /dev/disk/by-uuid/
mount|grep data0
#/etc/fstab增加挂载
#/dev/disk/by-uuid/0f57c0db-9adc-4ae9-8348-3bba4d5579eb /data0 xfs defaults 0 1

kubectl create ns cubefs
cp ../../values.yaml ./
ansible all -m shell -a"mkdir /data0/cubefs"
helm install my ./ -n cubefs
helm uninstall my -n cubefs
ansible all -m shell -a"rm -rf /data0/cubefs"
ansible all -m shell -a"mkdir -p /data0/cubefs/path"
ansible all -m shell -a"mkdir -p /data0/cubefs/data"

watch kubectl get all -n cubefs

docker save -o quay.io_k8scsi_csi-node-driver-registrar_v1.3.0.tar.gz quay.io/k8scsi/csi-node-driver-registrar:v1.3.0
docker load -i quay.io_k8scsi_csi-node-driver-registrar_v1.3.0.tar.gz

#command: ["/bin/bash", "-ce", "tail -f /dev/null"]
kubectl edit deployment client -n cubefs
kubectl exec -it client-78b5b5c497-zbdf4 /bin/bash -n cubefs
#--password hdfs --access-key=hdfs --secret-key=12345678
kubectl exec -it -n hadoop my-hadoop-yarn-rm-0 -- /bin/bash
  /cfs/bin/cfs-cli config set --addr master-service.cubefs:17010
  /cfs/bin/cfs-cli user create hdfs -y
:<<EOF
    Access Key : 7QvXDdpBczgTwZt3
    Secret Key : SFXxvPnmO5eDfsHNirtdJ6bvwBwwwrxT
EOF
  #curl -v "http://master-0.master-service.cubefs:17010/admin/createVol?name=hdfs&capacity=100&owner=hdfs&mpCount=3"
  cfs-cli volume create hdfs

/cfs/bin/start.sh
/cfs/bin/cfs-client -f -c /cfs/conf/fuse.json
tail -f /cfs/logs/client/output.log
:<<\EOF
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - preference:
              matchExpressions:
              - key: kubernetes.io/hostname
                operator: In
                values:
                - mdubu
            weight: 1
#      containers:
#        - name: client-pod
EOF

curl -v "http://master-0.master-service:17010/admin/createVol?name=test&capacity=100&owner=cfs&mpCount=3"

