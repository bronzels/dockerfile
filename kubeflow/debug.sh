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
cd kubeflow-manifest-mirror
kubectl apply -f ./patch/knative_serving_releases_download_v0.17.1_serving-crds.yaml
while ! kustomize build example | kubectl apply -f -; do echo "Retrying to apply resources"; sleep 10; done
