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
[1] 17215
localhost:minio apple$ Starting port forward of the Console UI.

To connect open a browser and go to http://localhost:9090

Current JWT to login: eyJhbGciOiJSUzI1NiIsImtpZCI6InZlR3JYQUVVaGFFYko2Uno1VWFXeHZPY1RSTmlUb1NkUldMTzNnZ1dsOFkifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJtaW5pby1vcGVyYXRvciIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJjb25zb2xlLXNhLXRva2VuLWQ5N3ZnIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImNvbnNvbGUtc2EiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiI0MDFlNzNkOC0wZjM2LTQyOTktOGIxNy1lYjFiNDNhMjNlNGEiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6bWluaW8tb3BlcmF0b3I6Y29uc29sZS1zYSJ9.SISJdmO80JXgu2XwQs3atN4WOCCJNK1Z6yqmOvyGmg52pLUOVBPGEpQUfUxwGpH4jKbMIso2uNuRoZX9qdmUyl1Dv-q_RXV9_tCiAIz5nkliU4ez4si8rLsxF-PnwLm15r3ljK1rPB2jfsIYzCRbN0W16lQ9K2RkZz_47xJLfBSXSJXalFPjS9U-bDKp3Uk6irqF6tKqZ5XtbotESuDlkUZ0r0T02UQORSd2XSALbznd8eN26lpEiqsx2VVHwlvZzPlYJW-JwvYv5mIK5XgmE6vmgMkgWQn82r2iObqbfdcwJkEMfOLklP_r8QbutW4dd_XbDM32dMMWrKmxs3MPXQ

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

ansible all -m shell -a"rm -rf /data0/minio"
ansible all -m shell -a"mkdir -p /data0/minio/pv1"
ansible all -m shell -a"mkdir -p /data0/minio/pv2"
ansible all -m shell -a"mkdir -p /data0/minio/pv3"
ansible all -m shell -a"mkdir -p /data0/minio/pv4"

mkdir pvs
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

sudo ssh dtpct mkdir -p /data0/minio/pvlog
cat << \EOF > minio-pv-log.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
   name: dtpct-minio-pvlog
   labels:
     app: minio
spec:
   capacity:
      storage: "5368709120"
   volumeMode: Filesystem
   accessModes:
   - ReadWriteOnce
   persistentVolumeReclaimPolicy: Retain
   local:
      path: /data0/minio/pvlog
   nodeAffinity:
      required:
         nodeSelectorTerms:
         - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
              - dtpct
EOF
kubectl apply -f minio-pv-log.yaml
kubectl delete -f minio-pv-log.yaml

sudo ssh dtpct mkdir -p /data0/minio/pvprom
cat << \EOF > minio-pv-prom.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
   name: dtpct-minio-pvprom
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
      path: /data0/minio/pvprom
   nodeAffinity:
      required:
         nodeSelectorTerms:
         - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
              - dtpct
EOF
kubectl apply -f minio-pv-prom.yaml
kubectl delete -f minio-pv-prom.yaml

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

kubectl apply -f pvs/
kubectl delete -f pvs/
ansible all -m shell -a"ls /data0/minio/"
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

  Username: QR9RXSLIPZCLQCHB240V
  Password: ThPMZakACdQ42AU4a8A3HgGJAotvm148hW4jpv4m
  Note: Copy the credentials to a secure location. MinIO will not display these again.

APPLICATION	SERVICE NAME          	NAMESPACE     	SERVICE TYPE	SERVICE PORT
MinIO      	minio                 	minio-tenant-1	ClusterIP   	443
Console    	minio-tenant-1-console	minio-tenant-1	ClusterIP   	9443
EOF

kubectl get all -n minio-tenant-1
kubectl get pvc -n minio-tenant-1

kubectl port-forward -n minio-tenant-1 svc/minio-tenant-1-console 9443:9443 &
kubectl port-forward -n minio-tenant-1 svc/minio 1443:443 &
mc config host add minio http://localhost:1443 HAB5AAOUSN8Q9IYLB8RH 9on6RpakntU9gBvZ4GtZREbjL8T6IgyFDPr0Ofp2

kubectl minio tenant delete minio-tenant-1 --namespace minio-tenant-1

kubectl delete pvc --all -n minio-tenant-1
#pv没有ns，小心删除其他应用的pv
kubectl get pv -n hadoop | grep minio | awk '{print $1}' | xargs kubectl delete pv

kubectl delete ns minio-tenant-1

#test

