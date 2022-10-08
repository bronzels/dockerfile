sudo curl -Lo ./kustomize https://github.com/kubernetes-sigs/kustomize/releases/download/v3.2.0/kustomize_3.2.0_linux_amd64
sudo chmod +x ./kustomize
#sudo wget -c https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv3.10.0/kustomize_v3.10.0_linux_amd64.tar.gz
#sudo tar xzvf kustomize_v3.10.0_linux_amd64.tar.gz
sudo mv kustomize /usr/local/bin

git clone https://github.com/rancher/local-path-provisioner.git
cd local-path-provisioner
#在所有工作节点主机，创建文件路径，替换缺省目录成数据盘相应目录
grep "paths" deploy/local-path-storage.yaml
sudo mkdir -p /opt/local-path-provisioner
sudo chmod 777 /opt/local-path-provisioner
#发布local-path-storage
kubectl apply -f deploy/local-path-storage.yaml -n local-path-storage
kubectl get pods -n local-path-storage
kubectl get storageclass
#设置为default的storageclass
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.beta.kubernetes.io/is-default-class":"true"}}}'
kubectl get storageclass
#卸载
#kubectl delete -f local-path-provisioner/deploy/local-path-storage.yaml
mkdir test
cd test
cat << \EOF > pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: local-path-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 50Mi
EOF
kubectl apply -f pvc.yaml
kubectl get pvc -A
cat << \EOF > pvc-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: volume-test
  namespace: default
spec:
  containers:
  - name: volume-test
    image: nginx:1.18-alpine
    imagePullPolicy: IfNotPresent
    volumeMounts:
    - name: volv
      mountPath: /data
    ports:
    - containerPort: 80
  volumes:
  - name: volv
    persistentVolumeClaim:
      claimName: local-path-pvc
EOF
kubectl apply -f pvc-pod.yaml
kubectl get pv -A

#1，在pod中写入文件
kubectl get pods volume-test -o jsonpath={.spec.containers[*].name}
kubectl exec -it volume-test -c volume-test /bin/sh
:<<\EOF
#cd data
/data # echo "hello, local PV" > pvc-test
/data # cat pvc-test
hello, local PV
EOF
#2，在local PV查看是否同样有此文件
kubectl get pod -o wide
#在pod所在node上
cd /opt/local-path-provisioner/pvc-9f6f7735-17dd-42ee-b831-99faa3d56295_default_local-path-pvc/
cat pvc-test

:<<\EOF
#不好解决gcr下载问题
#总有knative相关yaml错误，不确定knative对应的版本，不知道哪里去下载“patch”的yaml
#git clone https://github.com/shikanon/kubeflow-manifests.git
wget -c https://github.com/kubeflow/manifests/archive/refs/tags/v1.6.0.tar.gz
tar xzvf Downloads/v1.6.0.tar.gz
ln -s manifests-1.6.0 manifests
cd manifests
EOF
:<<\EOF
kustomize build example |grep 'image: gcr.io'|awk '$2 != "" { print $2}' |sort -u
kustomize build example |grep 'image: quay.io'|awk '$2 != "" { print $2}' |sort -u
cd ..
git clone https://github.com/kenwoodjw/sync_gcr.git
cd sync_gcr
#把以上gcr.io和quay.io的image
EOF
:<<\EOF
find ./ -name "*.py" | xargs grep "docker.io/" | awk -F: '$1 != "" { print $1}' | xargs sed -i 's#docker.io/##g'
#find ./ -name "*.py" | xargs grep "quay.io/" | awk -F: '$1 != "" { print $1}' | xargs sed -i 's#quay.io/##g'
find ./ -name "*.yaml" | xargs grep "docker.io/" | awk -F: '$1 != "" { print $1}' | xargs sed -i 's#docker.io/##g'
find ./ -name "*.yaml" | xargs grep "quay.io/" | awk -F: '$1 != "" { print $1}' | xargs sed -i 's#quay.io/##g'
#报错
EOF
git clone https://github.com/jiaozhentian/kubeflow-manifest-mirror.git
cd jiaozhentian/kubeflow-manifest-mirror
kubectl apply -f ./patch/knative_serving_releases_download_v0.17.1_serving-crds.yaml
while ! kustomize build example | kubectl apply -f -; do echo "Retrying to apply resources"; sleep 10; done
