#参考文章kubectl get all -n minio-tenant-1

MINIO_OP_VERSION=4.5.4
#MINIO_OP_VERSION=5.0.14
#linux
rm -f kubectl-minio
wget -c https://github.com/minio/operator/releases/download/v${MINIO_OP_VERSION}/kubectl-minio_${MINIO_OP_VERSION}_linux_amd64 -O kubectl-minio
#mac
rm -f kubectl-minio
wget -c https://github.com/minio/operator/releases/download/v${MINIO_OP_VERSION}/kubectl-minio_${MINIO_OP_VERSION}_darwin_amd64 -O kubectl-minio
chmod +x kubectl-minio
mv kubectl-minio /usr/local/bin/

kubectl minio version

kubectl minio init

kubectl get all -n minio-operator

kubectl minio proxy -n minio-operator &
:<<EOF
[1] 19298
localhost:minio apple$ Starting port forward of the Console UI.

To connect open a browser and go to http://localhost:9090

Current JWT to login: eyJhbGciOiJSUzI1NiIsImtpZCI6IjdTUlMzQUhzUFJrM200MWNPLXY4RDNVZzRXcDUxZXBZOVhmZzdmTnBvSkUifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJtaW5pby1vcGVyYXRvciIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJjb25zb2xlLXNhLXRva2VuLXA2ZHA4Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImNvbnNvbGUtc2EiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiI3MGZhMTAyNS1jZjBhLTRmNDYtYWY0Yy0zMGYyMTU0YTUyZjkiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6bWluaW8tb3BlcmF0b3I6Y29uc29sZS1zYSJ9.N7jS7BOQq_-8vMAcsdq_A1m1gpl8PX5bJ8rIJ8JSoasxBor9SXpe5Mje3TcCjrWhQKW2InCHiR2_TOfCq4-iZkFhBBwROA7XMzR2D_1B-yG2KfI_I97D9_xtSo_vjS7qa9mjMSh1GI7t6yJ6qqNtK8v0a5VfEQIqgsUOKfjCeGgYXxO49Ju3xN0JIXiFduVfZpv5xpIuRq75qPCNsNW2XDQRLUcvF7dZqRWiCb6NJGvqc6K9LGm5Q4R7xYw3lLSVTznsxT2D4lZgSn_h8e_TmPOyHtWeddeS4LKbGUCut0WBLyBvp2k8v7YZjVssSekSDXplNQGPMK9PLkdP4rlWTQ

EOF

kubectl minio delete


kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
   name: minio-local-storage
provisioner: kubernetes.io/no-provisioner
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
EOF
kubectl get sc

mkdir pvs

#local-path和 minio-local-storage作用一样
:<<EOF
ansible all -m shell -a"rm -rf /data0/minio"
ansible all -m shell -a"mkdir -p /data0/minio/pv1"
ansible all -m shell -a"mkdir -p /data0/minio/pv2"
ansible all -m shell -a"mkdir -p /data0/minio/pv3"
ansible all -m shell -a"mkdir -p /data0/minio/pv4"
EOF

cat << EOF > minio-pv-template.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
   name: myhost-minio-mypv
   labels:
     app: minio
spec:
   capacity:
      storage: 20Gi
   volumeMode: Filesystem
   accessModes:
   - ReadWriteOnce
   persistentVolumeReclaimPolicy: Retain
   storageClassName: minio-local-storage
   local:
      path: /data0/minio/mypv
   nodeAffinity:
      required:
         nodeSelectorTerms:
         - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
              - myhost
EOF
for myhost in {dtpct,mdubu,mdlapubu}
do
  echo "myhost:${myhost}"
  for num in {1..4}
  do
    mypv="pv${num}"
    echo "mypv:${mypv}"
    file=minio-pv-${myhost}-${num}.yaml
    echo "file:${file}"
    cp minio-pv-template.yaml pvs/${file}
    sed -i "" "s/myhost/${myhost}/g" pvs/${file}
    sed -i "" "s/mypv/${mypv}/g" pvs/${file}
    cat pvs/${file}
  done
done

#log不知道怎么删除，会空间远超数据目录，引起节点disk pressure被evicted
sudo ssh dtpct mkdir -p /data0/minio/pv5g1
sudo ssh dtpct mkdir -p /data0/minio/pv5g2
cat << EOF > minio-pv5g-template.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
   name: dtpct-minio-mypv
   labels:
     app: minio
spec:
   capacity:
      storage: 5Gi
   volumeMode: Filesystem
   accessModes:
   - ReadWriteOnce
   persistentVolumeReclaimPolicy: Retain
   local:
      path: /data0/minio/mypv
   nodeAffinity:
      required:
         nodeSelectorTerms:
         - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
              - dtpct
EOF
for num in {1..2}
do
  mypv="pv5g${num}"
  echo "mypv:${mypv}"
  file=minio-pv5g-${num}.yaml
  echo "file:${file}"
  cp minio-pv5g-template.yaml pvs/${file}
  sed -i "" "s/mypv/${mypv}/g" pvs/${file}
  cat pvs/${file}
done

#local-path和 minio-local-storage作用一样
:<<EOF
ansible all -m shell -a"ls /data0/minio/"

kubectl apply -f pvs/
kubectl delete -f pvs/
EOF

kubectl get pv | grep minio

kubectl create ns minio-tenant-1
#local-path和 minio-local-storage作用一样
#  --storage-class  minio-local-storage \
#最新版本不支持
#  --enable-audit-logs=false \
#  --enable-prometheus=false
kubectl minio tenant create minio-tenant-1  \
  --servers 3 \
  --volumes 12 \
  --capacity 240Gi \
  --storage-class  local-path \
  --namespace minio-tenant-1
# 指定image会造成tenent通信错误
#  --image registry.cn-hangzhou.aliyuncs.com/bronzels/minio-minio-release-2022-10-29:1.0
#  --image registry.cn-hangzhou.aliyuncs.com/bronzels/minio-minio2022-04-16:1.0
:<<EOF
W0414 10:48:58.168858   15937 warnings.go:70] unknown field "spec.pools[0].volumeClaimTemplate.metadata.creationTimestamp"

Tenant 'minio-tenant-1' created in 'minio-tenant-1' Namespace

  Username: 18RWFEAJ21CRGTVPWHUU 
  Password: Qi7t0WREEXlwdYRFOAebr6VQ4lECBJIFe7gsJcuf 
  Note: Copy the credentials to a secure location. MinIO will not display these again.

APPLICATION	SERVICE NAME          	NAMESPACE     	SERVICE TYPE	SERVICE PORT 
MinIO      	minio                 	minio-tenant-1	ClusterIP   	443         	
Console    	minio-tenant-1-console	minio-tenant-1	ClusterIP   	9443        	
EOF

wget -c https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc

watch kubectl get all -n minio-tenant-1
kubectl get pvc -n minio-tenant-1

kubectl port-forward -n minio-tenant-1 svc/minio-tenant-1-console 9443:9443 &
#kubectl port-forward -n minio-tenant-1 svc/minio 1443:443 &

kubectl minio tenant delete minio-tenant-1 --namespace minio-tenant-1

kubectl delete pvc --all -n minio-tenant-1
#pv没有ns，小心删除其他应用的pv
kubectl get pv | grep minio | awk '{print $1}' | xargs kubectl delete pv

kubectl delete ns minio-tenant-1

#test

cat << EOF > minio-sc.yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: minio-sc
provisioner: minio.min.io
parameters:
  serverEndpoint: "http://my-minio-0.my-minio.minio-operator.svc.cluster.local:9000"
  accessKey: "INE1337BT1CWKY1QFCKB"
  secretKey: "1cVBLXO8MCSBgm9V0JGIDp7BPQmgcx3qUtbBhjMi"
  bucket: "scstorage"
  region: "us-east-1"
EOF

kubectl apply -f minio-sc.yaml

kubectl run distfs-test -it --image=harbor.my.org:1080/chenseanxy/hadoop-ubussh-juicefs:3.2.1-nolib --restart=Never --rm -- /bin/bash
#kubectl exec -it distfs-test -- /bin/bash
  mc config host add minio https://minio.minio-tenant-1.svc.cluster.local INE1337BT1CWKY1QFCKB 1cVBLXO8MCSBgm9V0JGIDp7BPQmgcx3qUtbBhjMi
  mc mb minio/scstorage
  mc ls minio/scstorage

