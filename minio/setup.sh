#参考文章kubectl get all -n minio-tenant-1
#linux
rm -f kubectl-minio
wget -c https://github.com/minio/operator/releases/download/v4.5.4/kubectl-minio_4.5.4_linux_amd64 -O kubectl-minio
#mac
rm -f kubectl-minio
wget -c https://github.com/minio/operator/releases/download/v4.5.4/kubectl-minio_4.5.4_darwin_amd64 -O kubectl-minio
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

Current JWT to login: eyJhbGciOiJSUzI1NiIsImtpZCI6IjVxTUNjc2MxMTJsVUdEX3V0WTVsd3BDcVZSLWJoYnhlV29vQ0E2SVNBWjQifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJtaW5pby1vcGVyYXRvciIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJjb25zb2xlLXNhLXNlY3JldCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJjb25zb2xlLXNhIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQudWlkIjoiY2ZkYTYyNzUtM2E5ZC00ZGNiLTljYjItMjcwY2RhY2RlYjRjIiwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50Om1pbmlvLW9wZXJhdG9yOmNvbnNvbGUtc2EifQ.Ft59XCR8NLowhMguyrtgie3aJz-KVt-RzW2uh-Ar8dsNbrFBn39IAX_KBJ_HBuf6IdriSI40ULXdnSUQb8zfgJA-GPB5uWcu-bR76V92zS9Yek_AucjXQymhD_UXy-btvDVkKB4CEUNJWBmfsnGzxyQoFLvUhId_fp9IehH_4vdfr_6wHYh1zOdaX-9I0R_SnsUKn8QHAA3wIvxaPb1QoRH9OTX6Pl0LqtTX3252sOjSDCkWjGTKBnfyIS5aFtzC44iblyvNMnmNgXrToqN4RRdbzZ9PD8-BMejmfhgZAmTnEyv0cclYG__TWCp-OTiRpwo1ocm6yJnacL7xOlY1HA

EOF

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

ansible all -m shell -a"rm -rf /data0/minio"
ansible all -m shell -a"mkdir -p /data0/minio/pv1"
ansible all -m shell -a"mkdir -p /data0/minio/pv2"
ansible all -m shell -a"mkdir -p /data0/minio/pv3"
ansible all -m shell -a"mkdir -p /data0/minio/pv4"
cat << \EOF > minio-pv-template.yaml
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
cat << \EOF > minio-pv5g-template.yaml
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

ansible all -m shell -a"ls /data0/minio/"

kubectl apply -f pvs/
kubectl delete -f pvs/
kubectl get pv | grep minio

kubectl create ns minio-tenant-1
#  --storage-class  minio-local-storage \
kubectl minio tenant create minio-tenant-1  \
  --servers 3 \
  --volumes 12 \
  --capacity 240Gi \
  --storage-class  local-path \
  --namespace minio-tenant-1 \
  --enable-audit-logs=false \
  --enable-prometheus=false \
  --image registry.cn-hangzhou.aliyuncs.com/bronzels/minio-minio-release-2022-10-29:1.0
#  --image registry.cn-hangzhou.aliyuncs.com/bronzels/minio-minio2022-04-16:1.0
:<<EOF
W0414 10:48:58.168858   15937 warnings.go:70] unknown field "spec.pools[0].volumeClaimTemplate.metadata.creationTimestamp"

Tenant 'minio-tenant-1' created in 'minio-tenant-1' Namespace

  Username: 8UO66W6IHMOVQ3377AVN 
  Password: RtiK0qLDMjzLHKhMIk3NHqsblQjMijF23AKDUltw 
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

