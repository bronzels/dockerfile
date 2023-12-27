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

PRJ_HOME=${MYHOME}/workspace/dockerfile
KUBEFLOW_PRJ_HOME=${PRJ_HOME}/kubeflow
#MANIFEST_VERSION=1.6.1
#MANIFEST_VERSION=1.7.0
MANIFEST_VERSION=1.8.0

#KUSTOMIZE_VERSION=3.2.0
KUSTOMIZE_VERSION=5.0.1
#1.6.1 README说要用3.2.0版本，可是报错
    #unknown field "$patch" in io.k8s.api.policy.v1.PodDisruptionBudget
#1.6.2不支持k8s 1.18
    #error":"kubernetes version \"1.18.12\" is not compatible, need at least \"1.21.0-0\"

export PATH=$PATH:${PRJ_HOME}

:<<EOF
wget https://github.com/kubernetes-sigs/kustomize/releases/download/v${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_${os}_amd64
mv kustomize_${KUSTOMIZE_VERSION}_${os}_amd64 kustomize
EOF
wget -c https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_${os}_amd64.tar.gz
tar xzvf kustomize_v${KUSTOMIZE_VERSION}_${os}_amd64.tar.gz

chmod +x ./kustomize
mv kustomize ${BININSTALLED}

#kubectl patch storageclass juicefs-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

wget -c https://github.com/kubeflow/manifests/archive/refs/tags/v${MANIFEST_VERSION}.tar.gz
tar xzvf manifests-${MANIFEST_VERSION}.tar.gz
cd ${KUBEFLOW_PRJ_HOME}/manifests-${MANIFEST_VERSION}
find ./ -type file|xargs grep "imagePullPolicy: Always"
find ./ -type file|xargs grep "imagePullPolicy: 'Always'"
find ./ -type file|xargs grep "imagePullPolicy: \"Always\""
find ./ -type file|xargs $SED -i "s/imagePullPolicy: Always/imagePullPolicy: IfNotPresent/g"
find ./ -type file|xargs grep "imagePullPolicy: IfNotPresent"

kustomize build example |grep 'image: '|awk '$2 != "" { print $2}' |sort -u 
kustomize build example |grep 'image: gcr.io'|awk '$2 != "" { print $2}' |sort -u 


#1.6.1
#istio-system                authservice-0
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-arrikto-kubeflow-oidc-authservice-28c59ef:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-arrikto-kubeflow-oidc-authservice-28c59ef:1.0 gcr.io/arrikto/kubeflow/oidc-authservice:28c59ef"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-arrikto-kubeflow-oidc-authservice-28c59ef.tar gcr.io/arrikto/kubeflow/oidc-authservice:28c59ef
#istio-system                istiod-676b666c9d-5vdjg
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-arrikto-istio-pilot-1.14.1-1-g19df463bb:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-arrikto-istio-pilot-1.14.1-1-g19df463bb:1.0 gcr.io/arrikto/istio/pilot:1.14.1-1-g19df463bb"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-arrikto-istio-pilot-1.14.1-1-g19df463bb.tar gcr.io/arrikto/istio/pilot:1.14.1-1-g19df463bb
#knative-eventing            eventing-controller-7468fb4d5b-nsnsb
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-eventing-cmd-controller-sha2:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-eventing-cmd-controller-sha2:1.0 gcr.io/knative-releases/knative.dev/eventing/cmd/controller@sha256:dc0ac2d8f235edb04ec1290721f389d2bc719ab8b6222ee86f17af8d7d2a160f"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-knative-releases-knative.dev-eventing-cmd-controller-sha2.tar gcr.io/knative-releases/knative.dev/eventing/cmd/controller@sha256:dc0ac2d8f235edb04ec1290721f389d2bc719ab8b6222ee86f17af8d7d2a160f
sudo scp dtpct:/root/gcr.io-knative-releases-knative.dev-eventing-cmd-controller-sha2.tar ../kubeflow-imgbk-1.6.1/
#knative-eventing            eventing-webhook-74db54797-crrpg
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-eventing-cmd-webhook-161:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-eventing-cmd-webhook-161:1.0 gcr.io/knative-releases/knative.dev/eventing/cmd/webhook@sha256:b7faf7d253bd256dbe08f1cac084469128989cf39abbe256ecb4e1d4eb085a31"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-knative-releases-knative.dev-eventing-cmd-webhook-161.tar gcr.io/knative-releases/knative.dev/eventing/cmd/webhook@sha256:b7faf7d253bd256dbe08f1cac084469128989cf39abbe256ecb4e1d4eb085a31
sudo scp dtpct:/root/gcr.io-knative-releases-knative.dev-eventing-cmd-webhook-161.tar ../kubeflow-imgbk-1.6.1/
#knative-serving             activator-795b75df55-8thlm
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-serving-cmd-activator-sh-161:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-serving-cmd-activator-sh-161:1.0 gcr.io/knative-releases/knative.dev/serving/cmd/activator@sha256:93ff6e69357785ff97806945b284cbd1d37e50402b876a320645be8877c0d7b7"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-knative-releases-knative.dev-serving-cmd-activator-sh-161.tar gcr.io/knative-releases/knative.dev/serving/cmd/activator@sha256:93ff6e69357785ff97806945b284cbd1d37e50402b876a320645be8877c0d7b7
sudo scp dtpct:/root/gcr.io-knative-releases-knative.dev-serving-cmd-activator-sh-161.tar ../kubeflow-imgbk-1.6.1/
#knative-serving             autoscaler-5979cf9859-tx4v9
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-serving-cmd-autoscaler-s-161:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-serving-cmd-autoscaler-s-161:1.0 gcr.io/knative-releases/knative.dev/serving/cmd/autoscaler@sha256:007820fdb75b60e6fd5a25e65fd6ad9744082a6bf195d72795561c91b425d016"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-knative-releases-knative.dev-serving-cmd-autoscaler-s-161.tar gcr.io/knative-releases/knative.dev/serving/cmd/autoscaler@sha256:007820fdb75b60e6fd5a25e65fd6ad9744082a6bf195d72795561c91b425d016
sudo scp dtpct:/root/gcr.io-knative-releases-knative.dev-serving-cmd-autoscaler-s-161.tar ../kubeflow-imgbk-1.6.1/
#knative-serving             controller-6d59955498-jzpp4
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-serving-cmd-controller-sha25:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-serving-cmd-controller-sha25:1.0 gcr.io/knative-releases/knative.dev/serving/cmd/controller@sha256:75cfdcfa050af9522e798e820ba5483b9093de1ce520207a3fedf112d73a4686"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-knative-releases-knative.dev-serving-cmd-controller-sha25.tar gcr.io/knative-releases/knative.dev/serving/cmd/controller@sha256:75cfdcfa050af9522e798e820ba5483b9093de1ce520207a3fedf112d73a4686
sudo scp dtpct:/root/gcr.io-knative-releases-knative.dev-serving-cmd-controller-sha25.tar ../kubeflow-imgbk-1.6.1/
#knative-serving             domain-mapping-69b875bfc5-t5dlp
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-servingcmddomainmapping-s161:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-servingcmddomainmapping-s161:1.0 gcr.io/knative-releases/knative.dev/serving/cmd/domain-mapping@sha256:23baa19322320f25a462568eded1276601ef67194883db9211e1ea24f21a0beb"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-knative-releases-knative.dev-servingcmddomainmapping-s161.tar gcr.io/knative-releases/knative.dev/serving/cmd/domain-mapping@sha256:23baa19322320f25a462568eded1276601ef67194883db9211e1ea24f21a0beb
sudo scp dtpct:/root/gcr.io-knative-releases-knative.dev-servingcmddomainmapping-s161.tar ../kubeflow-imgbk-1.6.1/
#knative-serving             domainmapping-webhook-5bdf9599db-dvj2n
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knativedevservingcmddomainmappingweb-161:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knativedevservingcmddomainmappingweb-161:1.0 gcr.io/knative-releases/knative.dev/serving/cmd/domain-mapping-webhook@sha256:847bb97e38440c71cb4bcc3e430743e18b328ad1e168b6fca35b10353b9a2c22"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-knative-releases-knativedevservingcmddomainmappingweb-161.tar gcr.io/knative-releases/knative.dev/serving/cmd/domain-mapping-webhook@sha256:847bb97e38440c71cb4bcc3e430743e18b328ad1e168b6fca35b10353b9a2c22
sudo scp dtpct:/root/gcr.io-knative-releases-knativedevservingcmddomainmappingweb-161.tar ../kubeflow-imgbk-1.6.1/
#knative-serving             net-istio-controller-84876567fb-gx2fp
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-netistiocmdcontroller-sh-161:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-netistiocmdcontroller-sh-161:1.0 gcr.io/knative-releases/knative.dev/net-istio/cmd/controller@sha256:f253b82941c2220181cee80d7488fe1cefce9d49ab30bdb54bcb8c76515f7a26"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-knative-releases-knative.dev-netistiocmdcontroller-sh-161.tar gcr.io/knative-releases/knative.dev/net-istio/cmd/controller@sha256:f253b82941c2220181cee80d7488fe1cefce9d49ab30bdb54bcb8c76515f7a26
sudo scp dtpct:/root/gcr.io-knative-releases-knative.dev-netistiocmdcontroller-sh-161.tar ../kubeflow-imgbk-1.6.1/
#knative-serving             net-istio-webhook-7f7b9ffb6d-t6zrr
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-net-istio-cmd-webhook-sh-161:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-net-istio-cmd-webhook-sh-161:1.0 gcr.io/knative-releases/knative.dev/net-istio/cmd/webhook@sha256:a705c1ea8e9e556f860314fe055082fbe3cde6a924c29291955f98d979f8185e"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-knative-releases-knative.dev-net-istio-cmd-webhook-sh-161.tar gcr.io/knative-releases/knative.dev/net-istio/cmd/webhook@sha256:a705c1ea8e9e556f860314fe055082fbe3cde6a924c29291955f98d979f8185e
sudo scp dtpct:/root/gcr.io-knative-releases-knative.dev-net-istio-cmd-webhook-sh-161.tar ../kubeflow-imgbk-1.6.1/
#knative-serving             webhook-54b5d8b5b7-scqws
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-serving-cmd-webhook-sh-161:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-serving-cmd-webhook-sh-161:1.0 gcr.io/knative-releases/knative.dev/serving/cmd/webhook@sha256:9084ea8498eae3c6c4364a397d66516a25e48488f4a9871ef765fa554ba483f0"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-knative-releases-knative.dev-serving-cmd-webhook-sh-161.tar gcr.io/knative-releases/knative.dev/serving/cmd/webhook@sha256:9084ea8498eae3c6c4364a397d66516a25e48488f4a9871ef765fa554ba483f0
sudo scp dtpct:/root/gcr.io-knative-releases-knative.dev-serving-cmd-webhook-sh-161.tar ../kubeflow-imgbk-1.6.1/
#kubeflow-user-example-com   ml-pipeline-ui-artifact-5b7794c7b5-wlxb2
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-frontend-2.0.0-alpha.5:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-frontend-2.0.0-alpha.5:1.0 gcr.io/ml-pipeline/frontend:2.0.0-alpha.5"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-ml-pipeline-frontend-2.0.0-alpha.5.tar gcr.io/ml-pipeline/frontend:2.0.0-alpha.5
sudo scp dtpct:/root/gcr.io-ml-pipeline-frontend-2.0.0-alpha.5.tar ../kubeflow-imgbk-1.6.1/
#
#kubeflow-user-example-com   ml-pipeline-visualizationserver-85c6d6cc9f-qw8j9
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-visualization-server-2.0.0-alpha.5:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-visualization-server-2.0.0-alpha.5:1.0 gcr.io/ml-pipeline/visualization-server:2.0.0-alpha.5"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-ml-pipeline-visualization-server-2.0.0-alpha.5.tar gcr.io/ml-pipeline/visualization-server:2.0.0-alpha.5
sudo scp dtpct:/root/gcr.io-ml-pipeline-visualization-server-2.0.0-alpha.5.tar ../kubeflow-imgbk-1.6.1/
#
#kubeflow                    cache-server-5758c6d574-vt4wk
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-cache-server-2.0.0-alpha.5:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-cache-server-2.0.0-alpha.5:1.0 gcr.io/ml-pipeline/cache-server:2.0.0-alpha.5"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-ml-pipeline-cache-server-2.0.0-alpha.5.tar gcr.io/ml-pipeline/cache-server:2.0.0-alpha.5
sudo scp dtpct:/root/gcr.io-ml-pipeline-cache-server-2.0.0-alpha.5.tar ../kubeflow-imgbk-1.6.1/
#
#kubeflow                    metadata-envoy-deployment-5648f897fc-fbjbl
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-metadata-envoy-2.0.0-alpha.5:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-metadata-envoy-2.0.0-alpha.5:1.0 gcr.io/ml-pipeline/metadata-envoy:2.0.0-alpha.5"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-ml-pipeline-metadata-envoy-2.0.0-alpha.5.tar gcr.io/ml-pipeline/metadata-envoy:2.0.0-alpha.5
sudo scp dtpct:/root/gcr.io-ml-pipeline-metadata-envoy-2.0.0-alpha.5.tar ../kubeflow-imgbk-1.6.1/
#

#kubeflow                    metadata-writer-8bd8b7b66-jmsch
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-metadata-writer-2.0.0-alpha.5:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-metadata-writer-2.0.0-alpha.5:1.0 gcr.io/ml-pipeline/metadata-writer:2.0.0-alpha.5"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-ml-pipeline-metadata-writer-2.0.0-alpha.5.tar gcr.io/ml-pipeline/metadata-writer:2.0.0-alpha.5
sudo scp dtpct:/root/gcr.io-ml-pipeline-metadata-writer-2.0.0-alpha.5.tar ../kubeflow-imgbk-1.6.1/
#

#kubeflow                    ml-pipeline-9f9846c47-tt7xs
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-api-server-2.0.0-alpha.5:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-api-server-2.0.0-alpha.5:1.0 gcr.io/ml-pipeline/api-server:2.0.0-alpha.5"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-ml-pipeline-api-server-2.0.0-alpha.5.tar gcr.io/ml-pipeline/api-server:2.0.0-alpha.5
sudo scp dtpct:/root/gcr.io-ml-pipeline-api-server-2.0.0-alpha.5.tar ../kubeflow-imgbk-1.6.1/
#

#kubeflow                    ml-pipeline-persistenceagent-84bdfb5c6b-4mwfk
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-persistenceagent-2.0.0-alpha.5:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-persistenceagent-2.0.0-alpha.5:1.0 gcr.io/ml-pipeline/persistenceagent:2.0.0-alpha.5"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-ml-pipeline-persistenceagent-2.0.0-alpha.5.tar gcr.io/ml-pipeline/persistenceagent:2.0.0-alpha.5
sudo scp dtpct:/root/gcr.io-ml-pipeline-persistenceagent-2.0.0-alpha.5.tar ../kubeflow-imgbk-1.6.1/
#

#kubeflow                    ml-pipeline-scheduledworkflow-8579759bc-c8dgt
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-scheduledworkflow-2.0.0-alpha.5:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-scheduledworkflow-2.0.0-alpha.5:1.0 gcr.io/ml-pipeline/scheduledworkflow:2.0.0-alpha.5"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-ml-pipeline-scheduledworkflow-2.0.0-alpha.5.tar gcr.io/ml-pipeline/scheduledworkflow:2.0.0-alpha.5
sudo scp dtpct:/root/gcr.io-ml-pipeline-scheduledworkflow-2.0.0-alpha.5.tar ../kubeflow-imgbk-1.6.1/
#

#kubeflow                    ml-pipeline-viewer-crd-6d859f4d6d-4w9qd
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-viewer-crd-controller-2.0.0-alpha.5:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-viewer-crd-controller-2.0.0-alpha.5:1.0 gcr.io/ml-pipeline/viewer-crd-controller:2.0.0-alpha.5"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-ml-pipeline-viewer-crd-controller-2.0.0-alpha.5.tar gcr.io/ml-pipeline/viewer-crd-controller:2.0.0-alpha.5
sudo scp dtpct:/root/gcr.io-ml-pipeline-viewer-crd-controller-2.0.0-alpha.5.tar ../kubeflow-imgbk-1.6.1/
#

#kubeflow                    ml-pipeline-visualizationserver-969df884f-zb926
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-visualization-server-2.0.0-alpha.5:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-visualization-server-2.0.0-alpha.5:1.0 gcr.io/ml-pipeline/visualization-server:2.0.0-alpha.5"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-ml-pipeline-visualization-server-2.0.0-alpha.5.tar gcr.io/ml-pipeline/visualization-server:2.0.0-alpha.5
sudo scp dtpct:/root/gcr.io-ml-pipeline-visualization-server-2.0.0-alpha.5.tar ../kubeflow-imgbk-1.6.1/
#
#kubeflow                    mysql-5c7f79f986-zc4cc
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-mysql-5.7-debian:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-mysql-5.7-debian:1.0 gcr.io/ml-pipeline/mysql:5.7-debian"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-ml-pipeline-mysql-5.7-debian.tar gcr.io/ml-pipeline/mysql:5.7-debian
sudo scp dtpct:/root/gcr.io-ml-pipeline-mysql-5.7-debian.tar ../kubeflow-imgbk-1.6.1/
#gcr.io/ml-pipeline/mysql:5.7-debian

#1.7.0
#istio-system istio-ingressgateway-6ff7c88855-v9zj4
#istio-system cluster-local-gateway-675bb7b74-n5dr5
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/docker.io-istio-proxyv2-1.16.0:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/docker.io-istio-proxyv2-1.16.0:1.0 docker.io/istio/proxyv2:1.16.0"
sudo ssh dtpct ctr -n k8s.io i export docker.io-istio-proxyv2-1.16.0.tar docker.io/istio/proxyv2:1.16.0
#istio-system         istiod-6995577d4-6zsgt
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/docker.io-istio-pilot-1.16.0:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/docker.io-istio-pilot-1.16.0:1.0 docker.io/istio/pilot:1.16.0"
sudo ssh dtpct ctr -n k8s.io i export docker.io-istio-pilot-1.16.0.tar docker.io/istio/pilot:1.16.0
#istio-system         authservice-0
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-arrikto-kubeflow-oidc-authservice-e236439:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-arrikto-kubeflow-oidc-authservice-e236439:1.0 gcr.io/arrikto/kubeflow/oidc-authservice:e236439"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-arrikto-kubeflow-oidc-authservice-e236439.tar gcr.io/arrikto/kubeflow/oidc-authservice:e236439
#knative-eventing     eventing-controller-86647cbc5b-h5wbn
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-eventing-cmd-controller:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-eventing-cmd-controller:1.0 gcr.io/knative-releases/knative.dev/eventing/cmd/controller@sha256:33d78536e9b38dbb2ec2952207b48ff8e05acb48e7d28c2305bd0a0f7156198f"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-knative-releases-knative.dev-eventing-cmd-controller.tar gcr.io/knative-releases/knative.dev/eventing/cmd/controller@sha256:33d78536e9b38dbb2ec2952207b48ff8e05acb48e7d28c2305bd0a0f7156198f
#knative-eventing     eventing-webhook-6f48bb5f4c-n2vvf
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-eventing-cmd-webhook:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-eventing-cmd-webhook:1.0 gcr.io/knative-releases/knative.dev/eventing/cmd/webhook@sha256:d217ab7e3452a87f8cbb3b45df65c98b18b8be39551e3e960cd49ea44bb415ba"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-knative-releases-knative.dev-eventing-cmd-webhook.tar gcr.io/knative-releases/knative.dev/eventing/cmd/webhook@sha256:d217ab7e3452a87f8cbb3b45df65c98b18b8be39551e3e960cd49ea44bb415ba
#knative-serving      activator-855b695596-95c86
docker pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-serving-cmd-activator:1.0
docker image save registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-serving-cmd-activator:1.0 -o gcr.io-knative-releases-knative.dev-serving-cmd-activator.tar
ansible all -m copy -a"src=gcr.io-knative-releases-knative.dev-serving-cmd-activator.tar dest=/root/"
ansible all -m shell -a"ctr -n k8s.io i import /root/gcr.io-knative-releases-knative.dev-serving-cmd-activator.tar"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-serving-cmd-activator:1.0 gcr.io/knative-releases/knative.dev/serving/cmd/activator@sha256:c3bbf3a96920048869dcab8e133e00f59855670b8a0bbca3d72ced2f512eb5e1"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-knative-releases-knative.dev-serving-cmd-activator.tar gcr.io/knative-releases/knative.dev/serving/cmd/activator@sha256:c3bbf3a96920048869dcab8e133e00f59855670b8a0bbca3d72ced2f512eb5e1
#knative-serving      controller-6657c556fd-xjhjm
docker pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-serving-cmd-controller:1.0
docker image save registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-serving-cmd-controller:1.0 -o gcr.io-knative-releases-knative.dev-serving-cmd-controller.tar
ansible all -m copy -a"src=gcr.io-knative-releases-knative.dev-serving-cmd-controller.tar dest=/root/"
ansible all -m shell -a"ctr -n k8s.io i import /root/gcr.io-knative-releases-knative.dev-serving-cmd-controller.tar"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-serving-cmd-controller:1.0 gcr.io/knative-releases/knative.dev/serving/cmd/controller@sha256:38f9557f4d61ec79cc2cdbe76da8df6c6ae5f978a50a2847c22cc61aa240da95"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-knative-releases-knative.dev-serving-cmd-controller.tar gcr.io/knative-releases/knative.dev/serving/cmd/controller@sha256:38f9557f4d61ec79cc2cdbe76da8df6c6ae5f978a50a2847c22cc61aa240da95
#knative-serving      autoscaler-7cbddfc9f7-n2ffd
docker pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-serving-cmd-autoscaler:1.0
docker image save registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-serving-cmd-autoscaler:1.0 -o gcr.io-knative-releases-knative.dev-serving-cmd-autoscaler.tar
ansible all -m copy -a"src=gcr.io-knative-releases-knative.dev-serving-cmd-autoscaler.tar dest=/root/"
ansible all -m shell -a"ctr -n k8s.io i import /root/gcr.io-knative-releases-knative.dev-serving-cmd-autoscaler.tar"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-serving-cmd-autoscaler:1.0 gcr.io/knative-releases/knative.dev/serving/cmd/autoscaler@sha256:caae5e34b4cb311ed8551f2778cfca566a77a924a59b775bd516fa8b5e3c1d7f"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-knative-releases-knative.dev-serving-cmd-autoscaler.tar gcr.io/knative-releases/knative.dev/serving/cmd/autoscaler@sha256:caae5e34b4cb311ed8551f2778cfca566a77a924a59b775bd516fa8b5e3c1d7f
#knative-serving      domain-mapping-544987775c-j4bj7 
docker pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-serving-cmd-domain-mapping:1.0
docker image save registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-serving-cmd-domain-mapping:1.0 -o gcr.io-knative-releases-knative.dev-serving-cmd-domain-mapping.tar
ansible all -m copy -a"src=gcr.io-knative-releases-knative.dev-serving-cmd-domain-mapping.tar dest=/root/"
ansible all -m shell -a"ctr -n k8s.io i import /root/gcr.io-knative-releases-knative.dev-serving-cmd-domain-mapping.tar"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-serving-cmd-domain-mapping:1.0 gcr.io/knative-releases/knative.dev/serving/cmd/domain-mapping@sha256:763d648bf1edee2b4471b0e211dbc53ba2d28f92e4dae28ccd39af7185ef2c96"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-knative-releases-knative.dev-serving-cmd-domain-mapping.tar gcr.io/knative-releases/knative.dev/serving/cmd/domain-mapping@sha256:763d648bf1edee2b4471b0e211dbc53ba2d28f92e4dae28ccd39af7185ef2c96
#knative-serving      domainmapping-webhook-6b48bdc856-ppt2w
docker pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-serving-cmd-domain-mapping-w:1.0
docker image save registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-serving-cmd-domain-mapping-w:1.0 -o gcr.io-knative-releases-knative.dev-serving-cmd-domain-mapping-webhook.tar
ansible all -m copy -a"src=gcr.io-knative-releases-knative.dev-serving-cmd-domain-mapping-webhook.tar dest=/root/"
ansible all -m shell -a"ctr -n k8s.io i import /root/gcr.io-knative-releases-knative.dev-serving-cmd-domain-mapping-webhook.tar"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-serving-cmd-domain-mapping-w:1.0 gcr.io/knative-releases/knative.dev/serving/cmd/domain-mapping-webhook@sha256:a4ba0076df2efaca2eed561339e21b3a4ca9d90167befd31de882bff69639470"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-knative-releases-knative.dev-serving-cmd-domain-mapping-webhook.tar gcr.io/knative-releases/knative.dev/serving/cmd/domain-mapping-webhook@sha256:a4ba0076df2efaca2eed561339e21b3a4ca9d90167befd31de882bff69639470
#knative-serving net-istio-controller-6fbdbd9959-5cqf4
docker pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-net-istio-cmd-controller:1.0
docker image save registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-net-istio-cmd-controller:1.0 -o gcr.io-knative-releases-knative.dev-net-istio-cmd-controller.tar
ansible all -m copy -a"src=gcr.io-knative-releases-knative.dev-net-istio-cmd-controller.tar dest=/root/"
ansible all -m shell -a"ctr -n k8s.io i import /root/gcr.io-knative-releases-knative.dev-net-istio-cmd-controller.tar"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-net-istio-cmd-controller:1.0 gcr.io/knative-releases/knative.dev/net-istio/cmd/controller@sha256:2b484d982ef1a5d6ff93c46d3e45f51c2605c2e3ed766e20247d1727eb5ce918"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-knative-releases-knative.dev-net-istio-cmd-controller.tar gcr.io/knative-releases/knative.dev/net-istio/cmd/controller@sha256:2b484d982ef1a5d6ff93c46d3e45f51c2605c2e3ed766e20247d1727eb5ce918
#knative-serving net-istio-webhook-7d4879cd7f-4stkv
docker pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-net-istio-cmd-webhook:1.0
docker image save registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-net-istio-cmd-webhook:1.0 -o gcr.io-knative-releases-knative.dev-net-istio-cmd-webhook.tar
ansible all -m copy -a"src=gcr.io-knative-releases-knative.dev-net-istio-cmd-webhook.tar dest=/root/"
ansible all -m shell -a"ctr -n k8s.io i import /root/gcr.io-knative-releases-knative.dev-net-istio-cmd-webhook.tar"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-net-istio-cmd-webhook:1.0 gcr.io/knative-releases/knative.dev/net-istio/cmd/webhook@sha256:59b6a46d3b55a03507c76a3afe8a4ee5f1a38f1130fd3d65c9fe57fff583fa8d"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-knative-releases-knative.dev-net-istio-cmd-webhook.tar gcr.io/knative-releases/knative.dev/net-istio/cmd/webhook@sha256:59b6a46d3b55a03507c76a3afe8a4ee5f1a38f1130fd3d65c9fe57fff583fa8d
#knative-serving webhook-665c977469-qchk2
docker pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-serving-cmd-webhook:1.0
docker image save registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-serving-cmd-webhook:1.0 -o gcr.io-knative-releases-knative.dev-serving-cmd-webhook.tar
ansible all -m copy -a"src=gcr.io-knative-releases-knative.dev-serving-cmd-webhook.tar dest=/root/"
ansible all -m shell -a"ctr -n k8s.io i import /root/gcr.io-knative-releases-knative.dev-serving-cmd-webhook.tar"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-knative-releases-knative.dev-serving-cmd-webhook:1.0 gcr.io/knative-releases/knative.dev/serving/cmd/webhook@sha256:bc13765ba4895c0fa318a065392d05d0adc0e20415c739e0aacb3f56140bf9ae"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-knative-releases-knative.dev-serving-cmd-webhook.tar gcr.io/knative-releases/knative.dev/serving/cmd/webhook@sha256:bc13765ba4895c0fa318a065392d05d0adc0e20415c739e0aacb3f56140bf9ae
#kubeflow cache-server-7969cdbfc-6f429
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-cache-server-2.0.0-alpha.7:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-cache-server-2.0.0-alpha.7:1.0 gcr.io/ml-pipeline/cache-server:2.0.0-alpha.7"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-ml-pipeline-cache-server-2.0.0-alpha.7.tar gcr.io/ml-pipeline/cache-server:2.0.0-alpha.7
#kubeflow kserve-controller-manager-698dd6896d-t96l5
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-kubebuilder-kube-rbac-proxy-v0.13.1:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-kubebuilder-kube-rbac-proxy-v0.13.1:1.0 gcr.io/kubebuilder/kube-rbac-proxy:v0.13.1"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-kubebuilder-kube-rbac-proxy-v0.13.1.tar gcr.io/kubebuilder/kube-rbac-proxy:v0.13.1
#kubeflow metadata-envoy-deployment-7b49bdb748-jgv2p
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-metadata-envoy-2.0.0-alpha.7:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-metadata-envoy-2.0.0-alpha.7:1.0 gcr.io/ml-pipeline/metadata-envoy:2.0.0-alpha.7"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-ml-pipeline-metadata-envoy-2.0.0-alpha.7.tar gcr.io/ml-pipeline/metadata-envoy:2.0.0-alpha.7
#kubeflow metadata-grpc-deployment-6d744c66bb-865gm
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-tfx-oss-public-ml_metadata_store_server-1.5.0:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-tfx-oss-public-ml_metadata_store_server-1.5.0:1.0 gcr.io/tfx-oss-public/ml_metadata_store_server:1.5.0"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-tfx-oss-public-ml_metadata_store_server-1.5.0.tar gcr.io/tfx-oss-public/ml_metadata_store_server:1.5.0
#kubeflow metadata-writer-5bfdbf79b7-qbsjf
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-tfx-oss-public-ml_metadata_store_server-1.5.0:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-tfx-oss-public-ml_metadata_store_server-1.5.0:1.0 gcr.io/ml-pipeline/metadata-writer:2.0.0-alpha.7"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-tfx-oss-public-ml_metadata_store_server-1.5.0.tar gcr.io/ml-pipeline/metadata-writer:2.0.0-alpha.7
#kubeflow minio-549846c488-7m4t9
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-minio:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-minio:1.0 gcr.io/ml-pipeline/minio:RELEASE.2019-08-14T20-37-41Z-license-compliance"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-ml-pipeline-minio.tar gcr.io/ml-pipeline/minio:RELEASE.2019-08-14T20-37-41Z-license-compliance
#kubeflow ml-pipeline-86d69497fc-z6chf 
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-api-server-2.0.0-alpha.7:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-api-server-2.0.0-alpha.7:1.0 gcr.io/ml-pipeline/api-server:2.0.0-alpha.7"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-ml-pipeline-api-server-2.0.0-alpha.7.tar gcr.io/ml-pipeline/api-server:2.0.0-alpha.7
#kubeflow ml-pipeline-persistenceagent-5789446f9c-8qt75
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-persistenceagent-2.0.0-alpha.7:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-persistenceagent-2.0.0-alpha.7:1.0 gcr.io/ml-pipeline/persistenceagent:2.0.0-alpha.7"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-ml-pipeline-persistenceagent-2.0.0-alpha.7.tar gcr.io/ml-pipeline/persistenceagent:2.0.0-alpha.7
#kubeflow ml-pipeline-scheduledworkflow-fb9fbd76b-zl5f5
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-scheduledworkflow-2.0.0-alpha.7:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-scheduledworkflow-2.0.0-alpha.7:1.0 gcr.io/ml-pipeline/scheduledworkflow:2.0.0-alpha.7"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-ml-pipeline-scheduledworkflow-2.0.0-alpha.7.tar gcr.io/ml-pipeline/scheduledworkflow:2.0.0-alpha.7
#kubeflow ml-pipeline-ui-74fcbdddd9-nwkw9
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-frontend-2.0.0-alpha.7:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-frontend-2.0.0-alpha.7:1.0 gcr.io/ml-pipeline/frontend:2.0.0-alpha.7"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-ml-pipeline-frontend-2.0.0-alpha.7.tar gcr.io/ml-pipeline/frontend:2.0.0-alpha.7
#kubeflow ml-pipeline-viewer-crd-5f955bfb79-pkgdh
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-viewer-crd-controller-2.0.0-alpha.7:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-viewer-crd-controller-2.0.0-alpha.7:1.0 gcr.io/ml-pipeline/viewer-crd-controller:2.0.0-alpha.7"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-ml-pipeline-viewer-crd-controller-2.0.0-alpha.7.tar gcr.io/ml-pipeline/viewer-crd-controller:2.0.0-alpha.7
#kubeflow ml-pipeline-visualizationserver-845d745b46-sgpt4
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-visualization-server-2.0.0-alpha.7:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-visualization-server-2.0.0-alpha.7:1.0 gcr.io/ml-pipeline/visualization-server:2.0.0-alpha.7"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-ml-pipeline-visualization-server-2.0.0-alpha.7.tar gcr.io/ml-pipeline/visualization-server:2.0.0-alpha.7
#kubeflow mysql-5f968d4688-dhvf8
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-mysql-8.0.26:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-mysql-8.0.26:1.0 gcr.io/ml-pipeline/mysql:8.0.26"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-ml-pipeline-mysql-8.0.26.tar gcr.io/ml-pipeline/mysql:8.0.26
#kubeflow tensorboard-controller-deployment-697c566bd5-t4qln
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-kubebuilder-kube-rbac-proxy-v0.8.0:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-kubebuilder-kube-rbac-proxy-v0.8.0:1.0 gcr.io/kubebuilder/kube-rbac-proxy:v0.8.0"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-kubebuilder-kube-rbac-proxy-v0.8.0.tar gcr.io/kubebuilder/kube-rbac-proxy:v0.8.0
#kubeflow workflow-controller-56cc57796-6s6v5
# Error: container has runAsNonRoot and image will run as root (pod: "workflow-controller-56cc57796-bct4b_kubeflow(3d084b2f-95ca-4610-af3f-a4be2fcd71d6)", container: workflow-controller)
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-viewer-crd-controller-2.0.0-alpha.7:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-viewer-crd-controller-2.0.0-alpha.7:1.0 gcr.io/ml-pipeline/workflow-controller:v3.3.8-license-compliance"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-ml-pipeline-viewer-crd-controller-2.0.0-alpha.7.tar gcr.io/ml-pipeline/workflow-controller:v3.3.8-license-compliance
#kubeflow profiles-deployment-7cf8b9b794-kr597
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/docker.io-kubeflownotebookswg-profile-controller-v1.7.0:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/docker.io-kubeflownotebookswg-profile-controller-v1.7.0:1.0 docker.io/kubeflownotebookswg/profile-controller:v1.7.0"
sudo ssh dtpct ctr -n k8s.io i export docker.io-kubeflownotebookswg-profile-controller-v1.7.0.tar docker.io/kubeflownotebookswg/profile-controller:v1.7.0
#kubeflow                    katib-ui-7859bc4c67-f65nf
ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/docker.io-kubeflowkatib-katib-ui-v0.15.0:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/docker.io-kubeflowkatib-katib-ui-v0.15.0:1.0 docker.io/kubeflowkatib/katib-ui:v0.15.0"
sudo ssh dtpct ctr -n k8s.io i export docker.io-kubeflowkatib-katib-ui-v0.15.0.tar docker.io/kubeflowkatib/katib-ui:v0.15.0


:<<EOF
RUN cat /proc/version
#Linux version 5.15.49-linuxkit (root@buildkitsandbox) (gcc (Alpine 10.2.1_pre1) 10.2.1 20201203, GNU ld (GNU Binutils) 2.35.2) #1 SMP Tue Sep 13 07:51:46 UTC 2022
RUN cat /etc/issue
#Alpine Linux 3.17
EOF
cat << \EOF > Dockerfile
FROM registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-ml-pipeline-viewer-crd-controller-2.0.0-alpha.7:1.0
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
RUN addgroup -S workflow && adduser -u 1000 -S workflow -G workflow -G root
RUN apk add --update util-linux
RUN whereis workflow-controller
#RUN chmod a+x /usr/bin/workflow-controller
USER 1000
EOF
docker build ./ -t harbor.my.org:1080/kubeflow/ml-pipeline-workflow-controller:v3.3.8-license-compliance
docker push harbor.my.org:1080/kubeflow/ml-pipeline-workflow-controller:v3.3.8-license-compliance
ansible all -m shell -a"ctr -n k8s.io i delete gcr.io/ml-pipeline/workflow-controller:v3.3.8-license-compliance"
ansible all -m shell -a"crictl pull harbor.my.org:1080/kubeflow/ml-pipeline-workflow-controller:v3.3.8-license-compliance"
ansible all -m shell -a"ctr -n k8s.io i tag harbor.my.org:1080/kubeflow/ml-pipeline-workflow-controller:v3.3.8-license-compliance gcr.io/ml-pipeline/workflow-controller:v3.3.8-license-compliance"
    #workflow-controller这个程序找不到
    #Error: failed to create containerd task: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: exec: "workflow-controller": executable file not found in $PATH: unknown

#1.8.0
:<<EOF
busybox:1.28
docker.io/istio/pilot:1.17.5
docker.io/istio/proxyv2:1.17.5
docker.io/kubeflowkatib/earlystopping-medianstop:v0.16.0
docker.io/kubeflowkatib/enas-cnn-cifar10-cpu:v0.16.0
docker.io/kubeflowkatib/file-metrics-collector:v0.16.0
docker.io/kubeflowkatib/katib-controller:v0.16.0
docker.io/kubeflowkatib/katib-db-manager:v0.16.0
docker.io/kubeflowkatib/katib-ui:v0.16.0
docker.io/kubeflowkatib/mxnet-mnist:v0.16.0
docker.io/kubeflowkatib/pytorch-mnist-cpu:v0.16.0
docker.io/kubeflowkatib/suggestion-darts:v0.16.0
docker.io/kubeflowkatib/suggestion-enas:v0.16.0
docker.io/kubeflowkatib/suggestion-goptuna:v0.16.0
docker.io/kubeflowkatib/suggestion-hyperband:v0.16.0
docker.io/kubeflowkatib/suggestion-hyperopt:v0.16.0
docker.io/kubeflowkatib/suggestion-optuna:v0.16.0
docker.io/kubeflowkatib/suggestion-pbt:v0.16.0
docker.io/kubeflowkatib/suggestion-skopt:v0.16.0
docker.io/kubeflowkatib/tfevent-metrics-collector:v0.16.0
docker.io/kubeflowmanifestswg/oidc-authservice:e236439
docker.io/kubeflownotebookswg/centraldashboard:v1.8.0
docker.io/kubeflownotebookswg/jupyter-web-app:v1.8.0
docker.io/kubeflownotebookswg/kfam:v1.8.0
docker.io/kubeflownotebookswg/notebook-controller:v1.8.0
docker.io/kubeflownotebookswg/poddefaults-webhook:v1.8.0
docker.io/kubeflownotebookswg/profile-controller:v1.8.0
docker.io/kubeflownotebookswg/pvcviewer-controller:v1.8.0
docker.io/kubeflownotebookswg/tensorboard-controller:v1.8.0
docker.io/kubeflownotebookswg/tensorboards-web-app:v1.8.0
docker.io/kubeflownotebookswg/volumes-web-app:v1.8.0
docker.io/metacontrollerio/metacontroller:v2.0.4
docker.io/seldonio/mlserver:1.3.2
gcr.io/knative-releases/knative.dev/eventing/cmd/controller@sha256:92967bab4ad8f7d55ce3a77ba8868f3f2ce173c010958c28b9a690964ad6ee9b
gcr.io/knative-releases/knative.dev/eventing/cmd/mtping@sha256:6d35cc98baa098fc0c5b4290859e363a8350a9dadc31d1191b0b5c9796958223
gcr.io/knative-releases/knative.dev/eventing/cmd/webhook@sha256:ebf93652f0254ac56600bedf4a7d81611b3e1e7f6526c6998da5dd24cdc67ee1
gcr.io/knative-releases/knative.dev/net-istio/cmd/controller@sha256:421aa67057240fa0c56ebf2c6e5b482a12842005805c46e067129402d1751220
gcr.io/knative-releases/knative.dev/net-istio/cmd/webhook@sha256:bfa1dfea77aff6dfa7959f4822d8e61c4f7933053874cd3f27352323e6ecd985
gcr.io/knative-releases/knative.dev/serving/cmd/activator@sha256:c2994c2b6c2c7f38ad1b85c71789bf1753cc8979926423c83231e62258837cb9
gcr.io/knative-releases/knative.dev/serving/cmd/autoscaler@sha256:8319aa662b4912e8175018bd7cc90c63838562a27515197b803bdcd5634c7007
gcr.io/knative-releases/knative.dev/serving/cmd/controller@sha256:98a2cc7fd62ee95e137116504e7166c32c65efef42c3d1454630780410abf943
gcr.io/knative-releases/knative.dev/serving/cmd/domain-mapping-webhook@sha256:7368aaddf2be8d8784dc7195f5bc272ecfe49d429697f48de0ddc44f278167aa
gcr.io/knative-releases/knative.dev/serving/cmd/domain-mapping@sha256:f66c41ad7a73f5d4f4bdfec4294d5459c477f09f3ce52934d1a215e32316b59b
gcr.io/knative-releases/knative.dev/serving/cmd/queue@sha256:dabaecec38860ca4c972e6821d5dc825549faf50c6feb8feb4c04802f2338b8a
gcr.io/knative-releases/knative.dev/serving/cmd/webhook@sha256:4305209ce498caf783f39c8f3e85dfa635ece6947033bf50b0b627983fd65953
gcr.io/kubebuilder/kube-rbac-proxy:v0.13.1
gcr.io/kubebuilder/kube-rbac-proxy:v0.8.0
gcr.io/ml-pipeline/api-server:2.0.3
gcr.io/ml-pipeline/cache-server:2.0.3
gcr.io/ml-pipeline/frontend
gcr.io/ml-pipeline/frontend:2.0.3
gcr.io/ml-pipeline/metadata-writer:2.0.3
gcr.io/ml-pipeline/minio:RELEASE.2019-08-14T20-37-41Z-license-compliance
gcr.io/ml-pipeline/mysql:8.0.26
gcr.io/ml-pipeline/persistenceagent:2.0.3
gcr.io/ml-pipeline/scheduledworkflow:2.0.3
gcr.io/ml-pipeline/viewer-crd-controller:2.0.3
gcr.io/ml-pipeline/visualization-server
gcr.io/ml-pipeline/workflow-controller:v3.3.10-license-compliance
gcr.io/tfx-oss-public/ml_metadata_store_server:1.14.0
ghcr.io/dexidp/dex:v2.36.0
image:
kserve/kserve-controller:v0.11.1
kserve/lgbserver:v0.11.1
kserve/models-web-app:v0.10.0
kserve/paddleserver:v0.11.1
kserve/pmmlserver:v0.11.1
kserve/sklearnserver:v0.11.1
kserve/xgbserver:v0.11.1
kubeflow/training-operator:v1-855e096
mysql:8.0.29
nvcr.io/nvidia/tritonserver:23.05-py3
python:3.7
pytorch/torchserve-kfs:0.8.2
quay.io/jetstack/cert-manager-cainjector:v1.12.2
quay.io/jetstack/cert-manager-controller:v1.12.2
quay.io/jetstack/cert-manager-webhook:v1.12.2
tensorflow/serving:2.6.2
EOF


#1.6.1
#k8s 1.25
kubectl describe pod -n kubeflow workflow-controller-56cc57796-h89dl
    CreateContainerConfigError
    Error: container has runAsNonRoot and image will run as root (pod: "workflow-controller-56cc57796-h89dl_kubeflow(515a2fb7-95a7-4de5-93ee-a02c2eb83c15)", container: workflow-controller)
#k8s 1.22
kubectl logs -n kubeflow             profiles-deployment-57d9fdf8b-wgbtg
    time="2023-04-26T11:50:30Z" level=info msg="Server started"
    E0426 11:50:30.940110       1 reflector.go:125] pkg/mod/k8s.io/client-go@v0.0.0-20190528110200-4f3abb12cae2/tools/cache/reflector.go:93: Failed to list *v1.RoleBinding: Get "https://10.96.0.1:443/apis/rbac.authorization.k8s.io/v1/rolebindings?limit=500&resourceVersion=0": dial tcp 10.96.0.1:443: connect: connection refused
#1.7.0(k8s 1.26.3/1.25.9相同错误)
kubectl describe pod -n istio-system cluster-local-gateway-675bb7b74-hkzbd
kubectl describe pod -n istio-system istio-ingressgateway-c7fdd4bf6-szctf
#这个错误重启就会恢复，一下修改方案错误会引起更多问题
  Warning  FailedMount  2m31s (x34 over 67m)  kubelet  MountVolume.SetUp failed for volume "istiod-ca-cert" : configmap "istio-ca-root-cert" not found
kubectl get pods -n istio-system | awk '{print $1}' | xargs kubectl delete pod "$1" -n istio-system --force --grace-period=0
:<<EOF
kubectl get cm -n istio-system 
    NAME                          DATA   AGE
    istio                         2      67m
    istio-sidecar-injector        2      67m
    kube-root-ca.crt              1      68m
    oidc-authservice-parameters   10     67m
find ./ -type file|xargs grep "istio-ca-root-cert"
find ./ -type file|xargs grep "kube-root-ca.crt"
find ./ -type file|xargs grep "istio-sidecar-injector"
find ./ -type file|xargs grep "name: istio"
#find ./ -type file|xargs $SED -i "s/istio-ca-root-cert/kube-root-ca.crt/g"
find ./ -type file|xargs $SED -i "s/kube-root-ca.crt/istio-ca-root-cert/g"
#find ./ -type file|xargs grep "kube-root-ca.crt"
find ./ -type file|xargs grep "istio-ca-root-cert"
EOF
kubectl describe pod -n kubeflow workflow-controller-56cc57796-h89dl
    CreateContainerConfigError
    Error: container has runAsNonRoot and image will run as root (pod: "workflow-controller-56cc57796-h89dl_kubeflow(515a2fb7-95a7-4de5-93ee-a02c2eb83c15)", container: workflow-controller)
    #1，kubeflow/manifests-1.7.0/apps/pipeline/upstream/third-party/argo/base/workflow-controller-deployment-patch.yaml
    #增加
      securityContext:
        runAsGroup: 0
        runAsNonRoot: false
        runAsUser: 0
    #结果只要有runAsNonRoot，就会按照非root用户处理，如果指定1000之类普通用户id入口脚本没有权限提示找不到
    #2，在output.yaml里查找"gcr.io/ml-pipeline/workflow-controller:v3.3.8-license-compliance"
    #把
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
          readOnlyRootFilesystem: true
          runAsNonRoot: true
    #删除掉
#apps/kfp-tekton/upstream/third-party/argo/upstream/manifests/base/workflow-controller/workflow-controller-deployment.yaml
kubectl describe pod -n knative-eventing eventing-controller-86647cbc5b-9ftfq
    panic: The environment variable "WEBHOOK_NAME" is not set.
    This should be unique for the webhooks in a namespace
    If this is a process running on Kubernetes, then initialize this variable via:
    env:
    - name: WEBHOOK_NAME
        value: webhook
    goroutine 1 [running]:
    knative.dev/pkg/webhook.NameFromEnv()
        knative.dev/pkg@v0.0.0-20221011175852-714b7630a836/webhook/env.go:49 +0x88
    main.main()
        knative.dev/eventing/cmd/webhook/main.go:256 +0x219
    #增加环境变量
        - name: WEBHOOK_NAME
            value: webhook

kubectl delete pod -n istio-system cluster-local-gateway-675bb7b74-hkzbd --force --grace-period=0
kubectl describe pod -n istio-system istio-ingressgateway-c7fdd4bf6-szctf --force --grace-period=0

#必须先分步单独安装certmanager相关，再while ! kustomize build example
kustomize build common/cert-manager/cert-manager/base | kubectl apply -f -
kubectl wait --for=condition=ready pod -l 'app in (cert-manager,webhook)' --timeout=180s -n cert-manager
kustomize build common/cert-manager/kubeflow-issuer/base | kubectl apply -f -
while ! kustomize build example | awk '!/well-defined/' | kubectl apply -f -; do echo "Retrying to apply resources"; sleep 10; done

#留意相应sc有无pvc创建失败的日志
kubectl logs -f -n local-path-storage `kubectl get pod -n local-path-storage | grep Running | awk '{print $1}'`

kustomize build example | awk '!/well-defined/' > output.yaml
while !  kubectl apply -f output.yaml; do echo "Retrying to apply resources"; sleep 10; done
#1.7.0
    error: resource mapping not found for name: "webhook" namespace: "knative-serving" from "STDIN": no matches for kind "HorizontalPodAutoscaler" in version "autoscaling/v2beta2"
    ensure CRDs are installed first
    Retrying to apply resources
kubectl api-versions | grep autoscaling
    autoscaling.internal.knative.dev/v1alpha1
    autoscaling/v1
    autoscaling/v2
find ./ -type file|xargs grep "autoscaling/v2beta2"
find ./ -type file|xargs $SED -i "s@autoscaling/v2beta2@autoscaling/v2@g"
find ./ -type file|xargs grep "autoscaling/v2beta2"
find ./ -type file|xargs grep "autoscaling/v2"
#1.6.1
resource mapping not found for name: "eventing-webhook" namespace: "knative-eventing" from "STDIN": no matches for kind "PodDisruptionBudget" in version "policy/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "eventing-webhook" namespace: "knative-eventing" from "STDIN": no matches for kind "HorizontalPodAutoscaler" in version "autoscaling/v2beta2"
ensure CRDs are installed first
resource mapping not found for name: "activator" namespace: "knative-serving" from "STDIN": no matches for kind "HorizontalPodAutoscaler" in version "autoscaling/v2beta2"
ensure CRDs are installed first
resource mapping not found for name: "webhook" namespace: "knative-serving" from "STDIN": no matches for kind "HorizontalPodAutoscaler" in version "autoscaling/v2beta2"
ensure CRDs are installed first
kubectl api-versions | grep policy
    policy/v1
find ./ -type file|xargs grep "policy/v1beta"
find ./ -type file|xargs $SED -i "s@policy/v1beta1@policy/v1@g"
find ./ -type file|xargs grep "policy/v1"
kubectl api-versions | grep autoscaling
    autoscaling.internal.knative.dev/v1alpha1
    autoscaling/v1
    autoscaling/v2
find ./ -type file|xargs grep "autoscaling/v2beta2"
find ./ -type file|xargs $SED -i "s@autoscaling/v2beta2@autoscaling/v2@g"
find ./ -type file|xargs $SED -i "s@autoscaling/v2beta1@autoscaling/v2@g"
find ./ -type file|xargs grep "autoscaling/v2beta2"
find ./ -type file|xargs grep "autoscaling/v2"


while ! kustomize build example | awk '!/well-defined/' | kubectl delete -f -; do echo "Retrying to delete resources"; sleep 10; done
kustomize build common/cert-manager/kubeflow-issuer/base | kubectl delete -f -
kustomize build common/cert-manager/cert-manager/base | kubectl delete -f -

kubectl proxy --port=8009 &
remove_abnormal_pods.sh
kubectl get deployments.apps -n kubeflow-user-example-com | awk '{print $1}' | xargs kubectl delete deployments.apps $1 -n kubeflow-user-example-com --force --grace-period=0
kubectl get replicaset.apps -n kubeflow-user-example-com | awk '{print $1}' | xargs kubectl delete replicaset.apps $1 -n kubeflow-user-example-com --force --grace-period=0
kubectl get service -n kubeflow-user-example-com | awk '{print $1}' | xargs kubectl delete service $1 -n kubeflow-user-example-com --force --grace-period=0
kubectl get pod -n kubeflow-user-example-com | awk '{print $1}' | xargs kubectl delete pod $1 -n kubeflow-user-example-com --force --grace-period=0
kubectl delete ns kubeflow-user-example-com
kubectl get pods -A
sudo ssh dtpct kubectl proxy --port=8009 &
sudo ssh dtpct remove_terminating_nses.sh
kubectl get ns | grep Terminating

kubectl get pvc -A
kubectl get pv

#1.6.1
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesJson6902' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesJson6902' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
2023/04/16 18:34:44 well-defined vars that were never replaced: kfp-app-name,kfp-app-version
namespace/auth unchanged
namespace/cert-manager unchanged
namespace/istio-system unchanged
namespace/knative-eventing unchanged
namespace/knative-serving unchanged
namespace/kubeflow unchanged
customresourcedefinition.apiextensions.k8s.io/apiserversources.sources.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/authcodes.dex.coreos.com unchanged
customresourcedefinition.apiextensions.k8s.io/authorizationpolicies.security.istio.io unchanged
customresourcedefinition.apiextensions.k8s.io/brokers.eventing.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/certificaterequests.cert-manager.io configured
customresourcedefinition.apiextensions.k8s.io/certificates.cert-manager.io configured
customresourcedefinition.apiextensions.k8s.io/certificates.networking.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/challenges.acme.cert-manager.io configured
customresourcedefinition.apiextensions.k8s.io/channels.messaging.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/clusterdomainclaims.networking.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/clusterissuers.cert-manager.io configured
customresourcedefinition.apiextensions.k8s.io/clusterservingruntimes.serving.kserve.io configured
customresourcedefinition.apiextensions.k8s.io/clusterworkflowtemplates.argoproj.io unchanged
customresourcedefinition.apiextensions.k8s.io/compositecontrollers.metacontroller.k8s.io configured
customresourcedefinition.apiextensions.k8s.io/configurations.serving.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/containersources.sources.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/controllerrevisions.metacontroller.k8s.io configured
customresourcedefinition.apiextensions.k8s.io/cronworkflows.argoproj.io unchanged
customresourcedefinition.apiextensions.k8s.io/decoratorcontrollers.metacontroller.k8s.io configured
customresourcedefinition.apiextensions.k8s.io/destinationrules.networking.istio.io unchanged
customresourcedefinition.apiextensions.k8s.io/domainmappings.serving.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/envoyfilters.networking.istio.io unchanged
customresourcedefinition.apiextensions.k8s.io/eventtypes.eventing.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/experiments.kubeflow.org unchanged
customresourcedefinition.apiextensions.k8s.io/gateways.networking.istio.io unchanged
customresourcedefinition.apiextensions.k8s.io/images.caching.internal.knative.dev unchanged
Warning: Detected changes to resource inferenceservices.serving.kserve.io which is currently being deleted.
customresourcedefinition.apiextensions.k8s.io/inferenceservices.serving.kserve.io configured
customresourcedefinition.apiextensions.k8s.io/ingresses.networking.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/issuers.cert-manager.io configured
customresourcedefinition.apiextensions.k8s.io/istiooperators.install.istio.io unchanged
customresourcedefinition.apiextensions.k8s.io/metrics.autoscaling.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/mpijobs.kubeflow.org configured
customresourcedefinition.apiextensions.k8s.io/mxjobs.kubeflow.org configured
customresourcedefinition.apiextensions.k8s.io/notebooks.kubeflow.org configured
customresourcedefinition.apiextensions.k8s.io/orders.acme.cert-manager.io configured
customresourcedefinition.apiextensions.k8s.io/parallels.flows.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/peerauthentications.security.istio.io unchanged
customresourcedefinition.apiextensions.k8s.io/pingsources.sources.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/podautoscalers.autoscaling.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/poddefaults.kubeflow.org configured
customresourcedefinition.apiextensions.k8s.io/profiles.kubeflow.org configured
customresourcedefinition.apiextensions.k8s.io/proxyconfigs.networking.istio.io unchanged
customresourcedefinition.apiextensions.k8s.io/pytorchjobs.kubeflow.org configured
customresourcedefinition.apiextensions.k8s.io/requestauthentications.security.istio.io unchanged
customresourcedefinition.apiextensions.k8s.io/revisions.serving.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/routes.serving.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/scheduledworkflows.kubeflow.org unchanged
customresourcedefinition.apiextensions.k8s.io/sequences.flows.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/serverlessservices.networking.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/serviceentries.networking.istio.io unchanged
customresourcedefinition.apiextensions.k8s.io/services.serving.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/servingruntimes.serving.kserve.io configured
customresourcedefinition.apiextensions.k8s.io/sidecars.networking.istio.io unchanged
customresourcedefinition.apiextensions.k8s.io/sinkbindings.sources.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/subscriptions.messaging.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/suggestions.kubeflow.org unchanged
customresourcedefinition.apiextensions.k8s.io/telemetries.telemetry.istio.io unchanged
customresourcedefinition.apiextensions.k8s.io/tensorboards.tensorboard.kubeflow.org configured
customresourcedefinition.apiextensions.k8s.io/tfjobs.kubeflow.org configured
customresourcedefinition.apiextensions.k8s.io/trainedmodels.serving.kserve.io configured
customresourcedefinition.apiextensions.k8s.io/trials.kubeflow.org unchanged
customresourcedefinition.apiextensions.k8s.io/triggers.eventing.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/viewers.kubeflow.org unchanged
customresourcedefinition.apiextensions.k8s.io/virtualservices.networking.istio.io unchanged
customresourcedefinition.apiextensions.k8s.io/wasmplugins.extensions.istio.io unchanged
customresourcedefinition.apiextensions.k8s.io/workfloweventbindings.argoproj.io unchanged
customresourcedefinition.apiextensions.k8s.io/workflows.argoproj.io unchanged
customresourcedefinition.apiextensions.k8s.io/workflowtaskresults.argoproj.io unchanged
customresourcedefinition.apiextensions.k8s.io/workflowtasksets.argoproj.io unchanged
customresourcedefinition.apiextensions.k8s.io/workflowtemplates.argoproj.io unchanged
customresourcedefinition.apiextensions.k8s.io/workloadentries.networking.istio.io unchanged
customresourcedefinition.apiextensions.k8s.io/workloadgroups.networking.istio.io unchanged
customresourcedefinition.apiextensions.k8s.io/xgboostjobs.kubeflow.org configured
serviceaccount/dex unchanged
serviceaccount/cert-manager unchanged
serviceaccount/cert-manager-cainjector unchanged
serviceaccount/cert-manager-webhook unchanged
serviceaccount/cluster-local-gateway-service-account unchanged
serviceaccount/istio-ingressgateway-service-account unchanged
serviceaccount/istio-reader-service-account unchanged
serviceaccount/istiod unchanged
serviceaccount/istiod-service-account unchanged
serviceaccount/eventing-controller unchanged
serviceaccount/eventing-webhook unchanged
serviceaccount/pingsource-mt-adapter unchanged
serviceaccount/controller unchanged
serviceaccount/admission-webhook-service-account unchanged
serviceaccount/argo unchanged
serviceaccount/centraldashboard unchanged
serviceaccount/jupyter-web-app-service-account unchanged
serviceaccount/katib-controller unchanged
serviceaccount/katib-ui unchanged
serviceaccount/kserve-controller-manager unchanged
serviceaccount/kserve-models-web-app unchanged
serviceaccount/kubeflow-pipelines-cache unchanged
serviceaccount/kubeflow-pipelines-container-builder unchanged
serviceaccount/kubeflow-pipelines-metadata-writer unchanged
serviceaccount/kubeflow-pipelines-viewer unchanged
serviceaccount/meta-controller-service unchanged
serviceaccount/metadata-grpc-server unchanged
serviceaccount/ml-pipeline unchanged
serviceaccount/ml-pipeline-persistenceagent unchanged
serviceaccount/ml-pipeline-scheduledworkflow unchanged
serviceaccount/ml-pipeline-ui unchanged
serviceaccount/ml-pipeline-viewer-crd-service-account unchanged
serviceaccount/ml-pipeline-visualizationserver unchanged
serviceaccount/mysql unchanged
serviceaccount/notebook-controller-service-account unchanged
serviceaccount/pipeline-runner unchanged
serviceaccount/profiles-controller-service-account unchanged
serviceaccount/tensorboard-controller-controller-manager unchanged
serviceaccount/tensorboards-web-app-service-account unchanged
serviceaccount/training-operator unchanged
serviceaccount/volumes-web-app-service-account unchanged
role.rbac.authorization.k8s.io/cert-manager-webhook:dynamic-serving unchanged
role.rbac.authorization.k8s.io/cluster-local-gateway-sds unchanged
role.rbac.authorization.k8s.io/istio-ingressgateway-sds unchanged
role.rbac.authorization.k8s.io/istiod unchanged
role.rbac.authorization.k8s.io/istiod-istio-system unchanged
role.rbac.authorization.k8s.io/knative-eventing-webhook unchanged
role.rbac.authorization.k8s.io/cert-manager-cainjector:leaderelection unchanged
role.rbac.authorization.k8s.io/cert-manager:leaderelection unchanged
role.rbac.authorization.k8s.io/argo-role unchanged
role.rbac.authorization.k8s.io/centraldashboard unchanged
role.rbac.authorization.k8s.io/jupyter-web-app-jupyter-notebook-role unchanged
role.rbac.authorization.k8s.io/kserve-leader-election-role unchanged
role.rbac.authorization.k8s.io/kubeflow-pipelines-cache-role unchanged
role.rbac.authorization.k8s.io/kubeflow-pipelines-metadata-writer-role unchanged
role.rbac.authorization.k8s.io/ml-pipeline unchanged
role.rbac.authorization.k8s.io/ml-pipeline-persistenceagent-role unchanged
role.rbac.authorization.k8s.io/ml-pipeline-scheduledworkflow-role unchanged
role.rbac.authorization.k8s.io/ml-pipeline-ui unchanged
role.rbac.authorization.k8s.io/ml-pipeline-viewer-controller-role unchanged
role.rbac.authorization.k8s.io/notebook-controller-leader-election-role unchanged
role.rbac.authorization.k8s.io/pipeline-runner unchanged
role.rbac.authorization.k8s.io/profiles-leader-election-role unchanged
role.rbac.authorization.k8s.io/tensorboard-controller-leader-election-role unchanged
clusterrole.rbac.authorization.k8s.io/addressable-resolver configured
clusterrole.rbac.authorization.k8s.io/admission-webhook-cluster-role unchanged
clusterrole.rbac.authorization.k8s.io/admission-webhook-kubeflow-poddefaults-admin configured
clusterrole.rbac.authorization.k8s.io/admission-webhook-kubeflow-poddefaults-edit configured
clusterrole.rbac.authorization.k8s.io/admission-webhook-kubeflow-poddefaults-view unchanged
clusterrole.rbac.authorization.k8s.io/aggregate-to-kubeflow-pipelines-edit unchanged
clusterrole.rbac.authorization.k8s.io/aggregate-to-kubeflow-pipelines-view unchanged
clusterrole.rbac.authorization.k8s.io/argo-aggregate-to-admin unchanged
clusterrole.rbac.authorization.k8s.io/argo-aggregate-to-edit unchanged
clusterrole.rbac.authorization.k8s.io/argo-aggregate-to-view unchanged
clusterrole.rbac.authorization.k8s.io/argo-cluster-role unchanged
clusterrole.rbac.authorization.k8s.io/broker-addressable-resolver unchanged
clusterrole.rbac.authorization.k8s.io/builtin-podspecable-binding unchanged
clusterrole.rbac.authorization.k8s.io/centraldashboard unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-cainjector unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-approve:cert-manager-io unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-certificates unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-certificatesigningrequests unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-challenges unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-clusterissuers unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-ingress-shim unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-issuers unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-orders unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-edit unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-view unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-webhook:subjectaccessreviews unchanged
clusterrole.rbac.authorization.k8s.io/channel-addressable-resolver unchanged
clusterrole.rbac.authorization.k8s.io/channelable-manipulator configured
clusterrole.rbac.authorization.k8s.io/dex unchanged
clusterrole.rbac.authorization.k8s.io/eventing-broker-filter unchanged
clusterrole.rbac.authorization.k8s.io/eventing-broker-ingress unchanged
clusterrole.rbac.authorization.k8s.io/eventing-config-reader unchanged
clusterrole.rbac.authorization.k8s.io/eventing-sources-source-observer unchanged
clusterrole.rbac.authorization.k8s.io/flows-addressable-resolver unchanged
clusterrole.rbac.authorization.k8s.io/istio-reader-clusterrole-istio-system unchanged
clusterrole.rbac.authorization.k8s.io/istio-reader-istio-system unchanged
clusterrole.rbac.authorization.k8s.io/istiod-clusterrole-istio-system unchanged
clusterrole.rbac.authorization.k8s.io/istiod-gateway-controller-istio-system unchanged
clusterrole.rbac.authorization.k8s.io/istiod-istio-system unchanged
clusterrole.rbac.authorization.k8s.io/jupyter-web-app-cluster-role unchanged
clusterrole.rbac.authorization.k8s.io/jupyter-web-app-kubeflow-notebook-ui-admin configured
clusterrole.rbac.authorization.k8s.io/jupyter-web-app-kubeflow-notebook-ui-edit unchanged
clusterrole.rbac.authorization.k8s.io/jupyter-web-app-kubeflow-notebook-ui-view unchanged
clusterrole.rbac.authorization.k8s.io/katib-controller unchanged
clusterrole.rbac.authorization.k8s.io/katib-ui unchanged
clusterrole.rbac.authorization.k8s.io/knative-bindings-namespaced-admin unchanged
clusterrole.rbac.authorization.k8s.io/knative-eventing-controller unchanged
clusterrole.rbac.authorization.k8s.io/knative-eventing-namespaced-admin unchanged
clusterrole.rbac.authorization.k8s.io/knative-eventing-namespaced-edit unchanged
clusterrole.rbac.authorization.k8s.io/knative-eventing-namespaced-view unchanged
clusterrole.rbac.authorization.k8s.io/knative-eventing-pingsource-mt-adapter unchanged
clusterrole.rbac.authorization.k8s.io/knative-eventing-sources-controller unchanged
clusterrole.rbac.authorization.k8s.io/knative-eventing-webhook unchanged
clusterrole.rbac.authorization.k8s.io/knative-flows-namespaced-admin unchanged
clusterrole.rbac.authorization.k8s.io/knative-messaging-namespaced-admin unchanged
clusterrole.rbac.authorization.k8s.io/knative-serving-addressable-resolver unchanged
clusterrole.rbac.authorization.k8s.io/knative-serving-admin unchanged
clusterrole.rbac.authorization.k8s.io/knative-serving-aggregated-addressable-resolver unchanged
clusterrole.rbac.authorization.k8s.io/knative-serving-core unchanged
clusterrole.rbac.authorization.k8s.io/knative-serving-istio unchanged
clusterrole.rbac.authorization.k8s.io/knative-serving-namespaced-admin unchanged
clusterrole.rbac.authorization.k8s.io/knative-serving-namespaced-edit unchanged
clusterrole.rbac.authorization.k8s.io/knative-serving-namespaced-view unchanged
clusterrole.rbac.authorization.k8s.io/knative-serving-podspecable-binding unchanged
clusterrole.rbac.authorization.k8s.io/knative-sources-namespaced-admin unchanged
clusterrole.rbac.authorization.k8s.io/kserve-manager-role configured
clusterrole.rbac.authorization.k8s.io/kserve-models-web-app-cluster-role unchanged
clusterrole.rbac.authorization.k8s.io/kserve-proxy-role unchanged
clusterrole.rbac.authorization.k8s.io/kubeflow-admin configured
clusterrole.rbac.authorization.k8s.io/kubeflow-edit configured
clusterrole.rbac.authorization.k8s.io/kubeflow-istio-admin configured
clusterrole.rbac.authorization.k8s.io/kubeflow-istio-edit unchanged
clusterrole.rbac.authorization.k8s.io/kubeflow-istio-view unchanged
clusterrole.rbac.authorization.k8s.io/kubeflow-katib-admin configured
clusterrole.rbac.authorization.k8s.io/kubeflow-katib-edit unchanged
clusterrole.rbac.authorization.k8s.io/kubeflow-katib-view unchanged
clusterrole.rbac.authorization.k8s.io/kubeflow-kserve-admin configured
clusterrole.rbac.authorization.k8s.io/kubeflow-kserve-edit unchanged
clusterrole.rbac.authorization.k8s.io/kubeflow-kserve-view unchanged
clusterrole.rbac.authorization.k8s.io/kubeflow-kubernetes-admin unchanged
clusterrole.rbac.authorization.k8s.io/kubeflow-kubernetes-edit unchanged
clusterrole.rbac.authorization.k8s.io/kubeflow-kubernetes-view unchanged
clusterrole.rbac.authorization.k8s.io/kubeflow-pipelines-cache-role unchanged
clusterrole.rbac.authorization.k8s.io/kubeflow-pipelines-edit configured
clusterrole.rbac.authorization.k8s.io/kubeflow-pipelines-metadata-writer-role unchanged
clusterrole.rbac.authorization.k8s.io/kubeflow-pipelines-view configured
clusterrole.rbac.authorization.k8s.io/kubeflow-training-admin configured
clusterrole.rbac.authorization.k8s.io/kubeflow-training-edit unchanged
clusterrole.rbac.authorization.k8s.io/kubeflow-training-view unchanged
clusterrole.rbac.authorization.k8s.io/kubeflow-view configured
clusterrole.rbac.authorization.k8s.io/meta-channelable-manipulator unchanged
clusterrole.rbac.authorization.k8s.io/ml-pipeline unchanged
clusterrole.rbac.authorization.k8s.io/ml-pipeline-persistenceagent-role unchanged
clusterrole.rbac.authorization.k8s.io/ml-pipeline-scheduledworkflow-role unchanged
clusterrole.rbac.authorization.k8s.io/ml-pipeline-ui unchanged
clusterrole.rbac.authorization.k8s.io/ml-pipeline-viewer-controller-role unchanged
clusterrole.rbac.authorization.k8s.io/notebook-controller-kubeflow-notebooks-admin configured
clusterrole.rbac.authorization.k8s.io/notebook-controller-kubeflow-notebooks-edit unchanged
clusterrole.rbac.authorization.k8s.io/notebook-controller-kubeflow-notebooks-view unchanged
clusterrole.rbac.authorization.k8s.io/notebook-controller-role configured
clusterrole.rbac.authorization.k8s.io/podspecable-binding configured
clusterrole.rbac.authorization.k8s.io/service-addressable-resolver unchanged
clusterrole.rbac.authorization.k8s.io/serving-addressable-resolver unchanged
clusterrole.rbac.authorization.k8s.io/source-observer configured
clusterrole.rbac.authorization.k8s.io/tensorboard-controller-manager-role configured
clusterrole.rbac.authorization.k8s.io/tensorboard-controller-metrics-reader unchanged
clusterrole.rbac.authorization.k8s.io/tensorboard-controller-proxy-role unchanged
clusterrole.rbac.authorization.k8s.io/tensorboards-web-app-cluster-role unchanged
clusterrole.rbac.authorization.k8s.io/tensorboards-web-app-kubeflow-tensorboard-ui-admin configured
clusterrole.rbac.authorization.k8s.io/tensorboards-web-app-kubeflow-tensorboard-ui-edit unchanged
clusterrole.rbac.authorization.k8s.io/tensorboards-web-app-kubeflow-tensorboard-ui-view unchanged
clusterrole.rbac.authorization.k8s.io/training-operator unchanged
clusterrole.rbac.authorization.k8s.io/volumes-web-app-cluster-role unchanged
clusterrole.rbac.authorization.k8s.io/volumes-web-app-kubeflow-volume-ui-admin configured
clusterrole.rbac.authorization.k8s.io/volumes-web-app-kubeflow-volume-ui-edit unchanged
clusterrole.rbac.authorization.k8s.io/volumes-web-app-kubeflow-volume-ui-view unchanged
rolebinding.rbac.authorization.k8s.io/cert-manager-webhook:dynamic-serving configured
rolebinding.rbac.authorization.k8s.io/cluster-local-gateway-sds unchanged
rolebinding.rbac.authorization.k8s.io/istio-ingressgateway-sds unchanged
rolebinding.rbac.authorization.k8s.io/istiod unchanged
rolebinding.rbac.authorization.k8s.io/istiod-istio-system unchanged
rolebinding.rbac.authorization.k8s.io/eventing-webhook unchanged
rolebinding.rbac.authorization.k8s.io/cert-manager-cainjector:leaderelection unchanged
rolebinding.rbac.authorization.k8s.io/cert-manager:leaderelection configured
rolebinding.rbac.authorization.k8s.io/argo-binding unchanged
rolebinding.rbac.authorization.k8s.io/centraldashboard unchanged
rolebinding.rbac.authorization.k8s.io/jupyter-web-app-jupyter-notebook-role-binding unchanged
rolebinding.rbac.authorization.k8s.io/kserve-leader-election-rolebinding unchanged
rolebinding.rbac.authorization.k8s.io/kubeflow-pipelines-cache-binding unchanged
rolebinding.rbac.authorization.k8s.io/kubeflow-pipelines-metadata-writer-binding unchanged
rolebinding.rbac.authorization.k8s.io/ml-pipeline unchanged
rolebinding.rbac.authorization.k8s.io/ml-pipeline-persistenceagent-binding unchanged
rolebinding.rbac.authorization.k8s.io/ml-pipeline-scheduledworkflow-binding unchanged
rolebinding.rbac.authorization.k8s.io/ml-pipeline-ui unchanged
rolebinding.rbac.authorization.k8s.io/ml-pipeline-viewer-crd-binding unchanged
rolebinding.rbac.authorization.k8s.io/notebook-controller-leader-election-rolebinding unchanged
rolebinding.rbac.authorization.k8s.io/pipeline-runner-binding unchanged
rolebinding.rbac.authorization.k8s.io/profiles-leader-election-rolebinding unchanged
rolebinding.rbac.authorization.k8s.io/tensorboard-controller-leader-election-rolebinding unchanged
clusterrolebinding.rbac.authorization.k8s.io/admission-webhook-cluster-role-binding unchanged
clusterrolebinding.rbac.authorization.k8s.io/argo-binding unchanged
clusterrolebinding.rbac.authorization.k8s.io/centraldashboard unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-cainjector unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-approve:cert-manager-io unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-certificates unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-certificatesigningrequests unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-challenges unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-clusterissuers unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-ingress-shim unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-issuers unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-orders unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-webhook:subjectaccessreviews configured
clusterrolebinding.rbac.authorization.k8s.io/dex unchanged
clusterrolebinding.rbac.authorization.k8s.io/eventing-controller unchanged
clusterrolebinding.rbac.authorization.k8s.io/eventing-controller-manipulator unchanged
clusterrolebinding.rbac.authorization.k8s.io/eventing-controller-resolver unchanged
clusterrolebinding.rbac.authorization.k8s.io/eventing-controller-source-observer unchanged
clusterrolebinding.rbac.authorization.k8s.io/eventing-controller-sources-controller unchanged
clusterrolebinding.rbac.authorization.k8s.io/eventing-webhook unchanged
clusterrolebinding.rbac.authorization.k8s.io/eventing-webhook-podspecable-binding unchanged
clusterrolebinding.rbac.authorization.k8s.io/eventing-webhook-resolver unchanged
clusterrolebinding.rbac.authorization.k8s.io/istio-reader-clusterrole-istio-system unchanged
clusterrolebinding.rbac.authorization.k8s.io/istio-reader-istio-system unchanged
clusterrolebinding.rbac.authorization.k8s.io/istiod-clusterrole-istio-system unchanged
clusterrolebinding.rbac.authorization.k8s.io/istiod-gateway-controller-istio-system unchanged
clusterrolebinding.rbac.authorization.k8s.io/istiod-istio-system unchanged
clusterrolebinding.rbac.authorization.k8s.io/jupyter-web-app-cluster-role-binding unchanged
clusterrolebinding.rbac.authorization.k8s.io/katib-controller unchanged
clusterrolebinding.rbac.authorization.k8s.io/katib-ui unchanged
clusterrolebinding.rbac.authorization.k8s.io/knative-eventing-pingsource-mt-adapter unchanged
clusterrolebinding.rbac.authorization.k8s.io/knative-serving-controller-addressable-resolver unchanged
clusterrolebinding.rbac.authorization.k8s.io/knative-serving-controller-admin unchanged
clusterrolebinding.rbac.authorization.k8s.io/kserve-manager-rolebinding unchanged
clusterrolebinding.rbac.authorization.k8s.io/kserve-models-web-app-binding unchanged
clusterrolebinding.rbac.authorization.k8s.io/kserve-proxy-rolebinding unchanged
clusterrolebinding.rbac.authorization.k8s.io/kubeflow-pipelines-cache-binding unchanged
clusterrolebinding.rbac.authorization.k8s.io/kubeflow-pipelines-metadata-writer-binding unchanged
clusterrolebinding.rbac.authorization.k8s.io/meta-controller-cluster-role-binding unchanged
clusterrolebinding.rbac.authorization.k8s.io/ml-pipeline unchanged
clusterrolebinding.rbac.authorization.k8s.io/ml-pipeline-persistenceagent-binding unchanged
clusterrolebinding.rbac.authorization.k8s.io/ml-pipeline-scheduledworkflow-binding unchanged
clusterrolebinding.rbac.authorization.k8s.io/ml-pipeline-ui unchanged
clusterrolebinding.rbac.authorization.k8s.io/ml-pipeline-viewer-crd-binding unchanged
clusterrolebinding.rbac.authorization.k8s.io/notebook-controller-role-binding unchanged
clusterrolebinding.rbac.authorization.k8s.io/profiles-cluster-rolebinding unchanged
clusterrolebinding.rbac.authorization.k8s.io/tensorboard-controller-manager-rolebinding unchanged
clusterrolebinding.rbac.authorization.k8s.io/tensorboard-controller-proxy-rolebinding unchanged
clusterrolebinding.rbac.authorization.k8s.io/tensorboards-web-app-cluster-role-binding unchanged
clusterrolebinding.rbac.authorization.k8s.io/training-operator unchanged
clusterrolebinding.rbac.authorization.k8s.io/volumes-web-app-cluster-role-binding unchanged
configmap/dex unchanged
configmap/istio unchanged
configmap/istio-sidecar-injector unchanged
configmap/oidc-authservice-parameters unchanged
configmap/config-br-default-channel unchanged
configmap/config-br-defaults unchanged
configmap/config-features unchanged
configmap/config-kreference-mapping unchanged
configmap/config-leader-election unchanged
configmap/config-logging unchanged
configmap/config-observability unchanged
configmap/config-ping-defaults unchanged
configmap/config-tracing unchanged
configmap/default-ch-webhook unchanged
configmap/config-autoscaler unchanged
configmap/config-defaults unchanged
configmap/config-deployment unchanged
configmap/config-domain unchanged
configmap/config-features unchanged
configmap/config-gc unchanged
configmap/config-istio unchanged
configmap/config-leader-election unchanged
configmap/config-logging unchanged
configmap/config-network unchanged
configmap/config-observability unchanged
configmap/config-tracing unchanged
configmap/centraldashboard-config unchanged
configmap/centraldashboard-parameters unchanged
configmap/inferenceservice-config unchanged
configmap/jupyter-web-app-config-c765bftc87 unchanged
configmap/jupyter-web-app-logos unchanged
configmap/jupyter-web-app-parameters-42k97gcbmb unchanged
configmap/katib-config unchanged
configmap/kfp-launcher unchanged
configmap/kserve-config unchanged
configmap/kserve-models-web-app-config unchanged
configmap/kubeflow-pipelines-profile-controller-code-hdk828hd6c unchanged
configmap/kubeflow-pipelines-profile-controller-env-5252m69c4c unchanged
configmap/metadata-grpc-configmap unchanged
configmap/ml-pipeline-ui-configmap unchanged
configmap/namespace-labels-data-4df5t8mdgf unchanged
configmap/notebook-controller-config-m44cmb547t unchanged
configmap/persistenceagent-config-hkgkmd64bh unchanged
configmap/pipeline-api-server-config-dc9hkg52h6 unchanged
configmap/pipeline-install-config unchanged
configmap/profiles-config-46c7tgh6fd unchanged
configmap/tensorboard-controller-config-dg89gdkk47 unchanged
configmap/tensorboards-web-app-parameters-642bbg7t66 unchanged
configmap/trial-templates unchanged
configmap/volumes-web-app-parameters-57h65c44mg unchanged
configmap/workflow-controller-configmap unchanged
configmap/default-install-config-9h2h2b6hbk unchanged
secret/dex-oidc-client unchanged
secret/oidc-authservice-client unchanged
secret/eventing-webhook-certs unchanged
secret/domainmapping-webhook-certs unchanged
secret/net-istio-webhook-certs unchanged
secret/webhook-certs unchanged
secret/katib-mysql-secrets unchanged
secret/kserve-webhook-server-secret unchanged
secret/mlpipeline-minio-artifact configured
secret/mysql-secret configured
service/dex unchanged
service/cert-manager unchanged
service/cert-manager-webhook unchanged
service/authservice unchanged
service/cluster-local-gateway unchanged
service/istio-ingressgateway unchanged
service/istiod unchanged
service/knative-local-gateway unchanged
service/eventing-webhook unchanged
service/activator-service unchanged
service/autoscaler unchanged
service/controller unchanged
service/domainmapping-webhook unchanged
service/net-istio-webhook unchanged
service/webhook unchanged
service/admission-webhook-service unchanged
service/cache-server unchanged
service/centraldashboard unchanged
service/jupyter-web-app-service unchanged
service/katib-controller unchanged
service/katib-db-manager unchanged
service/katib-mysql unchanged
service/katib-ui unchanged
service/kserve-controller-manager-metrics-service unchanged
service/kserve-controller-manager-service unchanged
service/kserve-models-web-app unchanged
service/kserve-webhook-server-service unchanged
service/kubeflow-pipelines-profile-controller unchanged
service/metadata-envoy-service unchanged
service/metadata-grpc-service unchanged
service/minio-service unchanged
service/ml-pipeline unchanged
service/ml-pipeline-ui unchanged
service/ml-pipeline-visualizationserver unchanged
service/mysql unchanged
service/notebook-controller-service unchanged
service/profiles-kfam unchanged
service/tensorboard-controller-controller-manager-metrics-service unchanged
service/tensorboards-web-app-service unchanged
service/training-operator unchanged
service/volumes-web-app-service unchanged
service/workflow-controller-metrics unchanged
priorityclass.scheduling.k8s.io/workflow-controller unchanged
persistentvolumeclaim/authservice-pvc unchanged
persistentvolumeclaim/katib-mysql unchanged
persistentvolumeclaim/minio-pvc unchanged
persistentvolumeclaim/mysql-pv-claim unchanged
deployment.apps/dex unchanged
deployment.apps/cert-manager unchanged
deployment.apps/cert-manager-cainjector unchanged
deployment.apps/cert-manager-webhook unchanged
deployment.apps/cluster-local-gateway configured
deployment.apps/istio-ingressgateway configured
deployment.apps/istiod configured
deployment.apps/eventing-controller unchanged
deployment.apps/eventing-webhook unchanged
deployment.apps/pingsource-mt-adapter configured
deployment.apps/activator configured
deployment.apps/autoscaler configured
deployment.apps/controller configured
deployment.apps/domain-mapping unchanged
deployment.apps/domainmapping-webhook unchanged
deployment.apps/net-istio-controller unchanged
deployment.apps/net-istio-webhook unchanged
deployment.apps/webhook unchanged
deployment.apps/admission-webhook-deployment unchanged
deployment.apps/cache-server configured
deployment.apps/centraldashboard configured
deployment.apps/jupyter-web-app-deployment configured
deployment.apps/katib-controller unchanged
deployment.apps/katib-db-manager unchanged
deployment.apps/katib-mysql unchanged
deployment.apps/katib-ui unchanged
deployment.apps/kserve-models-web-app configured
deployment.apps/kubeflow-pipelines-profile-controller unchanged
deployment.apps/metadata-envoy-deployment unchanged
deployment.apps/metadata-grpc-deployment unchanged
deployment.apps/metadata-writer configured
deployment.apps/minio unchanged
deployment.apps/ml-pipeline configured
deployment.apps/ml-pipeline-persistenceagent configured
deployment.apps/ml-pipeline-scheduledworkflow configured
deployment.apps/ml-pipeline-ui configured
deployment.apps/ml-pipeline-viewer-crd configured
deployment.apps/ml-pipeline-visualizationserver unchanged
deployment.apps/mysql unchanged
deployment.apps/notebook-controller-deployment unchanged
deployment.apps/profiles-deployment unchanged
deployment.apps/tensorboard-controller-deployment unchanged
deployment.apps/tensorboards-web-app-deployment configured
deployment.apps/training-operator unchanged
deployment.apps/volumes-web-app-deployment configured
deployment.apps/workflow-controller unchanged
statefulset.apps/authservice unchanged
statefulset.apps/kserve-controller-manager unchanged
statefulset.apps/metacontroller configured
poddisruptionbudget.policy/eventing-webhook created
poddisruptionbudget.policy/activator-pdb configured
poddisruptionbudget.policy/webhook-pdb configured
horizontalpodautoscaler.autoscaling/eventing-webhook created
horizontalpodautoscaler.autoscaling/activator created
horizontalpodautoscaler.autoscaling/webhook created
image.caching.internal.knative.dev/queue-proxy unchanged
certificate.cert-manager.io/admission-webhook-cert unchanged
certificate.cert-manager.io/katib-webhook-cert unchanged
certificate.cert-manager.io/kfp-cache-cert unchanged
certificate.cert-manager.io/serving-cert unchanged
clusterissuer.cert-manager.io/kubeflow-self-signing-issuer unchanged
issuer.cert-manager.io/admission-webhook-selfsigned-issuer unchanged
issuer.cert-manager.io/katib-selfsigned-issuer unchanged
issuer.cert-manager.io/kfp-cache-selfsigned-issuer unchanged
issuer.cert-manager.io/selfsigned-issuer unchanged
profile.kubeflow.org/kubeflow-user-example-com unchanged
compositecontroller.metacontroller.k8s.io/kubeflow-pipelines-profile-controller unchanged
destinationrule.networking.istio.io/knative unchanged
destinationrule.networking.istio.io/metadata-grpc-service unchanged
destinationrule.networking.istio.io/ml-pipeline unchanged
destinationrule.networking.istio.io/ml-pipeline-minio unchanged
destinationrule.networking.istio.io/ml-pipeline-mysql unchanged
destinationrule.networking.istio.io/ml-pipeline-ui unchanged
destinationrule.networking.istio.io/ml-pipeline-visualizationserver unchanged
envoyfilter.networking.istio.io/authn-filter unchanged
envoyfilter.networking.istio.io/stats-filter-1.11 unchanged
envoyfilter.networking.istio.io/stats-filter-1.12 unchanged
envoyfilter.networking.istio.io/stats-filter-1.13 unchanged
envoyfilter.networking.istio.io/stats-filter-1.14 unchanged
envoyfilter.networking.istio.io/stats-filter-1.15 unchanged
envoyfilter.networking.istio.io/tcp-stats-filter-1.11 unchanged
envoyfilter.networking.istio.io/tcp-stats-filter-1.12 unchanged
envoyfilter.networking.istio.io/tcp-stats-filter-1.13 unchanged
envoyfilter.networking.istio.io/tcp-stats-filter-1.14 unchanged
envoyfilter.networking.istio.io/tcp-stats-filter-1.15 unchanged
envoyfilter.networking.istio.io/x-forwarded-host unchanged
gateway.networking.istio.io/cluster-local-gateway unchanged
gateway.networking.istio.io/istio-ingressgateway unchanged
gateway.networking.istio.io/knative-local-gateway unchanged
gateway.networking.istio.io/kubeflow-gateway unchanged
virtualservice.networking.istio.io/dex unchanged
virtualservice.networking.istio.io/centraldashboard unchanged
virtualservice.networking.istio.io/jupyter-web-app-jupyter-web-app unchanged
virtualservice.networking.istio.io/katib-ui unchanged
virtualservice.networking.istio.io/metadata-grpc unchanged
virtualservice.networking.istio.io/ml-pipeline-ui unchanged
virtualservice.networking.istio.io/profiles-kfam unchanged
virtualservice.networking.istio.io/tensorboards-web-app-tensorboards-web-app unchanged
virtualservice.networking.istio.io/volumes-web-app-volumes-web-app unchanged
virtualservice.networking.istio.io/kserve-models-web-app unchanged
authorizationpolicy.security.istio.io/cluster-local-gateway unchanged
authorizationpolicy.security.istio.io/global-deny-all unchanged
authorizationpolicy.security.istio.io/istio-ingressgateway unchanged
authorizationpolicy.security.istio.io/activator-service unchanged
authorizationpolicy.security.istio.io/autoscaler unchanged
authorizationpolicy.security.istio.io/controller unchanged
authorizationpolicy.security.istio.io/istio-webhook unchanged
authorizationpolicy.security.istio.io/webhook unchanged
authorizationpolicy.security.istio.io/central-dashboard unchanged
authorizationpolicy.security.istio.io/kserve-models-web-app unchanged
authorizationpolicy.security.istio.io/metadata-grpc-service unchanged
authorizationpolicy.security.istio.io/minio-service unchanged
authorizationpolicy.security.istio.io/ml-pipeline unchanged
authorizationpolicy.security.istio.io/ml-pipeline-ui unchanged
authorizationpolicy.security.istio.io/ml-pipeline-visualizationserver unchanged
authorizationpolicy.security.istio.io/mysql unchanged
authorizationpolicy.security.istio.io/profiles-kfam unchanged
authorizationpolicy.security.istio.io/service-cache-server unchanged
peerauthentication.security.istio.io/domainmapping-webhook unchanged
peerauthentication.security.istio.io/net-istio-webhook unchanged
peerauthentication.security.istio.io/webhook unchanged
clusterservingruntime.serving.kserve.io/kserve-lgbserver unchanged
clusterservingruntime.serving.kserve.io/kserve-mlserver unchanged
clusterservingruntime.serving.kserve.io/kserve-paddleserver unchanged
clusterservingruntime.serving.kserve.io/kserve-pmmlserver unchanged
clusterservingruntime.serving.kserve.io/kserve-sklearnserver unchanged
clusterservingruntime.serving.kserve.io/kserve-tensorflow-serving unchanged
clusterservingruntime.serving.kserve.io/kserve-torchserve unchanged
clusterservingruntime.serving.kserve.io/kserve-tritonserver unchanged
clusterservingruntime.serving.kserve.io/kserve-xgbserver unchanged
mutatingwebhookconfiguration.admissionregistration.k8s.io/admission-webhook-mutating-webhook-configuration configured
mutatingwebhookconfiguration.admissionregistration.k8s.io/cache-webhook-kubeflow configured
mutatingwebhookconfiguration.admissionregistration.k8s.io/cert-manager-webhook configured
mutatingwebhookconfiguration.admissionregistration.k8s.io/inferenceservice.serving.kserve.io configured
mutatingwebhookconfiguration.admissionregistration.k8s.io/istio-sidecar-injector configured
mutatingwebhookconfiguration.admissionregistration.k8s.io/katib.kubeflow.org configured
mutatingwebhookconfiguration.admissionregistration.k8s.io/sinkbindings.webhook.sources.knative.dev unchanged
mutatingwebhookconfiguration.admissionregistration.k8s.io/webhook.domainmapping.serving.knative.dev unchanged
mutatingwebhookconfiguration.admissionregistration.k8s.io/webhook.eventing.knative.dev unchanged
mutatingwebhookconfiguration.admissionregistration.k8s.io/webhook.istio.networking.internal.knative.dev unchanged
mutatingwebhookconfiguration.admissionregistration.k8s.io/webhook.serving.knative.dev unchanged
validatingwebhookconfiguration.admissionregistration.k8s.io/cert-manager-webhook configured
validatingwebhookconfiguration.admissionregistration.k8s.io/config.webhook.eventing.knative.dev unchanged
validatingwebhookconfiguration.admissionregistration.k8s.io/config.webhook.istio.networking.internal.knative.dev unchanged
validatingwebhookconfiguration.admissionregistration.k8s.io/config.webhook.serving.knative.dev unchanged
validatingwebhookconfiguration.admissionregistration.k8s.io/inferenceservice.serving.kserve.io configured
validatingwebhookconfiguration.admissionregistration.k8s.io/istio-validator-istio-system configured
validatingwebhookconfiguration.admissionregistration.k8s.io/katib.kubeflow.org configured
validatingwebhookconfiguration.admissionregistration.k8s.io/trainedmodel.serving.kserve.io configured
validatingwebhookconfiguration.admissionregistration.k8s.io/validation.webhook.domainmapping.serving.knative.dev unchanged
validatingwebhookconfiguration.admissionregistration.k8s.io/validation.webhook.eventing.knative.dev unchanged
validatingwebhookconfiguration.admissionregistration.k8s.io/validation.webhook.serving.knative.dev unchanged

#1.7.0
Retrying to apply resources
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesJson6902' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesJson6902' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
2023/04/16 13:37:40 well-defined vars that were never replaced: kfp-app-version,kfp-app-name
namespace/auth unchanged
namespace/cert-manager unchanged
namespace/istio-system unchanged
namespace/knative-eventing unchanged
namespace/knative-serving unchanged
namespace/kubeflow unchanged
customresourcedefinition.apiextensions.k8s.io/apiserversources.sources.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/authcodes.dex.coreos.com unchanged
customresourcedefinition.apiextensions.k8s.io/authorizationpolicies.security.istio.io unchanged
customresourcedefinition.apiextensions.k8s.io/brokers.eventing.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/certificaterequests.cert-manager.io unchanged
customresourcedefinition.apiextensions.k8s.io/certificates.cert-manager.io unchanged
customresourcedefinition.apiextensions.k8s.io/certificates.networking.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/challenges.acme.cert-manager.io unchanged
customresourcedefinition.apiextensions.k8s.io/channels.messaging.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/clusterdomainclaims.networking.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/clusterissuers.cert-manager.io unchanged
customresourcedefinition.apiextensions.k8s.io/clusterservingruntimes.serving.kserve.io configured
customresourcedefinition.apiextensions.k8s.io/clusterworkflowtemplates.argoproj.io unchanged
customresourcedefinition.apiextensions.k8s.io/compositecontrollers.metacontroller.k8s.io configured
customresourcedefinition.apiextensions.k8s.io/configurations.serving.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/containersources.sources.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/controllerrevisions.metacontroller.k8s.io configured
customresourcedefinition.apiextensions.k8s.io/cronworkflows.argoproj.io unchanged
customresourcedefinition.apiextensions.k8s.io/decoratorcontrollers.metacontroller.k8s.io configured
customresourcedefinition.apiextensions.k8s.io/destinationrules.networking.istio.io unchanged
customresourcedefinition.apiextensions.k8s.io/domainmappings.serving.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/envoyfilters.networking.istio.io unchanged
customresourcedefinition.apiextensions.k8s.io/eventtypes.eventing.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/experiments.kubeflow.org unchanged
customresourcedefinition.apiextensions.k8s.io/gateways.networking.istio.io unchanged
customresourcedefinition.apiextensions.k8s.io/images.caching.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/inferencegraphs.serving.kserve.io configured
Warning: Detected changes to resource inferenceservices.serving.kserve.io which is currently being deleted.
customresourcedefinition.apiextensions.k8s.io/inferenceservices.serving.kserve.io configured
customresourcedefinition.apiextensions.k8s.io/ingresses.networking.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/issuers.cert-manager.io unchanged
customresourcedefinition.apiextensions.k8s.io/istiooperators.install.istio.io unchanged
customresourcedefinition.apiextensions.k8s.io/metrics.autoscaling.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/mpijobs.kubeflow.org unchanged
customresourcedefinition.apiextensions.k8s.io/mxjobs.kubeflow.org unchanged
customresourcedefinition.apiextensions.k8s.io/notebooks.kubeflow.org configured
customresourcedefinition.apiextensions.k8s.io/orders.acme.cert-manager.io unchanged
customresourcedefinition.apiextensions.k8s.io/paddlejobs.kubeflow.org unchanged
customresourcedefinition.apiextensions.k8s.io/parallels.flows.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/peerauthentications.security.istio.io unchanged
customresourcedefinition.apiextensions.k8s.io/pingsources.sources.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/podautoscalers.autoscaling.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/poddefaults.kubeflow.org configured
customresourcedefinition.apiextensions.k8s.io/profiles.kubeflow.org configured
customresourcedefinition.apiextensions.k8s.io/proxyconfigs.networking.istio.io unchanged
customresourcedefinition.apiextensions.k8s.io/pytorchjobs.kubeflow.org unchanged
customresourcedefinition.apiextensions.k8s.io/requestauthentications.security.istio.io unchanged
customresourcedefinition.apiextensions.k8s.io/revisions.serving.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/routes.serving.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/scheduledworkflows.kubeflow.org unchanged
customresourcedefinition.apiextensions.k8s.io/sequences.flows.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/serverlessservices.networking.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/serviceentries.networking.istio.io unchanged
customresourcedefinition.apiextensions.k8s.io/services.serving.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/servingruntimes.serving.kserve.io configured
customresourcedefinition.apiextensions.k8s.io/sidecars.networking.istio.io unchanged
customresourcedefinition.apiextensions.k8s.io/sinkbindings.sources.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/subscriptions.messaging.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/suggestions.kubeflow.org unchanged
customresourcedefinition.apiextensions.k8s.io/telemetries.telemetry.istio.io unchanged
customresourcedefinition.apiextensions.k8s.io/tensorboards.tensorboard.kubeflow.org configured
customresourcedefinition.apiextensions.k8s.io/tfjobs.kubeflow.org unchanged
customresourcedefinition.apiextensions.k8s.io/trainedmodels.serving.kserve.io configured
customresourcedefinition.apiextensions.k8s.io/trials.kubeflow.org unchanged
customresourcedefinition.apiextensions.k8s.io/triggers.eventing.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/viewers.kubeflow.org unchanged
customresourcedefinition.apiextensions.k8s.io/virtualservices.networking.istio.io unchanged
customresourcedefinition.apiextensions.k8s.io/wasmplugins.extensions.istio.io unchanged
customresourcedefinition.apiextensions.k8s.io/workfloweventbindings.argoproj.io unchanged
customresourcedefinition.apiextensions.k8s.io/workflows.argoproj.io unchanged
customresourcedefinition.apiextensions.k8s.io/workflowtaskresults.argoproj.io unchanged
customresourcedefinition.apiextensions.k8s.io/workflowtasksets.argoproj.io unchanged
customresourcedefinition.apiextensions.k8s.io/workflowtemplates.argoproj.io unchanged
customresourcedefinition.apiextensions.k8s.io/workloadentries.networking.istio.io unchanged
customresourcedefinition.apiextensions.k8s.io/workloadgroups.networking.istio.io unchanged
customresourcedefinition.apiextensions.k8s.io/xgboostjobs.kubeflow.org unchanged
mutatingwebhookconfiguration.admissionregistration.k8s.io/admission-webhook-mutating-webhook-configuration configured
mutatingwebhookconfiguration.admissionregistration.k8s.io/cache-webhook-kubeflow configured
mutatingwebhookconfiguration.admissionregistration.k8s.io/cert-manager-webhook configured
mutatingwebhookconfiguration.admissionregistration.k8s.io/inferenceservice.serving.kserve.io configured
mutatingwebhookconfiguration.admissionregistration.k8s.io/istio-sidecar-injector configured
mutatingwebhookconfiguration.admissionregistration.k8s.io/katib.kubeflow.org configured
mutatingwebhookconfiguration.admissionregistration.k8s.io/sinkbindings.webhook.sources.knative.dev unchanged
mutatingwebhookconfiguration.admissionregistration.k8s.io/webhook.domainmapping.serving.knative.dev unchanged
mutatingwebhookconfiguration.admissionregistration.k8s.io/webhook.eventing.knative.dev unchanged
mutatingwebhookconfiguration.admissionregistration.k8s.io/webhook.istio.networking.internal.knative.dev unchanged
mutatingwebhookconfiguration.admissionregistration.k8s.io/webhook.serving.knative.dev unchanged
serviceaccount/dex unchanged
serviceaccount/cert-manager unchanged
serviceaccount/cert-manager-cainjector unchanged
serviceaccount/cert-manager-webhook unchanged
serviceaccount/authservice unchanged
serviceaccount/cluster-local-gateway-service-account unchanged
serviceaccount/istio-ingressgateway-service-account unchanged
serviceaccount/istio-reader-service-account unchanged
serviceaccount/istiod unchanged
serviceaccount/istiod-service-account unchanged
serviceaccount/eventing-controller unchanged
serviceaccount/eventing-webhook unchanged
serviceaccount/pingsource-mt-adapter unchanged
serviceaccount/controller unchanged
serviceaccount/admission-webhook-service-account unchanged
serviceaccount/argo unchanged
serviceaccount/centraldashboard unchanged
serviceaccount/jupyter-web-app-service-account unchanged
serviceaccount/katib-controller unchanged
serviceaccount/katib-ui unchanged
serviceaccount/kserve-controller-manager unchanged
serviceaccount/kserve-models-web-app unchanged
serviceaccount/kubeflow-pipelines-cache unchanged
serviceaccount/kubeflow-pipelines-container-builder unchanged
serviceaccount/kubeflow-pipelines-metadata-writer unchanged
serviceaccount/kubeflow-pipelines-viewer unchanged
serviceaccount/meta-controller-service unchanged
serviceaccount/metadata-grpc-server unchanged
serviceaccount/ml-pipeline unchanged
serviceaccount/ml-pipeline-persistenceagent unchanged
serviceaccount/ml-pipeline-scheduledworkflow unchanged
serviceaccount/ml-pipeline-ui unchanged
serviceaccount/ml-pipeline-viewer-crd-service-account unchanged
serviceaccount/ml-pipeline-visualizationserver unchanged
serviceaccount/mysql unchanged
serviceaccount/notebook-controller-service-account unchanged
serviceaccount/pipeline-runner unchanged
serviceaccount/profiles-controller-service-account unchanged
serviceaccount/tensorboard-controller-controller-manager unchanged
serviceaccount/tensorboards-web-app-service-account unchanged
serviceaccount/training-operator unchanged
serviceaccount/volumes-web-app-service-account unchanged
role.rbac.authorization.k8s.io/cert-manager-webhook:dynamic-serving unchanged
role.rbac.authorization.k8s.io/cluster-local-gateway-sds unchanged
role.rbac.authorization.k8s.io/istio-ingressgateway-sds unchanged
role.rbac.authorization.k8s.io/istiod unchanged
role.rbac.authorization.k8s.io/istiod-istio-system unchanged
role.rbac.authorization.k8s.io/knative-eventing-webhook unchanged
role.rbac.authorization.k8s.io/cert-manager-cainjector:leaderelection unchanged
role.rbac.authorization.k8s.io/cert-manager:leaderelection unchanged
role.rbac.authorization.k8s.io/argo-role unchanged
role.rbac.authorization.k8s.io/centraldashboard unchanged
role.rbac.authorization.k8s.io/jupyter-web-app-jupyter-notebook-role unchanged
role.rbac.authorization.k8s.io/kserve-leader-election-role unchanged
role.rbac.authorization.k8s.io/kubeflow-pipelines-cache-role unchanged
role.rbac.authorization.k8s.io/kubeflow-pipelines-metadata-writer-role unchanged
role.rbac.authorization.k8s.io/ml-pipeline unchanged
role.rbac.authorization.k8s.io/ml-pipeline-persistenceagent-role unchanged
role.rbac.authorization.k8s.io/ml-pipeline-scheduledworkflow-role unchanged
role.rbac.authorization.k8s.io/ml-pipeline-ui unchanged
role.rbac.authorization.k8s.io/ml-pipeline-viewer-controller-role unchanged
role.rbac.authorization.k8s.io/notebook-controller-leader-election-role unchanged
role.rbac.authorization.k8s.io/pipeline-runner unchanged
role.rbac.authorization.k8s.io/profiles-leader-election-role unchanged
role.rbac.authorization.k8s.io/tensorboard-controller-leader-election-role unchanged
clusterrole.rbac.authorization.k8s.io/addressable-resolver configured
clusterrole.rbac.authorization.k8s.io/admission-webhook-cluster-role unchanged
clusterrole.rbac.authorization.k8s.io/admission-webhook-kubeflow-poddefaults-admin configured
clusterrole.rbac.authorization.k8s.io/admission-webhook-kubeflow-poddefaults-edit configured
clusterrole.rbac.authorization.k8s.io/admission-webhook-kubeflow-poddefaults-view unchanged
clusterrole.rbac.authorization.k8s.io/aggregate-to-kubeflow-pipelines-edit unchanged
clusterrole.rbac.authorization.k8s.io/aggregate-to-kubeflow-pipelines-view unchanged
clusterrole.rbac.authorization.k8s.io/argo-aggregate-to-admin unchanged
clusterrole.rbac.authorization.k8s.io/argo-aggregate-to-edit unchanged
clusterrole.rbac.authorization.k8s.io/argo-aggregate-to-view unchanged
clusterrole.rbac.authorization.k8s.io/argo-cluster-role unchanged
clusterrole.rbac.authorization.k8s.io/authn-delegator unchanged
clusterrole.rbac.authorization.k8s.io/broker-addressable-resolver unchanged
clusterrole.rbac.authorization.k8s.io/builtin-podspecable-binding unchanged
clusterrole.rbac.authorization.k8s.io/centraldashboard unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-cainjector unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-approve:cert-manager-io unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-certificates unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-certificatesigningrequests unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-challenges unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-clusterissuers unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-ingress-shim unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-issuers unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-orders unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-edit unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-view unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-webhook:subjectaccessreviews unchanged
clusterrole.rbac.authorization.k8s.io/channel-addressable-resolver unchanged
clusterrole.rbac.authorization.k8s.io/channelable-manipulator configured
clusterrole.rbac.authorization.k8s.io/dex unchanged
clusterrole.rbac.authorization.k8s.io/eventing-broker-filter unchanged
clusterrole.rbac.authorization.k8s.io/eventing-broker-ingress unchanged
clusterrole.rbac.authorization.k8s.io/eventing-config-reader unchanged
clusterrole.rbac.authorization.k8s.io/eventing-sources-source-observer unchanged
clusterrole.rbac.authorization.k8s.io/flows-addressable-resolver unchanged
clusterrole.rbac.authorization.k8s.io/istio-reader-clusterrole-istio-system unchanged
clusterrole.rbac.authorization.k8s.io/istio-reader-istio-system unchanged
clusterrole.rbac.authorization.k8s.io/istiod-clusterrole-istio-system unchanged
clusterrole.rbac.authorization.k8s.io/istiod-gateway-controller-istio-system unchanged
clusterrole.rbac.authorization.k8s.io/istiod-istio-system unchanged
clusterrole.rbac.authorization.k8s.io/jupyter-web-app-cluster-role unchanged
clusterrole.rbac.authorization.k8s.io/jupyter-web-app-kubeflow-notebook-ui-admin configured
clusterrole.rbac.authorization.k8s.io/jupyter-web-app-kubeflow-notebook-ui-edit unchanged
clusterrole.rbac.authorization.k8s.io/jupyter-web-app-kubeflow-notebook-ui-view unchanged
clusterrole.rbac.authorization.k8s.io/katib-controller unchanged
clusterrole.rbac.authorization.k8s.io/katib-ui unchanged
clusterrole.rbac.authorization.k8s.io/knative-bindings-namespaced-admin unchanged
clusterrole.rbac.authorization.k8s.io/knative-eventing-controller unchanged
clusterrole.rbac.authorization.k8s.io/knative-eventing-namespaced-admin unchanged
clusterrole.rbac.authorization.k8s.io/knative-eventing-namespaced-edit unchanged
clusterrole.rbac.authorization.k8s.io/knative-eventing-namespaced-view unchanged
clusterrole.rbac.authorization.k8s.io/knative-eventing-pingsource-mt-adapter unchanged
clusterrole.rbac.authorization.k8s.io/knative-eventing-sources-controller unchanged
clusterrole.rbac.authorization.k8s.io/knative-eventing-webhook unchanged
clusterrole.rbac.authorization.k8s.io/knative-flows-namespaced-admin unchanged
clusterrole.rbac.authorization.k8s.io/knative-messaging-namespaced-admin unchanged
clusterrole.rbac.authorization.k8s.io/knative-serving-addressable-resolver unchanged
clusterrole.rbac.authorization.k8s.io/knative-serving-admin unchanged
clusterrole.rbac.authorization.k8s.io/knative-serving-aggregated-addressable-resolver unchanged
clusterrole.rbac.authorization.k8s.io/knative-serving-core unchanged
clusterrole.rbac.authorization.k8s.io/knative-serving-istio unchanged
clusterrole.rbac.authorization.k8s.io/knative-serving-namespaced-admin unchanged
clusterrole.rbac.authorization.k8s.io/knative-serving-namespaced-edit unchanged
clusterrole.rbac.authorization.k8s.io/knative-serving-namespaced-view unchanged
clusterrole.rbac.authorization.k8s.io/knative-serving-podspecable-binding unchanged
clusterrole.rbac.authorization.k8s.io/knative-sources-namespaced-admin unchanged
clusterrole.rbac.authorization.k8s.io/kserve-manager-role configured
clusterrole.rbac.authorization.k8s.io/kserve-models-web-app-cluster-role unchanged
clusterrole.rbac.authorization.k8s.io/kserve-proxy-role unchanged
clusterrole.rbac.authorization.k8s.io/kubeflow-admin configured
clusterrole.rbac.authorization.k8s.io/kubeflow-edit configured
clusterrole.rbac.authorization.k8s.io/kubeflow-istio-admin configured
clusterrole.rbac.authorization.k8s.io/kubeflow-istio-edit unchanged
clusterrole.rbac.authorization.k8s.io/kubeflow-istio-view unchanged
clusterrole.rbac.authorization.k8s.io/kubeflow-katib-admin configured
clusterrole.rbac.authorization.k8s.io/kubeflow-katib-edit unchanged
clusterrole.rbac.authorization.k8s.io/kubeflow-katib-view unchanged
clusterrole.rbac.authorization.k8s.io/kubeflow-kserve-admin configured
clusterrole.rbac.authorization.k8s.io/kubeflow-kserve-edit unchanged
clusterrole.rbac.authorization.k8s.io/kubeflow-kserve-view unchanged
clusterrole.rbac.authorization.k8s.io/kubeflow-kubernetes-admin unchanged
clusterrole.rbac.authorization.k8s.io/kubeflow-kubernetes-edit unchanged
clusterrole.rbac.authorization.k8s.io/kubeflow-kubernetes-view unchanged
clusterrole.rbac.authorization.k8s.io/kubeflow-pipelines-cache-role unchanged
clusterrole.rbac.authorization.k8s.io/kubeflow-pipelines-edit configured
clusterrole.rbac.authorization.k8s.io/kubeflow-pipelines-metadata-writer-role unchanged
clusterrole.rbac.authorization.k8s.io/kubeflow-pipelines-view configured
clusterrole.rbac.authorization.k8s.io/kubeflow-training-admin configured
clusterrole.rbac.authorization.k8s.io/kubeflow-training-edit unchanged
clusterrole.rbac.authorization.k8s.io/kubeflow-training-view unchanged
clusterrole.rbac.authorization.k8s.io/kubeflow-view configured
clusterrole.rbac.authorization.k8s.io/meta-channelable-manipulator unchanged
clusterrole.rbac.authorization.k8s.io/ml-pipeline unchanged
clusterrole.rbac.authorization.k8s.io/ml-pipeline-persistenceagent-role unchanged
clusterrole.rbac.authorization.k8s.io/ml-pipeline-scheduledworkflow-role unchanged
clusterrole.rbac.authorization.k8s.io/ml-pipeline-ui unchanged
clusterrole.rbac.authorization.k8s.io/ml-pipeline-viewer-controller-role unchanged
clusterrole.rbac.authorization.k8s.io/notebook-controller-kubeflow-notebooks-admin configured
clusterrole.rbac.authorization.k8s.io/notebook-controller-kubeflow-notebooks-edit unchanged
clusterrole.rbac.authorization.k8s.io/notebook-controller-kubeflow-notebooks-view unchanged
clusterrole.rbac.authorization.k8s.io/notebook-controller-role configured
clusterrole.rbac.authorization.k8s.io/podspecable-binding configured
clusterrole.rbac.authorization.k8s.io/service-addressable-resolver unchanged
clusterrole.rbac.authorization.k8s.io/serving-addressable-resolver unchanged
clusterrole.rbac.authorization.k8s.io/source-observer configured
clusterrole.rbac.authorization.k8s.io/tensorboard-controller-manager-role configured
clusterrole.rbac.authorization.k8s.io/tensorboard-controller-metrics-reader unchanged
clusterrole.rbac.authorization.k8s.io/tensorboard-controller-proxy-role unchanged
clusterrole.rbac.authorization.k8s.io/tensorboards-web-app-cluster-role unchanged
clusterrole.rbac.authorization.k8s.io/tensorboards-web-app-kubeflow-tensorboard-ui-admin configured
clusterrole.rbac.authorization.k8s.io/tensorboards-web-app-kubeflow-tensorboard-ui-edit unchanged
clusterrole.rbac.authorization.k8s.io/tensorboards-web-app-kubeflow-tensorboard-ui-view unchanged
clusterrole.rbac.authorization.k8s.io/training-operator unchanged
clusterrole.rbac.authorization.k8s.io/volumes-web-app-cluster-role unchanged
clusterrole.rbac.authorization.k8s.io/volumes-web-app-kubeflow-volume-ui-admin configured
clusterrole.rbac.authorization.k8s.io/volumes-web-app-kubeflow-volume-ui-edit unchanged
clusterrole.rbac.authorization.k8s.io/volumes-web-app-kubeflow-volume-ui-view unchanged
rolebinding.rbac.authorization.k8s.io/cert-manager-webhook:dynamic-serving configured
rolebinding.rbac.authorization.k8s.io/cluster-local-gateway-sds unchanged
rolebinding.rbac.authorization.k8s.io/istio-ingressgateway-sds unchanged
rolebinding.rbac.authorization.k8s.io/istiod unchanged
rolebinding.rbac.authorization.k8s.io/istiod-istio-system unchanged
rolebinding.rbac.authorization.k8s.io/eventing-webhook unchanged
rolebinding.rbac.authorization.k8s.io/cert-manager-cainjector:leaderelection unchanged
rolebinding.rbac.authorization.k8s.io/cert-manager:leaderelection configured
rolebinding.rbac.authorization.k8s.io/argo-binding unchanged
rolebinding.rbac.authorization.k8s.io/centraldashboard unchanged
rolebinding.rbac.authorization.k8s.io/jupyter-web-app-jupyter-notebook-role-binding unchanged
rolebinding.rbac.authorization.k8s.io/kserve-leader-election-rolebinding unchanged
rolebinding.rbac.authorization.k8s.io/kubeflow-pipelines-cache-binding unchanged
rolebinding.rbac.authorization.k8s.io/kubeflow-pipelines-metadata-writer-binding unchanged
rolebinding.rbac.authorization.k8s.io/ml-pipeline unchanged
rolebinding.rbac.authorization.k8s.io/ml-pipeline-persistenceagent-binding unchanged
rolebinding.rbac.authorization.k8s.io/ml-pipeline-scheduledworkflow-binding unchanged
rolebinding.rbac.authorization.k8s.io/ml-pipeline-ui unchanged
rolebinding.rbac.authorization.k8s.io/ml-pipeline-viewer-crd-binding unchanged
rolebinding.rbac.authorization.k8s.io/notebook-controller-leader-election-rolebinding unchanged
rolebinding.rbac.authorization.k8s.io/pipeline-runner-binding unchanged
rolebinding.rbac.authorization.k8s.io/profiles-leader-election-rolebinding unchanged
rolebinding.rbac.authorization.k8s.io/tensorboard-controller-leader-election-rolebinding unchanged
clusterrolebinding.rbac.authorization.k8s.io/admission-webhook-cluster-role-binding unchanged
clusterrolebinding.rbac.authorization.k8s.io/argo-binding unchanged
clusterrolebinding.rbac.authorization.k8s.io/authn-delegators unchanged
clusterrolebinding.rbac.authorization.k8s.io/centraldashboard unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-cainjector unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-approve:cert-manager-io unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-certificates unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-certificatesigningrequests unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-challenges unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-clusterissuers unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-ingress-shim unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-issuers unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-orders unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-webhook:subjectaccessreviews configured
clusterrolebinding.rbac.authorization.k8s.io/dex unchanged
clusterrolebinding.rbac.authorization.k8s.io/eventing-controller unchanged
clusterrolebinding.rbac.authorization.k8s.io/eventing-controller-manipulator unchanged
clusterrolebinding.rbac.authorization.k8s.io/eventing-controller-resolver unchanged
clusterrolebinding.rbac.authorization.k8s.io/eventing-controller-source-observer unchanged
clusterrolebinding.rbac.authorization.k8s.io/eventing-controller-sources-controller unchanged
clusterrolebinding.rbac.authorization.k8s.io/eventing-webhook unchanged
clusterrolebinding.rbac.authorization.k8s.io/eventing-webhook-podspecable-binding unchanged
clusterrolebinding.rbac.authorization.k8s.io/eventing-webhook-resolver unchanged
clusterrolebinding.rbac.authorization.k8s.io/istio-reader-clusterrole-istio-system unchanged
clusterrolebinding.rbac.authorization.k8s.io/istio-reader-istio-system unchanged
clusterrolebinding.rbac.authorization.k8s.io/istiod-clusterrole-istio-system unchanged
clusterrolebinding.rbac.authorization.k8s.io/istiod-gateway-controller-istio-system unchanged
clusterrolebinding.rbac.authorization.k8s.io/istiod-istio-system unchanged
clusterrolebinding.rbac.authorization.k8s.io/jupyter-web-app-cluster-role-binding unchanged
clusterrolebinding.rbac.authorization.k8s.io/katib-controller unchanged
clusterrolebinding.rbac.authorization.k8s.io/katib-ui unchanged
clusterrolebinding.rbac.authorization.k8s.io/knative-eventing-pingsource-mt-adapter unchanged
clusterrolebinding.rbac.authorization.k8s.io/knative-serving-controller-addressable-resolver unchanged
clusterrolebinding.rbac.authorization.k8s.io/knative-serving-controller-admin unchanged
clusterrolebinding.rbac.authorization.k8s.io/kserve-manager-rolebinding unchanged
clusterrolebinding.rbac.authorization.k8s.io/kserve-models-web-app-binding unchanged
clusterrolebinding.rbac.authorization.k8s.io/kserve-proxy-rolebinding unchanged
clusterrolebinding.rbac.authorization.k8s.io/kubeflow-pipelines-cache-binding unchanged
clusterrolebinding.rbac.authorization.k8s.io/kubeflow-pipelines-metadata-writer-binding unchanged
clusterrolebinding.rbac.authorization.k8s.io/meta-controller-cluster-role-binding unchanged
clusterrolebinding.rbac.authorization.k8s.io/ml-pipeline unchanged
clusterrolebinding.rbac.authorization.k8s.io/ml-pipeline-persistenceagent-binding unchanged
clusterrolebinding.rbac.authorization.k8s.io/ml-pipeline-scheduledworkflow-binding unchanged
clusterrolebinding.rbac.authorization.k8s.io/ml-pipeline-ui unchanged
clusterrolebinding.rbac.authorization.k8s.io/ml-pipeline-viewer-crd-binding unchanged
clusterrolebinding.rbac.authorization.k8s.io/notebook-controller-role-binding unchanged
clusterrolebinding.rbac.authorization.k8s.io/profiles-cluster-rolebinding unchanged
clusterrolebinding.rbac.authorization.k8s.io/tensorboard-controller-manager-rolebinding unchanged
clusterrolebinding.rbac.authorization.k8s.io/tensorboard-controller-proxy-rolebinding unchanged
clusterrolebinding.rbac.authorization.k8s.io/tensorboards-web-app-cluster-role-binding unchanged
clusterrolebinding.rbac.authorization.k8s.io/training-operator unchanged
clusterrolebinding.rbac.authorization.k8s.io/volumes-web-app-cluster-role-binding unchanged
configmap/dex unchanged
configmap/cert-manager-webhook configured
configmap/istio unchanged
configmap/istio-sidecar-injector unchanged
configmap/oidc-authservice-parameters unchanged
configmap/config-br-default-channel unchanged
configmap/config-br-defaults unchanged
configmap/config-features unchanged
configmap/config-kreference-mapping unchanged
configmap/config-leader-election unchanged
configmap/config-logging unchanged
configmap/config-observability unchanged
configmap/config-ping-defaults unchanged
configmap/config-sugar unchanged
configmap/config-tracing unchanged
configmap/default-ch-webhook unchanged
configmap/config-autoscaler unchanged
configmap/config-defaults unchanged
configmap/config-deployment unchanged
configmap/config-domain unchanged
configmap/config-features unchanged
configmap/config-gc unchanged
configmap/config-istio unchanged
configmap/config-leader-election unchanged
configmap/config-logging unchanged
configmap/config-network unchanged
configmap/config-observability unchanged
configmap/config-tracing unchanged
configmap/centraldashboard-config unchanged
configmap/centraldashboard-parameters unchanged
configmap/inferenceservice-config unchanged
configmap/jupyter-web-app-config-84khm987mh unchanged
configmap/jupyter-web-app-logos unchanged
configmap/jupyter-web-app-parameters-42k97gcbmb unchanged
configmap/katib-config unchanged
configmap/kfp-launcher unchanged
configmap/kserve-models-web-app-config unchanged
configmap/kubeflow-pipelines-profile-controller-code-hdk828hd6c unchanged
configmap/kubeflow-pipelines-profile-controller-env-5252m69c4c unchanged
configmap/metadata-grpc-configmap unchanged
configmap/ml-pipeline-ui-configmap unchanged
configmap/namespace-labels-data-4df5t8mdgf unchanged
configmap/notebook-controller-config-dm5b6dd458 unchanged
configmap/persistenceagent-config-hkgkmd64bh unchanged
configmap/pipeline-api-server-config-dc9hkg52h6 unchanged
configmap/pipeline-install-config unchanged
configmap/profiles-config-46c7tgh6fd unchanged
configmap/tensorboard-controller-config-b98cb9gk9k unchanged
configmap/tensorboards-web-app-parameters-642bbg7t66 unchanged
configmap/trial-templates unchanged
configmap/volumes-web-app-parameters-57h65c44mg unchanged
configmap/workflow-controller-configmap unchanged
configmap/default-install-config-9h2h2b6hbk unchanged
secret/dex-oidc-client unchanged
secret/oidc-authservice-client unchanged
secret/eventing-webhook-certs unchanged
secret/domainmapping-webhook-certs unchanged
secret/knative-serving-certs unchanged
secret/net-istio-webhook-certs unchanged
secret/serving-certs-ctrl-ca unchanged
secret/webhook-certs unchanged
secret/katib-mysql-secrets unchanged
secret/kserve-webhook-server-secret unchanged
secret/mlpipeline-minio-artifact configured
secret/mysql-secret configured
service/dex unchanged
service/cert-manager unchanged
service/cert-manager-webhook unchanged
service/authservice unchanged
service/cluster-local-gateway unchanged
service/istio-ingressgateway unchanged
service/istiod unchanged
service/knative-local-gateway unchanged
service/eventing-webhook unchanged
service/activator-service unchanged
service/autoscaler unchanged
service/controller unchanged
service/domainmapping-webhook unchanged
service/net-istio-webhook unchanged
service/webhook unchanged
service/admission-webhook-service unchanged
service/cache-server unchanged
service/centraldashboard unchanged
service/jupyter-web-app-service unchanged
service/katib-controller unchanged
service/katib-db-manager unchanged
service/katib-mysql unchanged
service/katib-ui unchanged
service/kserve-controller-manager-metrics-service unchanged
service/kserve-controller-manager-service unchanged
service/kserve-models-web-app unchanged
service/kserve-webhook-server-service unchanged
service/kubeflow-pipelines-profile-controller unchanged
service/metadata-envoy-service unchanged
service/metadata-grpc-service unchanged
service/minio-service unchanged
service/ml-pipeline unchanged
service/ml-pipeline-ui unchanged
service/ml-pipeline-visualizationserver unchanged
service/mysql unchanged
service/notebook-controller-service unchanged
service/profiles-kfam unchanged
service/tensorboard-controller-controller-manager-metrics-service unchanged
service/tensorboards-web-app-service unchanged
service/training-operator unchanged
service/volumes-web-app-service unchanged
service/workflow-controller-metrics unchanged
priorityclass.scheduling.k8s.io/workflow-controller unchanged
persistentvolumeclaim/authservice-pvc unchanged
persistentvolumeclaim/katib-mysql unchanged
persistentvolumeclaim/minio-pvc unchanged
persistentvolumeclaim/mysql-pv-claim unchanged
deployment.apps/dex unchanged
deployment.apps/cert-manager unchanged
deployment.apps/cert-manager-cainjector unchanged
deployment.apps/cert-manager-webhook unchanged
deployment.apps/cluster-local-gateway configured
deployment.apps/istio-ingressgateway configured
deployment.apps/istiod configured
deployment.apps/eventing-controller unchanged
deployment.apps/eventing-webhook unchanged
deployment.apps/pingsource-mt-adapter configured
deployment.apps/activator configured
deployment.apps/autoscaler configured
deployment.apps/controller configured
deployment.apps/domain-mapping unchanged
deployment.apps/domainmapping-webhook unchanged
deployment.apps/net-istio-controller unchanged
deployment.apps/net-istio-webhook unchanged
deployment.apps/webhook unchanged
deployment.apps/admission-webhook-deployment unchanged
deployment.apps/cache-server configured
deployment.apps/centraldashboard configured
deployment.apps/jupyter-web-app-deployment configured
deployment.apps/katib-controller unchanged
deployment.apps/katib-db-manager unchanged
deployment.apps/katib-mysql unchanged
deployment.apps/katib-ui unchanged
deployment.apps/kserve-controller-manager unchanged
deployment.apps/kserve-models-web-app configured
deployment.apps/kubeflow-pipelines-profile-controller unchanged
deployment.apps/metadata-envoy-deployment unchanged
deployment.apps/metadata-grpc-deployment unchanged
deployment.apps/metadata-writer configured
deployment.apps/minio unchanged
deployment.apps/ml-pipeline configured
deployment.apps/ml-pipeline-persistenceagent configured
deployment.apps/ml-pipeline-scheduledworkflow configured
deployment.apps/ml-pipeline-ui configured
deployment.apps/ml-pipeline-viewer-crd configured
deployment.apps/ml-pipeline-visualizationserver unchanged
deployment.apps/mysql unchanged
deployment.apps/notebook-controller-deployment unchanged
deployment.apps/profiles-deployment unchanged
deployment.apps/tensorboard-controller-deployment unchanged
deployment.apps/tensorboards-web-app-deployment configured
deployment.apps/training-operator unchanged
deployment.apps/volumes-web-app-deployment configured
deployment.apps/workflow-controller unchanged
statefulset.apps/authservice unchanged
statefulset.apps/metacontroller configured
poddisruptionbudget.policy/cluster-local-gateway configured
poddisruptionbudget.policy/istio-ingressgateway configured
poddisruptionbudget.policy/istiod configured
poddisruptionbudget.policy/eventing-webhook configured
poddisruptionbudget.policy/activator-pdb configured
poddisruptionbudget.policy/webhook-pdb configured
horizontalpodautoscaler.autoscaling/eventing-webhook unchanged
horizontalpodautoscaler.autoscaling/activator unchanged
horizontalpodautoscaler.autoscaling/webhook unchanged
image.caching.internal.knative.dev/queue-proxy created
profile.kubeflow.org/kubeflow-user-example-com created
compositecontroller.metacontroller.k8s.io/kubeflow-pipelines-profile-controller created
destinationrule.networking.istio.io/knative created
destinationrule.networking.istio.io/jupyter-web-app created
destinationrule.networking.istio.io/metadata-grpc-service created
destinationrule.networking.istio.io/ml-pipeline created
destinationrule.networking.istio.io/ml-pipeline-minio created
destinationrule.networking.istio.io/ml-pipeline-mysql created
destinationrule.networking.istio.io/ml-pipeline-ui created
destinationrule.networking.istio.io/ml-pipeline-visualizationserver created
destinationrule.networking.istio.io/tensorboards-web-app created
destinationrule.networking.istio.io/volumes-web-app created
envoyfilter.networking.istio.io/authn-filter created
envoyfilter.networking.istio.io/stats-filter-1.13 created
envoyfilter.networking.istio.io/stats-filter-1.14 created
envoyfilter.networking.istio.io/stats-filter-1.15 created
envoyfilter.networking.istio.io/stats-filter-1.16 created
envoyfilter.networking.istio.io/tcp-stats-filter-1.13 created
envoyfilter.networking.istio.io/tcp-stats-filter-1.14 created
envoyfilter.networking.istio.io/tcp-stats-filter-1.15 created
envoyfilter.networking.istio.io/tcp-stats-filter-1.16 created
envoyfilter.networking.istio.io/x-forwarded-host created
gateway.networking.istio.io/cluster-local-gateway created
gateway.networking.istio.io/istio-ingressgateway created
gateway.networking.istio.io/knative-local-gateway created
gateway.networking.istio.io/kubeflow-gateway created
virtualservice.networking.istio.io/dex created
virtualservice.networking.istio.io/centraldashboard created
virtualservice.networking.istio.io/jupyter-web-app-jupyter-web-app created
virtualservice.networking.istio.io/katib-ui created
virtualservice.networking.istio.io/metadata-grpc created
virtualservice.networking.istio.io/ml-pipeline-ui created
virtualservice.networking.istio.io/profiles-kfam created
virtualservice.networking.istio.io/tensorboards-web-app-tensorboards-web-app created
virtualservice.networking.istio.io/volumes-web-app-volumes-web-app created
virtualservice.networking.istio.io/kserve-models-web-app created
authorizationpolicy.security.istio.io/cluster-local-gateway created
authorizationpolicy.security.istio.io/global-deny-all created
authorizationpolicy.security.istio.io/istio-ingressgateway created
authorizationpolicy.security.istio.io/activator-service created
authorizationpolicy.security.istio.io/autoscaler created
authorizationpolicy.security.istio.io/controller created
authorizationpolicy.security.istio.io/istio-webhook created
authorizationpolicy.security.istio.io/webhook created
authorizationpolicy.security.istio.io/central-dashboard created
authorizationpolicy.security.istio.io/jupyter-web-app created
authorizationpolicy.security.istio.io/katib-ui created
authorizationpolicy.security.istio.io/kserve-models-web-app created
authorizationpolicy.security.istio.io/metadata-grpc-service created
authorizationpolicy.security.istio.io/minio-service created
authorizationpolicy.security.istio.io/ml-pipeline created
authorizationpolicy.security.istio.io/ml-pipeline-ui created
authorizationpolicy.security.istio.io/ml-pipeline-visualizationserver created
authorizationpolicy.security.istio.io/mysql created
authorizationpolicy.security.istio.io/profiles-kfam created
authorizationpolicy.security.istio.io/service-cache-server created
authorizationpolicy.security.istio.io/tensorboards-web-app created
authorizationpolicy.security.istio.io/volumes-web-app created
peerauthentication.security.istio.io/domainmapping-webhook created
peerauthentication.security.istio.io/net-istio-webhook created
peerauthentication.security.istio.io/webhook created
clusterservingruntime.serving.kserve.io/kserve-lgbserver created
clusterservingruntime.serving.kserve.io/kserve-mlserver created
clusterservingruntime.serving.kserve.io/kserve-paddleserver created
clusterservingruntime.serving.kserve.io/kserve-pmmlserver created
clusterservingruntime.serving.kserve.io/kserve-sklearnserver created
clusterservingruntime.serving.kserve.io/kserve-tensorflow-serving created
clusterservingruntime.serving.kserve.io/kserve-torchserve created
clusterservingruntime.serving.kserve.io/kserve-tritonserver created
clusterservingruntime.serving.kserve.io/kserve-xgbserver created
validatingwebhookconfiguration.admissionregistration.k8s.io/cert-manager-webhook configured
validatingwebhookconfiguration.admissionregistration.k8s.io/config.webhook.eventing.knative.dev unchanged
validatingwebhookconfiguration.admissionregistration.k8s.io/config.webhook.istio.networking.internal.knative.dev unchanged
validatingwebhookconfiguration.admissionregistration.k8s.io/config.webhook.serving.knative.dev unchanged
validatingwebhookconfiguration.admissionregistration.k8s.io/inferencegraph.serving.kserve.io configured
validatingwebhookconfiguration.admissionregistration.k8s.io/inferenceservice.serving.kserve.io configured
validatingwebhookconfiguration.admissionregistration.k8s.io/istio-validator-istio-system configured
validatingwebhookconfiguration.admissionregistration.k8s.io/katib.kubeflow.org configured
validatingwebhookconfiguration.admissionregistration.k8s.io/trainedmodel.serving.kserve.io configured
validatingwebhookconfiguration.admissionregistration.k8s.io/validation.webhook.domainmapping.serving.knative.dev unchanged
validatingwebhookconfiguration.admissionregistration.k8s.io/validation.webhook.eventing.knative.dev unchanged
validatingwebhookconfiguration.admissionregistration.k8s.io/validation.webhook.serving.knative.dev unchanged
Error from server (InternalError): error when creating "STDIN": Internal error occurred: failed calling webhook "webhook.cert-manager.io": failed to call webhook: Post "https://cert-manager-webhook.cert-manager.svc:443/mutate?timeout=10s": x509: certificate signed by unknown authority
Error from server (InternalError): error when creating "STDIN": Internal error occurred: failed calling webhook "webhook.cert-manager.io": failed to call webhook: Post "https://cert-manager-webhook.cert-manager.svc:443/mutate?timeout=10s": x509: certificate signed by unknown authority
Error from server (InternalError): error when creating "STDIN": Internal error occurred: failed calling webhook "webhook.cert-manager.io": failed to call webhook: Post "https://cert-manager-webhook.cert-manager.svc:443/mutate?timeout=10s": x509: certificate signed by unknown authority
Error from server (InternalError): error when creating "STDIN": Internal error occurred: failed calling webhook "webhook.cert-manager.io": failed to call webhook: Post "https://cert-manager-webhook.cert-manager.svc:443/mutate?timeout=10s": x509: certificate signed by unknown authority
Error from server (InternalError): error when creating "STDIN": Internal error occurred: failed calling webhook "webhook.cert-manager.io": failed to call webhook: Post "https://cert-manager-webhook.cert-manager.svc:443/mutate?timeout=10s": x509: certificate signed by unknown authority
Error from server (InternalError): error when creating "STDIN": Internal error occurred: failed calling webhook "webhook.cert-manager.io": failed to call webhook: Post "https://cert-manager-webhook.cert-manager.svc:443/mutate?timeout=10s": x509: certificate signed by unknown authority
Error from server (InternalError): error when creating "STDIN": Internal error occurred: failed calling webhook "webhook.cert-manager.io": failed to call webhook: Post "https://cert-manager-webhook.cert-manager.svc:443/mutate?timeout=10s": x509: certificate signed by unknown authority
Error from server (InternalError): error when creating "STDIN": Internal error occurred: failed calling webhook "webhook.cert-manager.io": failed to call webhook: Post "https://cert-manager-webhook.cert-manager.svc:443/mutate?timeout=10s": x509: certificate signed by unknown authority
Error from server (InternalError): error when creating "STDIN": Internal error occurred: failed calling webhook "webhook.cert-manager.io": failed to call webhook: Post "https://cert-manager-webhook.cert-manager.svc:443/mutate?timeout=10s": x509: certificate signed by unknown authority

#1.8.0
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesJson6902' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'vars' is deprecated. Please use 'replacements' instead. [EXPERIMENTAL] Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesJson6902' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
# Warning: 'patchesStrategicMerge' is deprecated. Please use 'patches' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
2023/12/21 10:00:56 well-defined vars that were never replaced: kfp-app-name,kfp-app-version
namespace/auth created
namespace/cert-manager unchanged
namespace/istio-system created
namespace/knative-eventing created
namespace/knative-serving created
namespace/kubeflow created
customresourcedefinition.apiextensions.k8s.io/apiserversources.sources.knative.dev created
customresourcedefinition.apiextensions.k8s.io/authcodes.dex.coreos.com created
customresourcedefinition.apiextensions.k8s.io/authorizationpolicies.security.istio.io created
customresourcedefinition.apiextensions.k8s.io/brokers.eventing.knative.dev created
customresourcedefinition.apiextensions.k8s.io/certificaterequests.cert-manager.io unchanged
customresourcedefinition.apiextensions.k8s.io/certificates.cert-manager.io unchanged
customresourcedefinition.apiextensions.k8s.io/certificates.networking.internal.knative.dev created
customresourcedefinition.apiextensions.k8s.io/challenges.acme.cert-manager.io unchanged
customresourcedefinition.apiextensions.k8s.io/channels.messaging.knative.dev created
customresourcedefinition.apiextensions.k8s.io/clusterdomainclaims.networking.internal.knative.dev created
customresourcedefinition.apiextensions.k8s.io/clusterissuers.cert-manager.io unchanged
customresourcedefinition.apiextensions.k8s.io/clusterservingruntimes.serving.kserve.io created
customresourcedefinition.apiextensions.k8s.io/clusterstoragecontainers.serving.kserve.io created
customresourcedefinition.apiextensions.k8s.io/clusterworkflowtemplates.argoproj.io created
customresourcedefinition.apiextensions.k8s.io/compositecontrollers.metacontroller.k8s.io created
customresourcedefinition.apiextensions.k8s.io/configurations.serving.knative.dev created
customresourcedefinition.apiextensions.k8s.io/containersources.sources.knative.dev created
customresourcedefinition.apiextensions.k8s.io/controllerrevisions.metacontroller.k8s.io created
customresourcedefinition.apiextensions.k8s.io/cronworkflows.argoproj.io created
customresourcedefinition.apiextensions.k8s.io/decoratorcontrollers.metacontroller.k8s.io created
customresourcedefinition.apiextensions.k8s.io/destinationrules.networking.istio.io created
customresourcedefinition.apiextensions.k8s.io/domainmappings.serving.knative.dev created
customresourcedefinition.apiextensions.k8s.io/envoyfilters.networking.istio.io created
customresourcedefinition.apiextensions.k8s.io/eventtypes.eventing.knative.dev created
customresourcedefinition.apiextensions.k8s.io/experiments.kubeflow.org created
customresourcedefinition.apiextensions.k8s.io/gateways.networking.istio.io created
customresourcedefinition.apiextensions.k8s.io/images.caching.internal.knative.dev created
customresourcedefinition.apiextensions.k8s.io/inferencegraphs.serving.kserve.io created
customresourcedefinition.apiextensions.k8s.io/inferenceservices.serving.kserve.io created
customresourcedefinition.apiextensions.k8s.io/ingresses.networking.internal.knative.dev created
customresourcedefinition.apiextensions.k8s.io/issuers.cert-manager.io unchanged
customresourcedefinition.apiextensions.k8s.io/istiooperators.install.istio.io created
customresourcedefinition.apiextensions.k8s.io/metrics.autoscaling.internal.knative.dev created
customresourcedefinition.apiextensions.k8s.io/mpijobs.kubeflow.org created
customresourcedefinition.apiextensions.k8s.io/mxjobs.kubeflow.org created
customresourcedefinition.apiextensions.k8s.io/notebooks.kubeflow.org created
customresourcedefinition.apiextensions.k8s.io/orders.acme.cert-manager.io unchanged
customresourcedefinition.apiextensions.k8s.io/paddlejobs.kubeflow.org created
customresourcedefinition.apiextensions.k8s.io/parallels.flows.knative.dev created
customresourcedefinition.apiextensions.k8s.io/peerauthentications.security.istio.io created
customresourcedefinition.apiextensions.k8s.io/pingsources.sources.knative.dev created
customresourcedefinition.apiextensions.k8s.io/podautoscalers.autoscaling.internal.knative.dev created
customresourcedefinition.apiextensions.k8s.io/poddefaults.kubeflow.org created
customresourcedefinition.apiextensions.k8s.io/profiles.kubeflow.org created
customresourcedefinition.apiextensions.k8s.io/proxyconfigs.networking.istio.io created
customresourcedefinition.apiextensions.k8s.io/pvcviewers.kubeflow.org created
customresourcedefinition.apiextensions.k8s.io/pytorchjobs.kubeflow.org created
customresourcedefinition.apiextensions.k8s.io/requestauthentications.security.istio.io created
customresourcedefinition.apiextensions.k8s.io/revisions.serving.knative.dev created
customresourcedefinition.apiextensions.k8s.io/routes.serving.knative.dev created
customresourcedefinition.apiextensions.k8s.io/scheduledworkflows.kubeflow.org created
customresourcedefinition.apiextensions.k8s.io/sequences.flows.knative.dev created
customresourcedefinition.apiextensions.k8s.io/serverlessservices.networking.internal.knative.dev created
customresourcedefinition.apiextensions.k8s.io/serviceentries.networking.istio.io created
customresourcedefinition.apiextensions.k8s.io/services.serving.knative.dev created
customresourcedefinition.apiextensions.k8s.io/servingruntimes.serving.kserve.io created
customresourcedefinition.apiextensions.k8s.io/sidecars.networking.istio.io created
customresourcedefinition.apiextensions.k8s.io/sinkbindings.sources.knative.dev created
customresourcedefinition.apiextensions.k8s.io/subscriptions.messaging.knative.dev created
customresourcedefinition.apiextensions.k8s.io/suggestions.kubeflow.org created
customresourcedefinition.apiextensions.k8s.io/telemetries.telemetry.istio.io created
customresourcedefinition.apiextensions.k8s.io/tensorboards.tensorboard.kubeflow.org created
customresourcedefinition.apiextensions.k8s.io/tfjobs.kubeflow.org created
customresourcedefinition.apiextensions.k8s.io/trainedmodels.serving.kserve.io created
customresourcedefinition.apiextensions.k8s.io/trials.kubeflow.org created
customresourcedefinition.apiextensions.k8s.io/triggers.eventing.knative.dev created
customresourcedefinition.apiextensions.k8s.io/viewers.kubeflow.org created
customresourcedefinition.apiextensions.k8s.io/virtualservices.networking.istio.io created
customresourcedefinition.apiextensions.k8s.io/wasmplugins.extensions.istio.io created
customresourcedefinition.apiextensions.k8s.io/workfloweventbindings.argoproj.io created
customresourcedefinition.apiextensions.k8s.io/workflows.argoproj.io created
customresourcedefinition.apiextensions.k8s.io/workflowtaskresults.argoproj.io created
customresourcedefinition.apiextensions.k8s.io/workflowtasksets.argoproj.io created
customresourcedefinition.apiextensions.k8s.io/workflowtemplates.argoproj.io created
customresourcedefinition.apiextensions.k8s.io/workloadentries.networking.istio.io created
customresourcedefinition.apiextensions.k8s.io/workloadgroups.networking.istio.io created
customresourcedefinition.apiextensions.k8s.io/xgboostjobs.kubeflow.org created
mutatingwebhookconfiguration.admissionregistration.k8s.io/admission-webhook-mutating-webhook-configuration created
mutatingwebhookconfiguration.admissionregistration.k8s.io/cache-webhook-kubeflow created
mutatingwebhookconfiguration.admissionregistration.k8s.io/cert-manager-webhook configured
mutatingwebhookconfiguration.admissionregistration.k8s.io/inferenceservice.serving.kserve.io created
mutatingwebhookconfiguration.admissionregistration.k8s.io/istio-sidecar-injector created
mutatingwebhookconfiguration.admissionregistration.k8s.io/katib.kubeflow.org created
mutatingwebhookconfiguration.admissionregistration.k8s.io/pvcviewer-mutating-webhook-configuration created
mutatingwebhookconfiguration.admissionregistration.k8s.io/sinkbindings.webhook.sources.knative.dev created
mutatingwebhookconfiguration.admissionregistration.k8s.io/webhook.domainmapping.serving.knative.dev created
mutatingwebhookconfiguration.admissionregistration.k8s.io/webhook.eventing.knative.dev created
mutatingwebhookconfiguration.admissionregistration.k8s.io/webhook.istio.networking.internal.knative.dev created
mutatingwebhookconfiguration.admissionregistration.k8s.io/webhook.serving.knative.dev created
serviceaccount/dex created
serviceaccount/cert-manager unchanged
serviceaccount/cert-manager-cainjector unchanged
serviceaccount/cert-manager-webhook unchanged
serviceaccount/authservice created
serviceaccount/cluster-local-gateway-service-account created
serviceaccount/istio-ingressgateway-service-account created
serviceaccount/istio-reader-service-account created
serviceaccount/istiod created
serviceaccount/istiod-service-account created
serviceaccount/eventing-controller created
serviceaccount/eventing-webhook created
serviceaccount/pingsource-mt-adapter created
serviceaccount/controller created
serviceaccount/admission-webhook-service-account created
serviceaccount/argo created
serviceaccount/centraldashboard created
serviceaccount/jupyter-web-app-service-account created
serviceaccount/katib-controller created
serviceaccount/katib-ui created
serviceaccount/kserve-controller-manager created
serviceaccount/kserve-models-web-app created
serviceaccount/kubeflow-pipelines-cache created
serviceaccount/kubeflow-pipelines-container-builder created
serviceaccount/kubeflow-pipelines-metadata-writer created
serviceaccount/kubeflow-pipelines-viewer created
serviceaccount/meta-controller-service created
serviceaccount/metadata-grpc-server created
serviceaccount/ml-pipeline created
serviceaccount/ml-pipeline-persistenceagent created
serviceaccount/ml-pipeline-scheduledworkflow created
serviceaccount/ml-pipeline-ui created
serviceaccount/ml-pipeline-viewer-crd-service-account created
serviceaccount/ml-pipeline-visualizationserver created
serviceaccount/mysql created
serviceaccount/notebook-controller-service-account created
serviceaccount/pipeline-runner created
serviceaccount/profiles-controller-service-account created
serviceaccount/pvcviewer-controller-manager created
serviceaccount/tensorboard-controller-controller-manager created
serviceaccount/tensorboards-web-app-service-account created
serviceaccount/training-operator created
serviceaccount/volumes-web-app-service-account created
role.rbac.authorization.k8s.io/cert-manager-webhook:dynamic-serving unchanged
role.rbac.authorization.k8s.io/cluster-local-gateway-sds created
role.rbac.authorization.k8s.io/istio-ingressgateway-sds created
role.rbac.authorization.k8s.io/istiod created
role.rbac.authorization.k8s.io/istiod-istio-system created
role.rbac.authorization.k8s.io/knative-eventing-webhook created
role.rbac.authorization.k8s.io/cert-manager-cainjector:leaderelection unchanged
role.rbac.authorization.k8s.io/cert-manager:leaderelection unchanged
role.rbac.authorization.k8s.io/argo-role created
role.rbac.authorization.k8s.io/centraldashboard created
role.rbac.authorization.k8s.io/jupyter-web-app-jupyter-notebook-role created
role.rbac.authorization.k8s.io/kserve-leader-election-role created
role.rbac.authorization.k8s.io/kubeflow-pipelines-cache-role created
role.rbac.authorization.k8s.io/kubeflow-pipelines-metadata-writer-role created
role.rbac.authorization.k8s.io/ml-pipeline created
role.rbac.authorization.k8s.io/ml-pipeline-persistenceagent-role created
role.rbac.authorization.k8s.io/ml-pipeline-scheduledworkflow-role created
role.rbac.authorization.k8s.io/ml-pipeline-ui created
role.rbac.authorization.k8s.io/ml-pipeline-viewer-controller-role created
role.rbac.authorization.k8s.io/notebook-controller-leader-election-role created
role.rbac.authorization.k8s.io/pipeline-runner created
role.rbac.authorization.k8s.io/profiles-leader-election-role created
role.rbac.authorization.k8s.io/pvcviewer-leader-election-role created
role.rbac.authorization.k8s.io/tensorboard-controller-leader-election-role created
clusterrole.rbac.authorization.k8s.io/addressable-resolver created
clusterrole.rbac.authorization.k8s.io/admission-webhook-cluster-role created
clusterrole.rbac.authorization.k8s.io/admission-webhook-kubeflow-poddefaults-admin created
clusterrole.rbac.authorization.k8s.io/admission-webhook-kubeflow-poddefaults-edit created
clusterrole.rbac.authorization.k8s.io/admission-webhook-kubeflow-poddefaults-view created
clusterrole.rbac.authorization.k8s.io/aggregate-to-kubeflow-pipelines-edit created
clusterrole.rbac.authorization.k8s.io/aggregate-to-kubeflow-pipelines-view created
clusterrole.rbac.authorization.k8s.io/argo-aggregate-to-admin created
clusterrole.rbac.authorization.k8s.io/argo-aggregate-to-edit created
clusterrole.rbac.authorization.k8s.io/argo-aggregate-to-view created
clusterrole.rbac.authorization.k8s.io/argo-cluster-role created
clusterrole.rbac.authorization.k8s.io/authn-delegator created
clusterrole.rbac.authorization.k8s.io/broker-addressable-resolver created
clusterrole.rbac.authorization.k8s.io/builtin-podspecable-binding created
clusterrole.rbac.authorization.k8s.io/centraldashboard created
clusterrole.rbac.authorization.k8s.io/cert-manager-cainjector unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-approve:cert-manager-io unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-certificates unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-certificatesigningrequests unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-challenges unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-clusterissuers unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-ingress-shim unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-issuers unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-orders unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-edit unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-view unchanged
clusterrole.rbac.authorization.k8s.io/cert-manager-webhook:subjectaccessreviews unchanged
clusterrole.rbac.authorization.k8s.io/channel-addressable-resolver created
clusterrole.rbac.authorization.k8s.io/channelable-manipulator created
clusterrole.rbac.authorization.k8s.io/dex created
clusterrole.rbac.authorization.k8s.io/eventing-broker-filter created
clusterrole.rbac.authorization.k8s.io/eventing-broker-ingress created
clusterrole.rbac.authorization.k8s.io/eventing-config-reader created
clusterrole.rbac.authorization.k8s.io/eventing-sources-source-observer created
clusterrole.rbac.authorization.k8s.io/flows-addressable-resolver created
clusterrole.rbac.authorization.k8s.io/istio-reader-clusterrole-istio-system created
clusterrole.rbac.authorization.k8s.io/istio-reader-istio-system created
clusterrole.rbac.authorization.k8s.io/istiod-clusterrole-istio-system created
clusterrole.rbac.authorization.k8s.io/istiod-gateway-controller-istio-system created
clusterrole.rbac.authorization.k8s.io/istiod-istio-system created
clusterrole.rbac.authorization.k8s.io/jupyter-web-app-cluster-role created
clusterrole.rbac.authorization.k8s.io/jupyter-web-app-kubeflow-notebook-ui-admin created
clusterrole.rbac.authorization.k8s.io/jupyter-web-app-kubeflow-notebook-ui-edit created
clusterrole.rbac.authorization.k8s.io/jupyter-web-app-kubeflow-notebook-ui-view created
clusterrole.rbac.authorization.k8s.io/katib-controller created
clusterrole.rbac.authorization.k8s.io/katib-ui created
clusterrole.rbac.authorization.k8s.io/knative-bindings-namespaced-admin created
clusterrole.rbac.authorization.k8s.io/knative-eventing-controller created
clusterrole.rbac.authorization.k8s.io/knative-eventing-namespaced-admin created
clusterrole.rbac.authorization.k8s.io/knative-eventing-namespaced-edit created
clusterrole.rbac.authorization.k8s.io/knative-eventing-namespaced-view created
clusterrole.rbac.authorization.k8s.io/knative-eventing-pingsource-mt-adapter created
clusterrole.rbac.authorization.k8s.io/knative-eventing-sources-controller created
clusterrole.rbac.authorization.k8s.io/knative-eventing-webhook created
clusterrole.rbac.authorization.k8s.io/knative-flows-namespaced-admin created
clusterrole.rbac.authorization.k8s.io/knative-messaging-namespaced-admin created
clusterrole.rbac.authorization.k8s.io/knative-serving-addressable-resolver created
clusterrole.rbac.authorization.k8s.io/knative-serving-admin created
clusterrole.rbac.authorization.k8s.io/knative-serving-aggregated-addressable-resolver created
clusterrole.rbac.authorization.k8s.io/knative-serving-core created
clusterrole.rbac.authorization.k8s.io/knative-serving-istio created
clusterrole.rbac.authorization.k8s.io/knative-serving-namespaced-admin created
clusterrole.rbac.authorization.k8s.io/knative-serving-namespaced-edit created
clusterrole.rbac.authorization.k8s.io/knative-serving-namespaced-view created
clusterrole.rbac.authorization.k8s.io/knative-serving-podspecable-binding created
clusterrole.rbac.authorization.k8s.io/knative-sources-namespaced-admin created
clusterrole.rbac.authorization.k8s.io/kserve-manager-role created
clusterrole.rbac.authorization.k8s.io/kserve-models-web-app-cluster-role created
clusterrole.rbac.authorization.k8s.io/kserve-proxy-role created
clusterrole.rbac.authorization.k8s.io/kubeflow-admin created
clusterrole.rbac.authorization.k8s.io/kubeflow-edit created
clusterrole.rbac.authorization.k8s.io/kubeflow-istio-admin created
clusterrole.rbac.authorization.k8s.io/kubeflow-istio-edit created
clusterrole.rbac.authorization.k8s.io/kubeflow-istio-view created
clusterrole.rbac.authorization.k8s.io/kubeflow-katib-admin created
clusterrole.rbac.authorization.k8s.io/kubeflow-katib-edit created
clusterrole.rbac.authorization.k8s.io/kubeflow-katib-view created
clusterrole.rbac.authorization.k8s.io/kubeflow-kserve-admin created
clusterrole.rbac.authorization.k8s.io/kubeflow-kserve-edit created
clusterrole.rbac.authorization.k8s.io/kubeflow-kserve-view created
clusterrole.rbac.authorization.k8s.io/kubeflow-kubernetes-admin created
clusterrole.rbac.authorization.k8s.io/kubeflow-kubernetes-edit created
clusterrole.rbac.authorization.k8s.io/kubeflow-kubernetes-view created
clusterrole.rbac.authorization.k8s.io/kubeflow-pipelines-cache-role created
clusterrole.rbac.authorization.k8s.io/kubeflow-pipelines-edit created
clusterrole.rbac.authorization.k8s.io/kubeflow-pipelines-metadata-writer-role created
clusterrole.rbac.authorization.k8s.io/kubeflow-pipelines-view created
clusterrole.rbac.authorization.k8s.io/kubeflow-training-admin created
clusterrole.rbac.authorization.k8s.io/kubeflow-training-edit created
clusterrole.rbac.authorization.k8s.io/kubeflow-training-view created
clusterrole.rbac.authorization.k8s.io/kubeflow-view created
clusterrole.rbac.authorization.k8s.io/meta-channelable-manipulator created
clusterrole.rbac.authorization.k8s.io/ml-pipeline created
clusterrole.rbac.authorization.k8s.io/ml-pipeline-persistenceagent-role created
clusterrole.rbac.authorization.k8s.io/ml-pipeline-scheduledworkflow-role created
clusterrole.rbac.authorization.k8s.io/ml-pipeline-ui created
clusterrole.rbac.authorization.k8s.io/ml-pipeline-viewer-controller-role created
clusterrole.rbac.authorization.k8s.io/notebook-controller-kubeflow-notebooks-admin created
clusterrole.rbac.authorization.k8s.io/notebook-controller-kubeflow-notebooks-edit created
clusterrole.rbac.authorization.k8s.io/notebook-controller-kubeflow-notebooks-view created
clusterrole.rbac.authorization.k8s.io/notebook-controller-role created
clusterrole.rbac.authorization.k8s.io/podspecable-binding created
clusterrole.rbac.authorization.k8s.io/pvcviewer-metrics-reader created
clusterrole.rbac.authorization.k8s.io/pvcviewer-proxy-role created
clusterrole.rbac.authorization.k8s.io/pvcviewer-role created
clusterrole.rbac.authorization.k8s.io/service-addressable-resolver created
clusterrole.rbac.authorization.k8s.io/serving-addressable-resolver created
clusterrole.rbac.authorization.k8s.io/source-observer created
clusterrole.rbac.authorization.k8s.io/tensorboard-controller-manager-role created
clusterrole.rbac.authorization.k8s.io/tensorboard-controller-metrics-reader created
clusterrole.rbac.authorization.k8s.io/tensorboard-controller-proxy-role created
clusterrole.rbac.authorization.k8s.io/tensorboards-web-app-cluster-role created
clusterrole.rbac.authorization.k8s.io/tensorboards-web-app-kubeflow-tensorboard-ui-admin created
clusterrole.rbac.authorization.k8s.io/tensorboards-web-app-kubeflow-tensorboard-ui-edit created
clusterrole.rbac.authorization.k8s.io/tensorboards-web-app-kubeflow-tensorboard-ui-view created
clusterrole.rbac.authorization.k8s.io/training-operator created
clusterrole.rbac.authorization.k8s.io/volumes-web-app-cluster-role created
clusterrole.rbac.authorization.k8s.io/volumes-web-app-kubeflow-volume-ui-admin created
clusterrole.rbac.authorization.k8s.io/volumes-web-app-kubeflow-volume-ui-edit created
clusterrole.rbac.authorization.k8s.io/volumes-web-app-kubeflow-volume-ui-view created
rolebinding.rbac.authorization.k8s.io/cert-manager-webhook:dynamic-serving configured
rolebinding.rbac.authorization.k8s.io/cluster-local-gateway-sds created
rolebinding.rbac.authorization.k8s.io/istio-ingressgateway-sds created
rolebinding.rbac.authorization.k8s.io/istiod created
rolebinding.rbac.authorization.k8s.io/istiod-istio-system created
rolebinding.rbac.authorization.k8s.io/eventing-webhook created
rolebinding.rbac.authorization.k8s.io/cert-manager-cainjector:leaderelection unchanged
rolebinding.rbac.authorization.k8s.io/cert-manager:leaderelection configured
rolebinding.rbac.authorization.k8s.io/argo-binding created
rolebinding.rbac.authorization.k8s.io/centraldashboard created
rolebinding.rbac.authorization.k8s.io/jupyter-web-app-jupyter-notebook-role-binding created
rolebinding.rbac.authorization.k8s.io/kserve-leader-election-rolebinding created
rolebinding.rbac.authorization.k8s.io/kubeflow-pipelines-cache-binding created
rolebinding.rbac.authorization.k8s.io/kubeflow-pipelines-metadata-writer-binding created
rolebinding.rbac.authorization.k8s.io/ml-pipeline created
rolebinding.rbac.authorization.k8s.io/ml-pipeline-persistenceagent-binding created
rolebinding.rbac.authorization.k8s.io/ml-pipeline-scheduledworkflow-binding created
rolebinding.rbac.authorization.k8s.io/ml-pipeline-ui created
rolebinding.rbac.authorization.k8s.io/ml-pipeline-viewer-crd-binding created
rolebinding.rbac.authorization.k8s.io/notebook-controller-leader-election-rolebinding created
rolebinding.rbac.authorization.k8s.io/pipeline-runner-binding created
rolebinding.rbac.authorization.k8s.io/profiles-leader-election-rolebinding created
rolebinding.rbac.authorization.k8s.io/pvcviewer-leader-election-rolebinding created
rolebinding.rbac.authorization.k8s.io/tensorboard-controller-leader-election-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/admission-webhook-cluster-role-binding created
clusterrolebinding.rbac.authorization.k8s.io/argo-binding created
clusterrolebinding.rbac.authorization.k8s.io/authn-delegators created
clusterrolebinding.rbac.authorization.k8s.io/centraldashboard created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-cainjector unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-approve:cert-manager-io unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-certificates unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-certificatesigningrequests unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-challenges unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-clusterissuers unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-ingress-shim unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-issuers unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-orders unchanged
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-webhook:subjectaccessreviews configured
clusterrolebinding.rbac.authorization.k8s.io/dex created
clusterrolebinding.rbac.authorization.k8s.io/eventing-controller created
clusterrolebinding.rbac.authorization.k8s.io/eventing-controller-manipulator created
clusterrolebinding.rbac.authorization.k8s.io/eventing-controller-resolver created
clusterrolebinding.rbac.authorization.k8s.io/eventing-controller-source-observer created
clusterrolebinding.rbac.authorization.k8s.io/eventing-controller-sources-controller created
clusterrolebinding.rbac.authorization.k8s.io/eventing-webhook created
clusterrolebinding.rbac.authorization.k8s.io/eventing-webhook-podspecable-binding created
clusterrolebinding.rbac.authorization.k8s.io/eventing-webhook-resolver created
clusterrolebinding.rbac.authorization.k8s.io/istio-reader-clusterrole-istio-system created
clusterrolebinding.rbac.authorization.k8s.io/istio-reader-istio-system created
clusterrolebinding.rbac.authorization.k8s.io/istiod-clusterrole-istio-system created
clusterrolebinding.rbac.authorization.k8s.io/istiod-gateway-controller-istio-system created
clusterrolebinding.rbac.authorization.k8s.io/istiod-istio-system created
clusterrolebinding.rbac.authorization.k8s.io/jupyter-web-app-cluster-role-binding created
clusterrolebinding.rbac.authorization.k8s.io/katib-controller created
clusterrolebinding.rbac.authorization.k8s.io/katib-ui created
clusterrolebinding.rbac.authorization.k8s.io/knative-eventing-pingsource-mt-adapter created
clusterrolebinding.rbac.authorization.k8s.io/knative-serving-controller-addressable-resolver created
clusterrolebinding.rbac.authorization.k8s.io/knative-serving-controller-admin created
clusterrolebinding.rbac.authorization.k8s.io/kserve-manager-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/kserve-models-web-app-binding created
clusterrolebinding.rbac.authorization.k8s.io/kserve-proxy-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/kubeflow-pipelines-cache-binding created
clusterrolebinding.rbac.authorization.k8s.io/kubeflow-pipelines-metadata-writer-binding created
clusterrolebinding.rbac.authorization.k8s.io/meta-controller-cluster-role-binding created
clusterrolebinding.rbac.authorization.k8s.io/ml-pipeline created
clusterrolebinding.rbac.authorization.k8s.io/ml-pipeline-persistenceagent-binding created
clusterrolebinding.rbac.authorization.k8s.io/ml-pipeline-scheduledworkflow-binding created
clusterrolebinding.rbac.authorization.k8s.io/ml-pipeline-ui created
clusterrolebinding.rbac.authorization.k8s.io/ml-pipeline-viewer-crd-binding created
clusterrolebinding.rbac.authorization.k8s.io/notebook-controller-role-binding created
clusterrolebinding.rbac.authorization.k8s.io/profiles-cluster-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/pvcviewer-manager-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/pvcviewer-proxy-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/tensorboard-controller-manager-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/tensorboard-controller-proxy-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/tensorboards-web-app-cluster-role-binding created
clusterrolebinding.rbac.authorization.k8s.io/training-operator created
clusterrolebinding.rbac.authorization.k8s.io/volumes-web-app-cluster-role-binding created
configmap/dex created
configmap/cert-manager-webhook configured
configmap/istio created
configmap/istio-sidecar-injector created
configmap/oidc-authservice-parameters created
configmap/config-br-default-channel created
configmap/config-br-defaults created
configmap/config-features created
configmap/config-kreference-mapping created
configmap/config-leader-election created
configmap/config-logging created
configmap/config-observability created
configmap/config-ping-defaults created
configmap/config-sugar created
configmap/config-tracing created
configmap/default-ch-webhook created
configmap/config-autoscaler created
configmap/config-defaults created
configmap/config-deployment created
configmap/config-domain created
configmap/config-features created
configmap/config-gc created
configmap/config-istio created
configmap/config-leader-election created
configmap/config-logging created
configmap/config-network created
configmap/config-observability created
configmap/config-tracing created
configmap/centraldashboard-config created
configmap/centraldashboard-parameters created
configmap/inferenceservice-config created
configmap/jupyter-web-app-config-7tkbmh828d created
configmap/jupyter-web-app-logos created
configmap/jupyter-web-app-parameters-42k97gcbmb created
configmap/katib-config created
configmap/kfp-launcher created
configmap/kserve-models-web-app-config created
configmap/kubeflow-pipelines-profile-controller-code-hdk828hd6c created
configmap/kubeflow-pipelines-profile-controller-env-5252m69c4c created
configmap/metadata-grpc-configmap created
configmap/ml-pipeline-ui-configmap created
configmap/namespace-labels-data-4df5t8mdgf created
configmap/notebook-controller-config-dm5b6dd458 created
configmap/pipeline-api-server-config-dc9hkg52h6 created
configmap/pipeline-install-config created
configmap/profiles-config-5h9m86f79f created
configmap/tensorboard-controller-config-b98cb9gk9k created
configmap/tensorboards-web-app-parameters-642bbg7t66 created
configmap/trial-templates created
configmap/volumes-web-app-parameters-57h65c44mg created
configmap/volumes-web-app-viewer-spec-gm954c98h6 created
configmap/workflow-controller-configmap created
configmap/default-install-config-9h2h2b6hbk created
secret/dex-oidc-client created
secret/oidc-authservice-client created
secret/eventing-webhook-certs created
secret/control-serving-certs created
secret/domainmapping-webhook-certs created
secret/knative-serving-certs created
secret/net-istio-webhook-certs created
secret/routing-serving-certs created
secret/serving-certs-ctrl-ca created
secret/webhook-certs created
secret/katib-mysql-secrets created
secret/kserve-webhook-server-secret created
secret/mlpipeline-minio-artifact created
secret/mysql-secret created
service/dex created
service/cert-manager unchanged
service/cert-manager-webhook unchanged
service/authservice created
service/cluster-local-gateway created
service/istio-ingressgateway created
service/istiod created
service/knative-local-gateway created
service/eventing-webhook created
service/activator-service created
service/autoscaler created
service/controller created
service/domainmapping-webhook created
service/net-istio-webhook created
service/webhook created
service/admission-webhook-service created
service/cache-server created
service/centraldashboard created
service/jupyter-web-app-service created
service/katib-controller created
service/katib-db-manager created
service/katib-mysql created
service/katib-ui created
service/kserve-controller-manager-metrics-service created
service/kserve-controller-manager-service created
service/kserve-models-web-app created
service/kserve-webhook-server-service created
service/kubeflow-pipelines-profile-controller created
service/metadata-envoy-service created
service/metadata-grpc-service created
service/minio-service created
service/ml-pipeline created
service/ml-pipeline-ui created
service/ml-pipeline-visualizationserver created
service/mysql created
service/notebook-controller-service created
service/profiles-kfam created
service/pvcviewer-controller-manager-metrics-service created
service/pvcviewer-webhook-service created
service/tensorboard-controller-controller-manager-metrics-service created
service/tensorboards-web-app-service created
service/training-operator created
service/volumes-web-app-service created
service/workflow-controller-metrics created
priorityclass.scheduling.k8s.io/workflow-controller created
persistentvolumeclaim/authservice-pvc created
persistentvolumeclaim/katib-mysql created
persistentvolumeclaim/minio-pvc created
persistentvolumeclaim/mysql-pv-claim created
deployment.apps/dex created
deployment.apps/cert-manager unchanged
deployment.apps/cert-manager-cainjector unchanged
deployment.apps/cert-manager-webhook unchanged
deployment.apps/cluster-local-gateway created
deployment.apps/istio-ingressgateway created
deployment.apps/istiod created
deployment.apps/eventing-controller created
deployment.apps/eventing-webhook created
deployment.apps/pingsource-mt-adapter created
deployment.apps/activator created
deployment.apps/autoscaler created
deployment.apps/controller created
deployment.apps/domain-mapping created
deployment.apps/domainmapping-webhook created
deployment.apps/net-istio-controller created
deployment.apps/net-istio-webhook created
deployment.apps/webhook created
deployment.apps/admission-webhook-deployment created
deployment.apps/cache-server created
deployment.apps/centraldashboard created
deployment.apps/jupyter-web-app-deployment created
deployment.apps/katib-controller created
deployment.apps/katib-db-manager created
deployment.apps/katib-mysql created
deployment.apps/katib-ui created
deployment.apps/kserve-controller-manager created
deployment.apps/kserve-models-web-app created
deployment.apps/kubeflow-pipelines-profile-controller created
deployment.apps/metadata-envoy-deployment created
deployment.apps/metadata-grpc-deployment created
deployment.apps/metadata-writer created
deployment.apps/minio created
deployment.apps/ml-pipeline created
deployment.apps/ml-pipeline-persistenceagent created
deployment.apps/ml-pipeline-scheduledworkflow created
deployment.apps/ml-pipeline-ui created
deployment.apps/ml-pipeline-viewer-crd created
deployment.apps/ml-pipeline-visualizationserver created
deployment.apps/mysql created
deployment.apps/notebook-controller-deployment created
deployment.apps/profiles-deployment created
deployment.apps/pvcviewer-controller-manager created
deployment.apps/tensorboard-controller-deployment created
deployment.apps/tensorboards-web-app-deployment created
deployment.apps/training-operator created
deployment.apps/volumes-web-app-deployment created
deployment.apps/workflow-controller created
statefulset.apps/oidc-authservice created
statefulset.apps/metacontroller created
poddisruptionbudget.policy/eventing-webhook created
poddisruptionbudget.policy/activator-pdb created
poddisruptionbudget.policy/webhook-pdb created
horizontalpodautoscaler.autoscaling/cluster-local-gateway created
horizontalpodautoscaler.autoscaling/istio-ingressgateway created
horizontalpodautoscaler.autoscaling/istiod created
horizontalpodautoscaler.autoscaling/eventing-webhook created
horizontalpodautoscaler.autoscaling/activator created
horizontalpodautoscaler.autoscaling/webhook created
certificate.cert-manager.io/admission-webhook-cert created
certificate.cert-manager.io/katib-webhook-cert created
certificate.cert-manager.io/kfp-cache-cert created
certificate.cert-manager.io/pvcviewer-serving-cert created
certificate.cert-manager.io/serving-cert created
clusterissuer.cert-manager.io/kubeflow-self-signing-issuer unchanged
issuer.cert-manager.io/admission-webhook-selfsigned-issuer created
issuer.cert-manager.io/katib-selfsigned-issuer created
issuer.cert-manager.io/kfp-cache-selfsigned-issuer created
issuer.cert-manager.io/pvcviewer-selfsigned-issuer created
issuer.cert-manager.io/selfsigned-issuer created
validatingwebhookconfiguration.admissionregistration.k8s.io/cert-manager-webhook configured
validatingwebhookconfiguration.admissionregistration.k8s.io/clusterservingruntime.serving.kserve.io created
validatingwebhookconfiguration.admissionregistration.k8s.io/config.webhook.eventing.knative.dev created
validatingwebhookconfiguration.admissionregistration.k8s.io/config.webhook.istio.networking.internal.knative.dev created
validatingwebhookconfiguration.admissionregistration.k8s.io/config.webhook.serving.knative.dev created
validatingwebhookconfiguration.admissionregistration.k8s.io/inferencegraph.serving.kserve.io created
validatingwebhookconfiguration.admissionregistration.k8s.io/inferenceservice.serving.kserve.io created
validatingwebhookconfiguration.admissionregistration.k8s.io/istio-validator-istio-system created
validatingwebhookconfiguration.admissionregistration.k8s.io/katib.kubeflow.org created
validatingwebhookconfiguration.admissionregistration.k8s.io/pvcviewer-validating-webhook-configuration created
validatingwebhookconfiguration.admissionregistration.k8s.io/servingruntime.serving.kserve.io created
validatingwebhookconfiguration.admissionregistration.k8s.io/trainedmodel.serving.kserve.io created
validatingwebhookconfiguration.admissionregistration.k8s.io/validation.webhook.domainmapping.serving.knative.dev created
validatingwebhookconfiguration.admissionregistration.k8s.io/validation.webhook.eventing.knative.dev created
validatingwebhookconfiguration.admissionregistration.k8s.io/validation.webhook.serving.knative.dev created
resource mapping not found for name: "queue-proxy" namespace: "knative-serving" from "STDIN": no matches for kind "Image" in version "caching.internal.knative.dev/v1alpha1"
ensure CRDs are installed first
resource mapping not found for name: "kubeflow-user-example-com" namespace: "" from "STDIN": no matches for kind "Profile" in version "kubeflow.org/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "kubeflow-pipelines-profile-controller" namespace: "kubeflow" from "STDIN": no matches for kind "CompositeController" in version "metacontroller.k8s.io/v1alpha1"
ensure CRDs are installed first
resource mapping not found for name: "knative" namespace: "knative-serving" from "STDIN": no matches for kind "DestinationRule" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "jupyter-web-app" namespace: "kubeflow" from "STDIN": no matches for kind "DestinationRule" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "metadata-grpc-service" namespace: "kubeflow" from "STDIN": no matches for kind "DestinationRule" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "ml-pipeline" namespace: "kubeflow" from "STDIN": no matches for kind "DestinationRule" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "ml-pipeline-minio" namespace: "kubeflow" from "STDIN": no matches for kind "DestinationRule" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "ml-pipeline-mysql" namespace: "kubeflow" from "STDIN": no matches for kind "DestinationRule" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "ml-pipeline-ui" namespace: "kubeflow" from "STDIN": no matches for kind "DestinationRule" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "ml-pipeline-visualizationserver" namespace: "kubeflow" from "STDIN": no matches for kind "DestinationRule" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "tensorboards-web-app" namespace: "kubeflow" from "STDIN": no matches for kind "DestinationRule" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "volumes-web-app" namespace: "kubeflow" from "STDIN": no matches for kind "DestinationRule" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "authn-filter" namespace: "istio-system" from "STDIN": no matches for kind "EnvoyFilter" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "stats-filter-1.13" namespace: "istio-system" from "STDIN": no matches for kind "EnvoyFilter" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "stats-filter-1.14" namespace: "istio-system" from "STDIN": no matches for kind "EnvoyFilter" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "stats-filter-1.15" namespace: "istio-system" from "STDIN": no matches for kind "EnvoyFilter" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "stats-filter-1.16" namespace: "istio-system" from "STDIN": no matches for kind "EnvoyFilter" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "stats-filter-1.17" namespace: "istio-system" from "STDIN": no matches for kind "EnvoyFilter" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "tcp-stats-filter-1.13" namespace: "istio-system" from "STDIN": no matches for kind "EnvoyFilter" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "tcp-stats-filter-1.14" namespace: "istio-system" from "STDIN": no matches for kind "EnvoyFilter" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "tcp-stats-filter-1.15" namespace: "istio-system" from "STDIN": no matches for kind "EnvoyFilter" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "tcp-stats-filter-1.16" namespace: "istio-system" from "STDIN": no matches for kind "EnvoyFilter" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "tcp-stats-filter-1.17" namespace: "istio-system" from "STDIN": no matches for kind "EnvoyFilter" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "x-forwarded-host" namespace: "istio-system" from "STDIN": no matches for kind "EnvoyFilter" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "cluster-local-gateway" namespace: "istio-system" from "STDIN": no matches for kind "Gateway" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "istio-ingressgateway" namespace: "istio-system" from "STDIN": no matches for kind "Gateway" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "kubeflow-gateway" namespace: "kubeflow" from "STDIN": no matches for kind "Gateway" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "dex" namespace: "auth" from "STDIN": no matches for kind "VirtualService" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "centraldashboard" namespace: "kubeflow" from "STDIN": no matches for kind "VirtualService" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "jupyter-web-app-jupyter-web-app" namespace: "kubeflow" from "STDIN": no matches for kind "VirtualService" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "katib-ui" namespace: "kubeflow" from "STDIN": no matches for kind "VirtualService" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "metadata-grpc" namespace: "kubeflow" from "STDIN": no matches for kind "VirtualService" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "ml-pipeline-ui" namespace: "kubeflow" from "STDIN": no matches for kind "VirtualService" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "profiles-kfam" namespace: "kubeflow" from "STDIN": no matches for kind "VirtualService" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "tensorboards-web-app-tensorboards-web-app" namespace: "kubeflow" from "STDIN": no matches for kind "VirtualService" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "volumes-web-app-volumes-web-app" namespace: "kubeflow" from "STDIN": no matches for kind "VirtualService" in version "networking.istio.io/v1alpha3"
ensure CRDs are installed first
resource mapping not found for name: "knative-local-gateway" namespace: "knative-serving" from "STDIN": no matches for kind "Gateway" in version "networking.istio.io/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "kserve-models-web-app" namespace: "kubeflow" from "STDIN": no matches for kind "VirtualService" in version "networking.istio.io/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "cluster-local-gateway" namespace: "istio-system" from "STDIN": no matches for kind "AuthorizationPolicy" in version "security.istio.io/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "global-deny-all" namespace: "istio-system" from "STDIN": no matches for kind "AuthorizationPolicy" in version "security.istio.io/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "istio-ingressgateway" namespace: "istio-system" from "STDIN": no matches for kind "AuthorizationPolicy" in version "security.istio.io/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "activator-service" namespace: "knative-serving" from "STDIN": no matches for kind "AuthorizationPolicy" in version "security.istio.io/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "autoscaler" namespace: "knative-serving" from "STDIN": no matches for kind "AuthorizationPolicy" in version "security.istio.io/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "controller" namespace: "knative-serving" from "STDIN": no matches for kind "AuthorizationPolicy" in version "security.istio.io/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "istio-webhook" namespace: "knative-serving" from "STDIN": no matches for kind "AuthorizationPolicy" in version "security.istio.io/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "webhook" namespace: "knative-serving" from "STDIN": no matches for kind "AuthorizationPolicy" in version "security.istio.io/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "central-dashboard" namespace: "kubeflow" from "STDIN": no matches for kind "AuthorizationPolicy" in version "security.istio.io/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "jupyter-web-app" namespace: "kubeflow" from "STDIN": no matches for kind "AuthorizationPolicy" in version "security.istio.io/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "katib-ui" namespace: "kubeflow" from "STDIN": no matches for kind "AuthorizationPolicy" in version "security.istio.io/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "kserve-models-web-app" namespace: "kubeflow" from "STDIN": no matches for kind "AuthorizationPolicy" in version "security.istio.io/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "metadata-grpc-service" namespace: "kubeflow" from "STDIN": no matches for kind "AuthorizationPolicy" in version "security.istio.io/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "minio-service" namespace: "kubeflow" from "STDIN": no matches for kind "AuthorizationPolicy" in version "security.istio.io/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "ml-pipeline" namespace: "kubeflow" from "STDIN": no matches for kind "AuthorizationPolicy" in version "security.istio.io/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "ml-pipeline-ui" namespace: "kubeflow" from "STDIN": no matches for kind "AuthorizationPolicy" in version "security.istio.io/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "ml-pipeline-visualizationserver" namespace: "kubeflow" from "STDIN": no matches for kind "AuthorizationPolicy" in version "security.istio.io/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "mysql" namespace: "kubeflow" from "STDIN": no matches for kind "AuthorizationPolicy" in version "security.istio.io/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "profiles-kfam" namespace: "kubeflow" from "STDIN": no matches for kind "AuthorizationPolicy" in version "security.istio.io/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "service-cache-server" namespace: "kubeflow" from "STDIN": no matches for kind "AuthorizationPolicy" in version "security.istio.io/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "tensorboards-web-app" namespace: "kubeflow" from "STDIN": no matches for kind "AuthorizationPolicy" in version "security.istio.io/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "volumes-web-app" namespace: "kubeflow" from "STDIN": no matches for kind "AuthorizationPolicy" in version "security.istio.io/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "domainmapping-webhook" namespace: "knative-serving" from "STDIN": no matches for kind "PeerAuthentication" in version "security.istio.io/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "net-istio-webhook" namespace: "knative-serving" from "STDIN": no matches for kind "PeerAuthentication" in version "security.istio.io/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "webhook" namespace: "knative-serving" from "STDIN": no matches for kind "PeerAuthentication" in version "security.istio.io/v1beta1"
ensure CRDs are installed first
resource mapping not found for name: "kserve-lgbserver" namespace: "" from "STDIN": no matches for kind "ClusterServingRuntime" in version "serving.kserve.io/v1alpha1"
ensure CRDs are installed first
resource mapping not found for name: "kserve-mlserver" namespace: "" from "STDIN": no matches for kind "ClusterServingRuntime" in version "serving.kserve.io/v1alpha1"
ensure CRDs are installed first
resource mapping not found for name: "kserve-paddleserver" namespace: "" from "STDIN": no matches for kind "ClusterServingRuntime" in version "serving.kserve.io/v1alpha1"
ensure CRDs are installed first
resource mapping not found for name: "kserve-pmmlserver" namespace: "" from "STDIN": no matches for kind "ClusterServingRuntime" in version "serving.kserve.io/v1alpha1"
ensure CRDs are installed first
resource mapping not found for name: "kserve-sklearnserver" namespace: "" from "STDIN": no matches for kind "ClusterServingRuntime" in version "serving.kserve.io/v1alpha1"
ensure CRDs are installed first
resource mapping not found for name: "kserve-tensorflow-serving" namespace: "" from "STDIN": no matches for kind "ClusterServingRuntime" in version "serving.kserve.io/v1alpha1"
ensure CRDs are installed first
resource mapping not found for name: "kserve-torchserve" namespace: "" from "STDIN": no matches for kind "ClusterServingRuntime" in version "serving.kserve.io/v1alpha1"
ensure CRDs are installed first
resource mapping not found for name: "kserve-tritonserver" namespace: "" from "STDIN": no matches for kind "ClusterServingRuntime" in version "serving.kserve.io/v1alpha1"
ensure CRDs are installed first
resource mapping not found for name: "kserve-xgbserver" namespace: "" from "STDIN": no matches for kind "ClusterServingRuntime" in version "serving.kserve.io/v1alpha1"
ensure CRDs are installed first
Retrying to apply resources



kubectl port-forward --address 0.0.0.0 svc/istio-ingressgateway -n istio-system 8080:80
    user@exmaple.com
    12341234

kubectl port-forward -n kubeflow svc/minio-service 9000:9000

kubectl get secret mlpipeline-minio-artifact -n kubeflow -o jsonpath="{.data.accesskey}" | base64 --decode
accesskey:minio
kubectl get secret mlpipeline-minio-artifact -n kubeflow -o jsonpath="{.data.secretkey}" | base64 --decode
secretkey:minio123
bucket:mlpipeline
