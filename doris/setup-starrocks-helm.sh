helm repo add starrocks-community https://starrocks.github.io/starrocks-kubernetes-operator
helm repo update
helm search repo starrocks-community
:<<EOF
NAME                                    CHART VERSION   APP VERSION     DESCRIPTION                                       
starrocks-community/kube-starrocks      1.9.4           3.2-latest      kube-starrocks includes two subcharts, operator...
EOF
while ! helm install starrocks starrocks-community/kube-starrocks \
    --namespace starrocks \
    --create-namespace; do sleep 2 ; done ; echo succeed
:<<EOF
NAME: starrocks
LAST DEPLOYED: Thu Apr 11 22:35:04 2024
NAMESPACE: starrocks
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for installing kube-starrocks-1.9.4 kube-starrocks chart.
It will install both operator and starrocks cluster, please wait for a few minutes for the cluster to be ready.

Please see the values.yaml for more operation information: https://github.com/yandongxiao/starrocks-kubernetes-operator/blob/main/helm-charts/charts/kube-starrocks/values.yaml
succeed
EOF

while ! helm pull starrocks-community/kube-starrocks; do sleep 2 ; done ; echo succeed
tar xzvf kube-starrocks-1.9.4.tgz
cd kube-starrocks
helm install starrocks ./ -n starrocks \
    --set starrocks.initPassword.enabled=true \
    --set starrocks.initPassword.password=root

helm uninstall starrocks -n starrocks
kubectl get pod -n starrocks |grep -v Running |awk '{print $1}'| xargs kubectl delete -n starrocks pod "$1" --force --grace-period=0

kubectl exec -it -n starrocks `kubectl get pod -n starrocks | grep kube-starrocks-fe-0 | grep Running | awk '{print $1}'` -- /bin/bash

kubectl exec -it -n mysql `kubectl get pod -n mysql | grep Running | awk '{print $1}'` -- mysql -h kube-starrocks-fe-service.starrocks -P 9030 -uroot -proot -e"SHOW DATABASES"
