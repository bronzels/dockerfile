helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
kubectl create ns redis
helm install my bitnami/redis \
  --set global.storageClass=nfs-client \
  --set global.redis.password=redis \
  --set image.registry=registry.cn-shanghai.aliyuncs.com \
  --set image.repository=wanfei/redis \
  --set architecture=standalone \
  --version 16.5.5 \
  -n redis
helm uninstall my -n redis
kubectl get pvc -n redis | grep redis | awk '{print $1}' | xargs kubectl delete pvc -n redis
:<<EOF
NAME: my
LAST DEPLOYED: Sun Dec 11 18:43:04 2022
NAMESPACE: redis
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: redis
CHART VERSION: 16.5.5
APP VERSION: 6.2.6

** Please be patient while the chart is being deployed **

Redis&trade; can be accessed via port 6379 on the following DNS name from within your cluster:

    my-redis-master.redis.svc.cluster.local



To get your password run:

    export REDIS_PASSWORD=$(kubectl get secret --namespace redis my-redis -o jsonpath="{.data.redis-password}" | base64 --decode)

To connect to your Redis&trade; server:

1. Run a Redis&trade; pod that you can use as a client:

   kubectl run --namespace redis redis-client --restart='Never'  --env REDIS_PASSWORD=$REDIS_PASSWORD  --image registry.cn-shanghai.aliyuncs.com/wanfei/redis:6.2.6-debian-10-r158 --command -- sleep infinity

   Use the following command to attach to the pod:

   kubectl exec --tty -i redis-client \
   --namespace redis -- bash

2. Connect using the Redis&trade; CLI:
   REDISCLI_AUTH="$REDIS_PASSWORD" redis-cli -h my-redis-master

To connect to your database from outside the cluster execute the following commands:

    kubectl port-forward --namespace redis svc/my-redis-master : &
    REDISCLI_AUTH="$REDIS_PASSWORD" redis-cli -h 127.0.0.1 -p
EOF
watch kubectl get all -n redis

#kubectl port-forward -n redis svc/my-redis-ha 6379:6379 &
kubectl port-forward -n redis svc/my-redis-master 6379:6379 &

