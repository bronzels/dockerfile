if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Mac detected."
    #mac
    MYHOME=/Volumes/data
    BININSTALLED=/Users/apple/bin
    os=darwin
    SED=gsed
else
    echo "Assuming linux by default."
    #linux
    MYHOME=~
    BININSTALLED=~/bin
    os=linux
    SED=sed
fi

CUBEHOME=${MYHOME}/workspace/dockerfile/kubeflow

sudo curl -Lo ./kustomize https://github.com/kubernetes-sigs/kustomize/releases/download/v3.2.0/kustomize_3.2.0_${os}_amd64
sudo chmod +x ./kustomize
#sudo wget -c https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv3.10.0/kustomize_v3.10.0_linux_amd64.tar.gz
#sudo tar xzvf kustomize_v3.10.0_linux_amd64.tar.gz
sudo mv kustomize ${BININSTALLED}

kubectl patch storageclass cfs-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

rev=1.6.1
wget -c https://github.com/kubeflow/manifests/archive/refs/tags/v${rev}.tar.gz
tar xzvf v${rev}.tar.gz
ln -s manifests-${rev} manifests