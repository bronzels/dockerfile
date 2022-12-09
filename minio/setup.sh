#参考文章kubectl get all -n minio-tenant-1  
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

Current JWT to login: eyJhbGciOiJSUzI1NiIsImtpZCI6InRRTmNzY2h6TmRRQmUtaHNETzhmaE4tcHlwYXY4TzJYRmEwQnhMWG1DZ1UifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJtaW5pby1vcGVyYXRvciIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJjb25zb2xlLXNhLXRva2VuLThtOGdrIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImNvbnNvbGUtc2EiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiJmMWUwMDY5OC01MGJkLTQ5YjQtODA0Ny1iODU3NjM2MzRmMTIiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6bWluaW8tb3BlcmF0b3I6Y29uc29sZS1zYSJ9.LMpWoTt_LIokdrv5Nb4rOy5xPhxyQsKWsmYBgoiwntUv3ftW0jwBc19HEurv0Ezh4XSiniMHsNmMljlbM_962lQDBh5MU1w5lHYKB4UMme2CPl844gHhYgOdXCo5dZSJPbYnFR6lv1Cj-7ocMN0qtrcbICoCvcaaL7Q5iscO8a-xTp8yJWqlj1nqu-jZJobvXxvtA2x8mDg9QYSi5oZ4LK-7-tg5W4L98OT6PVWwk-T9oZTZWg7atfExUkbGIEyOfkFMDbjfwIWvHaLbRWNr-M3Z9bnGa_G8vHR-CDGaqSa9cVabLaEq9fgbXCRdU703QGujX82Rr3euZCuHWUZXeg

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
kubectl minio tenant create minio-tenant-1  \
  --servers 3 \
  --volumes 12 \
  --capacity 240Gi \
  --storage-class  minio-local-storage \
  --namespace minio-tenant-1 \
  --image registry.cn-hangzhou.aliyuncs.com/bronzels/minio-minio-release-2022-10-29:1.0
#  --image registry.cn-hangzhou.aliyuncs.com/bronzels/minio-minio2022-04-16:1.0
:<<EOF
Tenant 'minio-tenant-1' created in 'minio-tenant-1' Namespace

  Username: WS26W3ADFQ0G95MSS29F
  Password: ZycLlyACsr7pVSsmcGL8AsNGnr1TWg21T6o18i8q
  Note: Copy the credentials to a secure location. MinIO will not display these again.

APPLICATION	SERVICE NAME          	NAMESPACE     	SERVICE TYPE	SERVICE PORT
MinIO      	minio                 	minio-tenant-1	ClusterIP   	443
Console    	minio-tenant-1-console	minio-tenant-1	ClusterIP   	9443
EOF

wget -c https://dl.min.io/server/minio/release/linux-amd64/minio
chmod +x minio
wget -c https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x minio

kubectl get all -n minio-tenant-1
kubectl get pvc -n minio-tenant-1

kubectl port-forward -n minio-tenant-1 svc/minio-tenant-1-console 9443:9443 &
kubectl port-forward -n minio-tenant-1 svc/minio 1443:443 &
mc config host add minio http://localhost:1443 QR9RXSLIPZCLQCHB240V ThPMZakACdQ42AU4a8A3HgGJAotvm148hW4jpv4m

kubectl minio tenant delete minio-tenant-1 --namespace minio-tenant-1

kubectl delete pvc --all -n minio-tenant-1
#pv没有ns，小心删除其他应用的pv
kubectl get pv -n hadoop | grep minio | awk '{print $1}' | xargs kubectl delete pv

kubectl delete ns minio-tenant-1

#test

