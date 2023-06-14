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

WORK_HOME=${MYHOME}/workspace
PRJ_HOME=${WORK_HOME}/dockerfile

NEBULA_PRJ_HOME=${PRJ_HOME}/nebula

NEBULA_REV=3.4.1
NEBULA_CHART_VERSION=1.4.2

KUBE_VERSION=1.21.14

export PATH=$PATH:${NEBULA_PRJ_HOME}

cd ${NEBULA_PRJ_HOME}

wget -c https://github.com/vesoft-inc/nebula/archive/refs/tags/v${NEBULA_REV}.tar.gz
wget -c https://oss-cdn.nebula-graph.com.cn/package/${NEBULA_REV}/nebula-graph-${NEBULA_REV}.el7.x86_64.tar.gz

tar xzvf v${NEBULA_REV}.tar.gz
tar xzvf nebula-graph-${NEBULA_REV}.el7.x86_64.tar.gz

kubectl create ns nebula

helm repo add nebula-operator https://vesoft-inc.github.io/nebula-operator/charts
helm repo update

ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-kubebuilder-kube-rbac-proxy-v0.8.0:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-kubebuilder-kube-rbac-proxy-v0.8.0:1.0 gcr.io/kubebuilder/kube-rbac-proxy:v0.8.0"

helm pull nebula-operator/nebula-operator --version=${NEBULA_CHART_VERSION}
tar xzvf nebula-operator-${NEBULA_CHART_VERSION}.tgz

helm install my nebula-operator/nebula-operator -n nebula \
    --set image.kubeScheduler.image=k8s.gcr.io/kube-scheduler:v${KUBE_VERSION} \
    --set image.kubeRBACProxy.image=registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-kubebuilder-kube-rbac-proxy-v0.8.0:1.0 \
    --version=${NEBULA_CHART_VERSION}
:<<EOF
NAME: my
LAST DEPLOYED: Thu Apr  6 20:00:01 2023
NAMESPACE: nebula
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Nebula Operator installed!
EOF
helm uninstall my -n nebula
kubectl get pod -n nebula |grep -v Running |awk '{print $1}'| xargs kubectl delete pod "$1" -n nebula --force --grace-period=0

kubectl get all -n nebula
watch kubectl get all -n nebula

wget -c https://github.com/vesoft-inc/nebula-operator/archive/refs/tags/v${NEBULA_CHART_VERSION}.tar.gz
tar xzvf nebula-operator-1.4.2.tar.gz
file=nebula-operator-1.4.2/config/samples/apps_v1alpha1_nebulacluster.yaml
cp ${file} ${file}.bk
$SED -i 's/storageClassName: ebs-sc/storageClassName: local-path/g' ${file}
kubectl create -n nebula -f nebula-operator-1.4.2/config/samples/apps_v1alpha1_nebulacluster.yaml
kubectl create -n nebula -f nebula-operator-1.4.2/config/samples/graphd-nodeport-service.yaml

kubectl delete -n nebula -f nebula-operator-1.4.2/config/samples/apps_v1alpha1_nebulacluster.yaml
kubectl delete -n nebula -f nebula-operator-1.4.2/config/samples/graphd-nodeport-service.yaml
kubectl get pod -n nebula |grep -v Running |awk '{print $1}'| xargs kubectl delete pod "$1" -n nebula --force --grace-period=0
kubectl get pvc -n nebula | awk '{print $1}' | xargs kubectl delete pvc -n nebula

