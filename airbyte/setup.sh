if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Mac detected."
    #mac
    os=darwin
    MYHOME=/Volumes/data
    SED=gsed
    bin=/Users/apple/bin
else
    echo "Assuming linux by default."
    #linux
    os=linux
    MYHOME=~
    SED=sed
    bin=/usr/local/bin
fi

AIRBYTE_HOME=${MYHOME}/workspace/dockerfile/airbyte

cd ${AIRBYTE_HOME}

kubectl create ns airbyte

helm repo add airbyte https://airbytehq.github.io/helm-charts
helm repo update
helm search repo airbyte
:<<EOF
NAME                                    CHART VERSION   APP VERSION     DESCRIPTION                                       
airbyte/airbyte                         0.64.81         0.57.2          Helm chart to deploy airbyte
EOF
while ! helm install airbyte airbyte/airbyte \
    --namespace airbyte \
    --create-namespace \
    --set global.storage.type=minio-sc; do sleep 2 ; done ; echo succeed
:<<EOF
EOF
while ! helm pull airbyte/airbyte; do sleep 2 ; done ; echo succeed
#webapp因为k8s集群宿主机禁用ipv6，需要修改nginx配置文件
docker run -it --name airbyte-webapp --rm airbyte/webapp:0.57.2 cat /etc/nginx/templates/default.conf.template > default.conf.template
file=default.conf.template
cp ${file} ${file}.bak
$SED -i '/    listen  \[::\]:8080;/d' ${file}
$SED -i 's@    server_name  localhost;@    server_name  localhost mmubu; @g' ${file}
chmod 777 default.conf.template
docker build ./ -t harbor.my.org:1080/integrate/airbyte-webapp:0.57.2
docker push harbor.my.org:1080/integrate/airbyte-webapp:0.57.2
ansible all -m shell -a"docker rmi harbor.my.org:1080/integrate/airbyte-webapp:0.57.2"
kubectl get pod -n airbyte |grep airbyte-webapp |awk '{print $1}'| xargs kubectl delete pod -n airbyte "$1" --force --grace-period=0
kubectl exec -n airbyte `kubectl get pod -n airbyte |grep airbyte-webapp |awk '{print $1}'` -- cat /etc/nginx/templates/default.conf.template
kubectl exec -n airbyte `kubectl get pod -n airbyte |grep airbyte-webapp |awk '{print $1}'` -- cat /etc/nginx/conf.d/default.conf
kubectl logs -n airbyte `kubectl get pod -n airbyte |grep airbyte-webapp |awk '{print $1}'` 
file=airbyte/values.yaml
cp ${file} ${file}.bak
:<<EOF
webapp:
  image:
    repository: airbyte/webapp
  service:
    type: ClusterIP
  ->
webapp:
  image:
    repository: harbor.my.org:1080/integrate/airbyte-webapp
  service:
    type: NodePort
    nodePort: 30080
EOF
cd airbyte
\cp ../values.yaml ./
helm install airbyte ./ \
    --namespace airbyte \
    --create-namespace
:<<EOF
NAME: airbyte
LAST DEPLOYED: Mon Apr 15 10:05:09 2024
NAMESPACE: airbyte
STATUS: deployed
REVISION: 1
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace airbyte -l "app.kubernetes.io/name=webapp" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace airbyte $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace airbyte port-forward $POD_NAME 8080:$CONTAINER_PORT
EOF

helm uninstall airbyte -n airbyte
#没有卸载干净，需要手工删除
kubectl delete statefulset.apps airbyte-db -n airbyte
kubectl delete  statefulset.apps airbyte-minio -n airbyte
kubectl delete  service airbyte-db-svc -n airbyte
kubectl delete  service airbyte-minio-svc -n airbyte
kubectl delete  pod airbyte-airbyte-bootloader -n airbyte
kubectl get pod -n airbyte |grep -v Running |awk '{print $1}'| xargs kubectl delete -n airbyte pod "$1" --force --grace-period=0
kubectl get pod -n airbyte |grep Completed |awk '{print $1}'| xargs kubectl delete -n airbyte pod "$1" --force --grace-period=0
kubectl get pvc -n airbyte |awk '{print $1}'| xargs kubectl delete pvc "$1" -n airbyte
kubectl get all -n airbyte
kubectl get pvc -n airbyte
#kubectl exec -it  `kubectl get pod -n airbyte |grep Running |grep airbyte-server- |awk '{print $1}'` -n airbyte -- /bin/bash
#kubectl exec -it  `kubectl get pod -n airbyte |grep Running |grep airbyte-airbyte-api-server |awk '{print $1}'` -n airbyte -- /bin/bash
#kubectl exec -it  `kubectl get pod -n airbyte |grep Running |grep airbyte-worker- |awk '{print $1}'` -n airbyte -- /bin/bash
