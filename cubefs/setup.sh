git clone https://github.com/cubefs/cubefs-helm
cd cubefs-helm/chubaofs
cp ~/.kube/config config/kubeconfig

kubectl label node dtpct chubaofs-master=enabled
kubectl label node mdlapubu chubaofs-master=enabled
kubectl label node mdubu chubaofs-master=enabled

kubectl label node dtpct chubaofs-metanode=enabled
kubectl label node mdlapubu chubaofs-metanode=enabled
kubectl label node mdubu chubaofs-metanode=enabled

kubectl label node dtpct chubaofs-datanode=enabled
kubectl label node mdlapubu chubaofs-datanode=enabled
kubectl label node mdubu chubaofs-datanode=enabled

kubectl label node dtpct chubaofs-csi-node=enabled
kubectl label node mdlapubu chubaofs-csi-node=enabled
kubectl label node mdubu chubaofs-csi-node=enabled

kubectl label node dtpct chubaofs-objectnode=enabled
kubectl label node mdlapubu chubaofs-objectnode=enabled
kubectl label node mdubu chubaofs-objectnode=enabled

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

kubectl create ns chubaofs
cp ../../values.yaml ./
helm install chubaofs ./ -n chubaofs
#helm uninstall chubaofs -n chubaofs

kubectl get pod -n chubaofs

docker save -o quay.io_k8scsi_csi-node-driver-registrar_v1.3.0.tar.gz quay.io/k8scsi/csi-node-driver-registrar:v1.3.0
docker load -i quay.io_k8scsi_csi-node-driver-registrar_v1.3.0.tar.gz

#command: ["/bin/bash", "-ce", "tail -f /dev/null"]
kubectl edit deployment client -n chubaofs
kubectl exec -it clientnew-78b5b5c497-zbdf4 /bin/bash -n chubaofs
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


