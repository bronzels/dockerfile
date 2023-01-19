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

