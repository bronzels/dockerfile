helm repo add stable https://charts.helm.sh/stable
helm repo update
kubectl create ns redis
helm install my stable/redis-ha --set persistentVolume.storageClass=nfs-client -n redis
helm uninstall my -n redis
kubectl get pvc -n redis | grep redis | awk '{print $1}' | xargs kubectl delete pvc -n redis
:<<EOF
WARNING: This chart is deprecated
NAME: my
LAST DEPLOYED: Thu Nov 10 14:47:27 2022
NAMESPACE: redis
STATUS: deployed
REVISION: 1
NOTES:
Redis can be accessed via port 6379 and Sentinel can be accessed via port 26379 on the following DNS name from within your cluster:
my-redis-ha.redis.svc.cluster.local

To connect to your Redis server:
1. Run a Redis pod that you can use as a client:

   kubectl exec -it my-redis-ha-server-0 sh -n redis

2. Connect using the Redis CLI:

  redis-cli -h my-redis-ha.redis.svc.cluster.local
EOF
kubectl get all -n redis

kubectl port-forward -n redis svc/my-redis-ha 6379:6379 &
