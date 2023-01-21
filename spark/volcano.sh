if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Mac detected."
    #mac
    MYHOME=/Volumes/data
    SED=gsed
else
    echo "Assuming linux by default."
    #linux
    MYHOME=~
    SED=sed
fi

rev=1.7.0
wget -c https://github.com/volcano-sh/volcano/archive/refs/tags/v${rev}.tar.gz -O volcano-${rev}.tar.gz
tar xzvf volcano-${rev}.tar.gz

#all k8s working node
ctr -n k8s.io image import /root/volcanosh-vc-webhook-manager-v1.7.0.tar
ctr -n k8s.io image import /root/volcanosh-vc-controller-manager-v1.7.0.tar

kubectl apply -f volcano-1.7.0/installer/volcano-development.yaml
kubectl delete -f volcano-1.7.0/installer/volcano-development.yaml
watch kubectl get all -n volcano-system

kubectl apply -f spark-pi.yaml -n spark-operator
#kubectl delete -f spark-pi.yaml -n spark-operator

kubectl get SparkApplication -n spark-operator

cp app-pi.yaml app-pi-volcano.yaml
$SED -i '/  sparkVersion: "3.3.1"/a\  batchScheduler: "volcano"\' app-pi-volcano.yaml

kubectl apply -f app-pi-nfs-pvc.yaml -n spark-operator
kubectl apply -f app-pi-volcano.yaml -n spark-operator
:<<EOF
kubectl delete -f app-pi-volcano.yaml -n spark-operator
kubectl delete -f app-pi-nfs-pvc.yaml -n spark-operator
EOF
kubectl logs spark-pi-driver -n spark-operator

kubectl get node --no-headers | while read node status; do echo '>>>>  ['$node']'; kubectl describe node $node | grep Resource -A 3 ;done
:<<EOF
>>>>  [dtpct]
  Resource           Requests       Limits
  --------           --------       ------
  cpu                5150m (42%)    5 (41%)
  memory             17392Mi (27%)  42324Mi (66%)
>>>>  [mdlapubu]
  Resource           Requests     Limits
  --------           --------     ------
  cpu                1200m (15%)  4 (50%)
  memory             2Gi (6%)     7Gi (22%)
>>>>  [mdubu]
  Resource           Requests    Limits
  --------           --------    ------
  cpu                400m (5%)   1 (12%)
  memory             968Mi (3%)  1Gi (3%)
EOF

kube-capacity -u -a
:<<EOF
NODE       CPU REQUESTS    CPU LIMITS      CPU UTIL        MEMORY REQUESTS     MEMORY LIMITS      MEMORY UTIL
*          21250m/28000m   18000m/28000m   27454m/28000m   107247Mi/127655Mi   77139Mi/127655Mi   120469Mi/127655Mi
dtpct      6850m/12000m    7000m/12000m    11642m/12000m   46611Mi/64003Mi     21679Mi/64003Mi    60794Mi/64003Mi
mdlapubu   6800m/8000m     4000m/8000m     7925m/8000m     29741Mi/31789Mi     24621Mi/31789Mi    30023Mi/31789Mi
mdubu      7600m/8000m     7000m/8000m     7885m/8000m     30896Mi/31864Mi     30840Mi/31864Mi    29653Mi/31864Mi
EOF

kubectl apply -f volcano-queue-priority.yaml -n spark-operator
kubectl delete -f volcano-queue-priority.yaml -n spark-operator

