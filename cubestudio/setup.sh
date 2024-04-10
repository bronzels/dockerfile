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
CUBESTUDIO_PRJ_HOME=${PRJ_HOME}/cubestudio

#CUBESTUDIO_VERSION=2023.04.01
#CUBESTUDIO_VERSION=2023.12.01
CUBESTUDIO_VERSION=2024.01.06

export PATH=$PATH:${PRJ_HOME}
cd ${CUBESTUDIO_PRJ_HOME}
wget -c https://github.com/tencentmusic/cube-studio/archive/refs/tags/v${CUBESTUDIO_VERSION}.tar.gz -O cube-studio-${CUBESTUDIO_VERSION}.tar.gz
tar xzvf cube-studio-${CUBESTUDIO_VERSION}.tar.gz 

cd cube-studio-${CUBESTUDIO_VERSION}
cp ~/.kube/config install/kubernetes/config

#kubectl patch storageclass juicefs-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

cd install/kubernetes

cd juicefs
#pv/pvc改写不彻底，部分改到了juicefs，部分还是hostpath，pod在其他node重建将无法访问
cp -r cube-pv-pvc-with-juicefs cube-pv-pvc-with-juicefs.bk
cd cube-pv-pvc-with-juicefs
ls | xargs $SED -i 's/500Gi/50Gi/g'
ls | xargs $SED -i 's/100Gi/10Gi/g'
cd ../..

file=pull_image_kubeflow.sh
cp ${file} ${file}.bk
$SED -i 's/docker pull/crictl pull/g' ${file}
$SED -i 's/docker tag/ctr -n k8s.io i tag/g' ${file}

ansible all -m copy -a"src=pull_image_kubeflow.sh dest=/root/ mode=0755"
ansible all -m shell -a"/root/pull_image_kubeflow.sh"
ansible all -m shell -a"ctr -n k8s.io i pull quay.io/argoproj/workflow-controller:v3.4.3"
imgarr=(busybox minio/minio frameworkcontroller/frameworkcontroller)
filearr=(busybox minio-minio frameworkcontroller-frameworkcontroller)
for i in ${!imgarr[@]}
do
	img=${imgarr[$i]}
	file=${filearr[$i]}
	docker pull $img
	docker save -o ${file}.tar ${img}
done                                                                                                                                                                                                                                            
filearr=(busybox minio-minio frameworkcontroller-frameworkcontroller)
for i in ${!filearr[@]}
do
	file=${filearr[$i]}
    ansible all -m copy -a"src=${file}.tar dest=/root/"
    ansible all -m shell -a"ctr -n k8s.io i import /root/${file}.tar"
    ansible all -m shell -a"rm -f /root/${file}.tar"
done                                                                                                                                                                                                                                            

cp ${CUBESTUDIO_PRJ_HOME}/stop.sh ./
cp ${CUBESTUDIO_PRJ_HOME}/remove_ns_secret.sh ./

file=start.sh
cp ${file} ${file}.bk
$SED -i '1,10d' ${file}

file=create_ns_secret.sh
cp ${file} ${file}.bk
$SED -i "s/for namespace in 'infra' 'kubeflow' 'istio-system' 'pipeline' 'automl' 'jupyter' 'service' 'monitoring' 'logging' 'kube-system'/for namespace in 'infra' 'kubeflow' 'istio-system' 'pipeline' 'automl' 'jupyter' 'service' 'monitoring' 'logging'/g" ${file}

$SED -i 's/kubectl create -f pv-pvc-infra.yaml/#kubectl create -f pv-pvc-infra.yaml/g' start.sh
$SED -i 's/kubectl create -f pv-pvc-jupyter.yaml/#kubectl create -f pv-pvc-jupyter.yaml/g' start.sh
$SED -i 's/kubectl create -f pv-pvc-automl.yaml/#kubectl create -f pv-pvc-automl.yaml/g' start.sh
$SED -i 's/kubectl create -f pv-pvc-pipeline.yaml/#kubectl create -f pv-pvc-pipeline.yaml/g' start.sh
$SED -i 's/kubectl create -f pv-pvc-service.yaml/#kubectl create -f pv-pvc-service.yaml/g' start.sh

# 部署dashboard
$SED -i '/# 部署dashboard/i\cd ${CUBESTUDIO_PRJ_HOME}\/cube-studio-${CUBESTUDIO_VERSION}\/install\/kubernetes\/juicefs\nfor i in $(ls cube-pv-pvc-with-juicefs\/); do kubectl apply -f  cube-pv-pvc-with-juicefs\/$i; done\ncd -' start.sh

# 部署dashboard
$SED -i 's/kubectl apply -f dashboard\/v2.2.0-cluster.yaml/#kubectl apply -f dashboard\/v2.2.0-cluster.yaml/g' start.sh
# 高版本k8s部署2.6.1版本
$SED -i 's/#kubectl apply -f dashboard\/v2.6.1-cluster.yaml/kubectl apply -f dashboard\/v2.6.1-cluster.yaml/g' start.sh

find ./ -type file | xargs grep "/data/k8s"

file=argo/minio-pv-pvc-hostpath.yaml
cp ${file} ${file}.bk
#删除pv，改造成local-path的pvc（1，加上local-path storageclass；2，删除掉和pv匹配的selector。）
#file=argo/install-3.4.3-all.yaml
#删除minio的service/deployment，把my-minio-cred改成自建minio集群的秘钥
#$SED -i 's/kubectl apply -f argo\/minio-pv-pvc-hostpath.yaml/#kubectl apply -f argo\/minio-pv-pvc-hostpath.yaml/g' start.sh

:<<EOF
file=mysql/pv-pvc-hostpath.yaml
cp ${file} ${file}.bk
#删除pv，改造成local-path的pvc（1，加上local-path storageclass；2，删除掉和pv匹配的selector。3，ReadWriteMany改成ReadWriteOnce。）
EOF
find ./ -type file | xargs grep 'mysql-service'
$SED -i 's/kubectl create -f mysql\/pv-pvc-hostpath.yaml/#kubectl create -f mysql\/pv-pvc-hostpath.yaml/g' start.sh
$SED -i 's/kubectl create -f mysql\/service.yaml/#kubectl create -f mysql\/service.yaml/g' start.sh
$SED -i 's/kubectl create -f mysql\/configmap-mysql.yaml/#kubectl create -f mysql\/configmap-mysql.yaml/g' start.sh
$SED -i 's/kubectl create -f mysql\/deploy.yaml/#kubectl create -f mysql\/deploy.yaml/g' start.sh
find ./ -type file | xargs grep 'mysql-service'
file=argo/workflow.yaml
cp ${file} ${file}.bk
#修改密码
  name: argo-mysql-config
  namespace: infra
stringData:
  password: 123456
  username: root
type: Opaque
#修改服务
    mysql:
      host: mysql-svc.mysql
file=cube/overlays/kustomization.yml
cp ${file} ${file}.bk
#修改密码
  - MYSQL_SERVICE=mysql+pymysql://root:123456@mysql-svc.mysql:3306/kubeflow?charset=utf8
cp ${CUBESTUDIO_PRJ_HOME}/mysql-init-deploy.yaml mysql/
$SED -i '/#kubectl create -f mysql\/deploy.yaml/a\kubectl create -f mysql\/mysql-init-deploy.yaml' start.sh
#把mysql/目录下cm的cnf配置项copy到独立mysql的cm中，重启独立mysql

ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-arrikto-kubeflow-oidc-authservice-28c59ef:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-arrikto-kubeflow-oidc-authservice-28c59ef:1.0 gcr.io/arrikto/kubeflow/oidc-authservice:28c59ef"
sudo ssh dtpct ctr -n k8s.io i export gcr.io-arrikto-kubeflow-oidc-authservice-28c59ef.tar gcr.io/arrikto/kubeflow/oidc-authservice:28c59ef

file=prometheus/grafana/pv-pvc-hostpath.yml
cp ${file} ${file}.bk
#删除pv，改造成local-path的pvc（1，加上local-path storageclass；2，删除掉和pv匹配的selector。3，ReadWriteMany改成ReadWriteOnce。）

#prometheus pv/pvc没有在使用
$SED -i 's/kubectl apply -f .\/prometheus\/pv-pvc-hostpath.yaml/#kubectl apply -f .\/prometheus\/pv-pvc-hostpath.yaml/g' start.sh

#redis pv没有在使用
$SED -i 's/kubectl create -f redis\/pv-hostpath.yaml/#kubectl create -f redis\/pv-hostpath.yaml/g' start.sh

# 在k8s 1.21-部署
$SED -i 's/kubectl apply -f istio\/install.yaml/#kubectl apply -f istio\/install.yaml/g' start.sh
# 在k8s 1.21+部署
$SED -i 's/# kubectl delete -f istio\/install.yaml/kubectl delete -f istio\/install.yaml/g' start.sh
$SED -i 's/# kubectl apply -f istio\/install-1.15.0.yaml/kubectl apply -f istio\/install-1.15.0.yaml/g' start.sh

$SED -i '/kubectl apply -f gpu\/nvidia-device-plugin.yml/a\kubectl apply -f gpu\/tke-gpu-manager.yaml' start.sh
file=gpu/tke-gpu-manager.yaml
cp ${file} ${file}.bk
$SED -i 's/        - image: tkestack\/gpu-manager:1.0.3/        - image: tkestack\/gpu-manager:v1.1.5/g' ${file}


cat << \EOF > header.sh
#!/usr/bin/env bash
OLD_IFS="$IFS"
IFS=","
iparr=($1)
IFS="$OLD_IFS"
ipstrarr={}
#for ip in ${iparr[@]}
for i in ${!iparr[@]}
do
    ip=${iparr[$i]}
    ipstrarr[$i]=\"${ip}\"
    node=`kubectl get node -o wide |grep "${ip}" |awk '{print $1}'`
    kubectl label node ${node} train=true cpu=true notebook=true service=true org=public istio=true kubeflow=true kubeflow-dashboard=true mysql=true redis=true monitoring=true logging=true --overwrite
done
allipstr4patch=$(IFS=,; echo "${ipstrarr[*]}")
echo "allipstr4patch:${allipstr4patch}"
EOF
$SED -i '1r header.sh' start.sh
rm -f header.sh
$SED -i '/kubectl patch svc istio-ingressgateway -n istio-system -p/d' start.sh
cat << \EOF >> start.sh
#kubectl patch svc istio-ingressgateway -n istio-system -p '{"spec":{"externalIPs":['${allipstr4patch}']}}'
for node in dtpct mdubu
do
    kubectl label node ${node} gpu=true vgpu=true
done
kubectl label node dtpct gpu-type=3060
kubectl label node mdubu gpu-type=3050
EOF
kubectl logs -n monitoring           dcgm-exporter-kmb82
    Warning #2: dcgm-exporter doesn't have sufficient privileges to expose profiling metrics. To get profiling metrics with dcgm-exporter, use --cap-add SYS_ADMIN
    time="2023-04-22T23:44:52Z" level=info msg="Starting dcgm-exporter"
    Error: Failed to initialize NVML
    time="2023-04-22T23:44:52Z" level=fatal msg="Error starting nv-hostengine: DCGM initialization error"
file=gpu/dcgm-exporter.yaml
cp ${file} ${file}.bk
#增加容器权限
    securityContext:
      capabilities:
        add: ["SYS_ADMIN"]
kubectl logs -n kubeflow             frameworkcontroller-0
    E0423 08:05:33.461529       9 runtime.go:69] Observed a panic: &errors.errorString{s:"Failed to put CRD: the server could not find the requested resource"} (Failed to put CRD: the server could not find the requested resource)
    /go/src/github.com/microsoft/frameworkcontroller/vendor/k8s.io/apimachinery/pkg/util/runtime/runtime.go:76
    /go/src/github.com/microsoft/frameworkcontroller/vendor/k8s.io/apimachinery/pkg/util/runtime/runtime.go:65
    /go/src/github.com/microsoft/frameworkcontroller/vendor/k8s.io/apimachinery/pkg/util/runtime/runtime.go:51
    /usr/local/go/src/runtime/panic.go:522
    /go/src/github.com/microsoft/frameworkcontroller/pkg/internal/utils.go:66
    /go/src/github.com/microsoft/frameworkcontroller/pkg/controller/controller.go:428
    /go/src/github.com/microsoft/frameworkcontroller/cmd/frameworkcontroller/main.go:35
    /usr/local/go/src/runtime/proc.go:200
    /usr/local/go/src/runtime/asm_amd64.s:1337
    E0423 08:05:33.461548       9 panic.go:522] Stopping frameworkcontroller
    panic: Failed to put CRD: the server could not find the requested resource [recovered]
        panic: Failed to put CRD: the server could not find the requested resource

    goroutine 1 [running]:
    github.com/microsoft/frameworkcontroller/vendor/k8s.io/apimachinery/pkg/util/runtime.HandleCrash(0x0, 0x0, 0x0)
        /go/src/github.com/microsoft/frameworkcontroller/vendor/k8s.io/apimachinery/pkg/util/runtime/runtime.go:58 +0x105
    panic(0x11f84e0, 0xc0004720e0)
        /usr/local/go/src/runtime/panic.go:522 +0x1b5
    github.com/microsoft/frameworkcontroller/pkg/internal.PutCRD(0xc0002faf00, 0xc000343340, 0xc0003470a8, 0xc0003470b0)
        /go/src/github.com/microsoft/frameworkcontroller/pkg/internal/utils.go:66 +0x173
    github.com/microsoft/frameworkcontroller/pkg/controller.(*FrameworkController).Run(0xc0000c13f0, 0xc00009d140)
        /go/src/github.com/microsoft/frameworkcontroller/pkg/controller/controller.go:428 +0x157
    main.main()
        /go/src/github.com/microsoft/frameworkcontroller/cmd/frameworkcontroller/main.go:35 +0x47
    localhost:kubernetes apple$ kubectl wait crd/frameworks.frameworkcontroller.microsoft.com --for condition=established --timeout=60s
    Error from server (NotFound): customresourcedefinitions.apiextensions.k8s.io "frameworks.frameworkcontroller.microsoft.com" not found
$SED -i '/kubectl create -f frameworkcontroller\/frameworkcontroller-with-default-config.yaml/i\kubectl create -f frameworkcontroller\/crd.yaml'  start.sh
kubectl create -f frameworkcontroller/crd.yaml
    The CustomResourceDefinition "frameworks.frameworkcontroller.microsoft.com" is invalid: 
    * spec.validation.openAPIV3Schema.properties[metadata].type: Invalid value: "": must be object
    * spec.validation.openAPIV3Schema.properties[metadata].type: Required value: must not be empty for specified object fields
    * spec.validation.openAPIV3Schema.properties[spec].properties[executionType].type: Required value: must not be empty for specified object fields
    * spec.validation.openAPIV3Schema.properties[spec].properties[retryPolicy].type: Required value: must not be empty for specified object fields
    * spec.validation.openAPIV3Schema.properties[spec].properties[taskRoles].items.properties[frameworkAttemptCompletionPolicy].type: Required value: must not be empty for specified object fields
    * spec.validation.openAPIV3Schema.properties[spec].properties[taskRoles].items.type: Required value: must not be empty for specified array items
    * spec.validation.openAPIV3Schema.properties[spec].type: Required value: must not be empty for specified object fields
    * spec.validation.openAPIV3Schema.type: Required value: must not be empty at the root
    * spec.preserveUnknownFields: Invalid value: true: cannot set to true, set x-kubernetes-preserve-unknown-fields to true in spec.versions[*].schema instead
file=frameworkcontroller/crd.yaml
cp ${file} ${file}.bk
#删除
  preserveUnknownFields: true
#删除整个status
status:

  storageClassName: local-path     #此处为你命名的StorageClass name


sh start.sh 192.168.3.14,192.168.3.6,192.168.3.103

cp ${CUBESTUDIO_PRJ_HOME}/stop.sh ./
cp ${CUBESTUDIO_PRJ_HOME}/remove_ns_secret.sh ./

sh stop.sh 192.168.3.14,192.168.3.6,192.168.3.103
#中间停住不动的地方，多数是删除pvc时，按ctrl+c
remove_abnormal_pods.sh
kubectl get pods -A
kubectl proxy --port=8009 &
remove_terminating_nses.sh
kubectl get ns | grep Terminating