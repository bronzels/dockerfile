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

FLINKCDC_HOME=${MYHOME}/workspace/dockerfile/flinkcdc

FLINK_VERSION=1.18.1
FLINK_SHORT_VERSION=1.18


FLINK_K8S_OP_VERSION=1.8.0
#FLINK_K8S_OP_VERSION=1.6.1
#seatunnel works only with 1.3.1
#FLINK_K8S_OP_VERSION=1.3.1

FLINK_CDC_VERSION=3.0.1
MYSQL_PIPELINE_CONNECTOR_VERSION=3.0.1
STARROCKS_PIPELINE_CONNECTOR_VERSION=3.0.1


cd ${FLINKCDC_HOME}

#while ! ; do sleep 2 ; done ; echo succeed

:<<EOF
wget -c https://github.com/jetstack/cert-manager/releases/download/v1.8.2/cert-manager.yaml
kubectl create -f cert-manager.yaml
kubectl get pods -A |grep cert-manager
kubectl delete -f cert-manager.yaml

#wget -c https://downloads.apache.org/flink/flink-kubernetes-operator-1.8.0/#:~:text=Parent%20Directory%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%2D-,flink%2Dkubernetes%2Doperator%2D1.8.0%2Dhelm.tgz,-2024%2D03%2D22
#tar xzvf flink-kubernetes-operator-1.8.0-helm.tgz


helm repo remove flink_operator-repo
#helm repo add flink_operator-repo https://downloads.apache.org/flink/flink-kubernetes-operator-${FLINK_K8S_OP_VERSION}/
helm repo add flink_operator-repo https://archive.apache.org/dist/flink/flink-kubernetes-operator-${FLINK_K8S_OP_VERSION}/
helm pull flink_operator-repo/flink-kubernetes-operator
helm install flink-kubernetes-operator flink_operator-repo/flink-kubernetes-operator \
    --create-namespace \
    --namespace flink

kubectl get pod -n flink |grep -v Running |awk '{print $1}'| xargs kubectl delete -n flink pod "$1" --force --grace-period=0
helm uninstall flink-kubernetes-operator -n flink
kubectl get all -n flink

docker run --rm --name flink-test flink:${FLINK_VERSION} cat /opt/flink/conf/flink-conf.yaml > flink-conf-${FLINK_VERSION}.yaml
file=flink-conf-${FLINK_VERSION}.yaml
cp ${file} ${file}.bk
$SED -i '/# execution.checkpointing.interval: 3min/a\execution.checkpointing.interval: 3000' ${file}

kubectl apply -n flink -f jfs-pvcs.yaml
kubectl delete -n flink -f jfs-pvcs.yaml
kubectl get pvc -n flink

kubectl apply -n flink -f flink-user-pod.yaml
kubectl delete -n flink -f flink-user-pod.yaml

kubectl exec -n flink `kubectl get pod -n flink |grep flink-user |grep Running |awk '{print $1}'` -- mkdir -p /opt/flink/user/wordcount/trino_wordcount
kubectl exec -n flink `kubectl get pod -n flink |grep flink-user |grep Running |awk '{print $1}'` -- chmod 777 /opt/flink/user/wordcount
kubectl exec -n flink `kubectl get pod -n flink |grep flink-user |grep Running |awk '{print $1}'` -- chmod 777 /opt/flink/user/wordcount/trino_wordcount
kubectl cp trino.txt -n flink `kubectl get pod -n flink |grep flink-user |grep Running |awk '{print $1}'`:/opt/flink/user/wordcount/

kubectl apply -n flink -f flink-wordcount.yaml
kubectl delete -n flink -f flink-wordcount.yaml
kubectl exec -n flink `kubectl get pod -n flink |grep flink-wordcount |grep Running |awk '{print $1}'` -- cat /opt/flink/user/trino.txt
kubectl exec -n flink `kubectl get pod -n flink |grep flink-wordcount |grep Running |awk '{print $1}'` -- cat /opt/flink/conf/flink-conf.yaml
kubectl exec -n flink `kubectl get pod -n flink |grep flink-user |grep Running |awk '{print $1}'` -- ls /opt/flink/state
kubectl exec -n flink `kubectl get pod -n flink |grep flink-user |grep Running |awk '{print $1}'` -- ls /opt/flink/user/wordcount/trino_output/2024-04-18--06
kubectl exec -n flink `kubectl get pod -n flink |grep flink-user |grep Running |awk '{print $1}'` -- cat /opt/flink/user/wordcount/trino_output/2024-04-18--06/part-c94df982-eed4-4467-b7a1-6808fc37a37a-0

kubectl apply -n flink -f flink-session-cluster.yaml
kubectl delete -n flink -f flink-session-cluster.yaml

kubectl exec -n flink `kubectl get pod -n flink |grep flink-user |grep Running |awk '{print $1}'` -- mkdir -p /opt/flink/user/flinkcdc
kubectl cp flink-session-cluster.yaml -n flink `kubectl get pod -n flink |grep flink-user |grep Running |awk '{print $1}'`:/opt/flink/user/flinkcdc/

kubectl exec -n flink `kubectl get pod -n flink |grep flink-session-cluster |grep Running |awk '{print $1}'` -- whereis flink-cdc.sh
flink-cdc.sh mysql-to-starrocks.yaml

kubectl apply -n flink -f flink-cdc-pvc.yaml
kubectl delete -n flink -f flink-cdc-pvc.yaml
kubectl get pvc -n flink


DOCKER_BUILDKIT=1 docker build ./ --progress=plain\
 --build-arg FLINK_VERSION="${FLINK_VERSION}"\
 --build-arg FLINK_CDC_VERSION="${FLINK_CDC_VERSION}"\
 --build-arg MYSQL_PIPELINE_CONNECTOR_VERSION="${MYSQL_PIPELINE_CONNECTOR_VERSION}"\
 --build-arg STARROCKS_PIPELINE_CONNECTOR_VERSION="${STARROCKS_PIPELINE_CONNECTOR_VERSION}"\
 -t harbor.my.org:1080/flink/flink:cdc-${FLINK_CDC_VERSION}-flink-${FLINK_VERSION}
docker push harbor.my.org:1080/flink/flink:cdc-${FLINK_CDC_VERSION}-flink-${FLINK_VERSION}
ansible all -m shell -a"docker rmi harbor.my.org:1080/flink/flink:cdc-${FLINK_CDC_VERSION}-flink-${FLINK_VERSION}"

kubectl create ns flink
kubectl create serviceaccount flink -n flink
#kubectl create clusterrolebinding flink-role-bind --clusterrole=edit --serviceaccount=flink:flink
kubectl create clusterrolebinding flink-role-bind --clusterrole=cluster-admin --serviceaccount=flink:flink

#
file=flink/conf/flink-conf.yaml
cp ${file} ${file}.bk
echo "kubernetes.container.image.ref: harbor.my.org:1080/flink/flink:cdc-3.0.1-flink-1.18.1" >> ${file}

#export FLINK_HOME=$PWD/flink
flink/bin/kubernetes-session.sh \
 -Dkubernetes.namespace=flink \
 -Dkubernetes.jobmanager.service-account=flink \
 -Dkubernetes.rest-service.exposed.type=NodePort \
 -Dkubernetes.cluster-id=flink-cluster \
 -Dkubernetes.jobmanager.cpu=1 \
 -Djobmanager.memory.process.size=1024m \
 -Dresourcemanager.taskmanager-timeout=3600000 \
 -Dkubernetes.taskmanager.cpu=8 \
 -Dtaskmanager.memory.process.size=8192m \
 -Dtaskmanager.numberOfTaskSlots=8 \
 -Dexecution.checkpointing.interval: 3000
#2024-04-18 17:37:11,471 INFO  org.apache.flink.kubernetes.KubernetesClusterDescriptor      [] - Create flink session cluster flink-cluster successfully, JobManager Web Interface: http://192.168.3.14:52865
#flink/bin/kubernetes-session.sh stop flink-cluster
kubectl delete -n flink deployment.apps flink-cluster
kubectl cp flink-cdc-${FLINK_CDC_VERSION} -n flink `kubectl get pod -n flink |grep flink-cluster |grep Running |awk '{print $1}'`:/opt/flink/flink-cdc
kubectl cp flink-cdc-pipeline-connector-mysql-${MYSQL_PIPELINE_CONNECTOR_VERSION}.jar -n flink `kubectl get pod -n flink |grep flink-cluster |grep Running |awk '{print $1}'`:/opt/flink/lib/
kubectl cp flink-cdc-pipeline-connector-starrocks-${STARROCKS_PIPELINE_CONNECTOR_VERSION}.jar -n flink `kubectl get pod -n flink |grep flink-cluster |grep Running |awk '{print $1}'`:/opt/flink/lib/

EOF

#dtpct
docker-compose up

tar xzvf flink-${FLINK_VERSION}-bin-scala_2.12.tgz
ln -s flink-1.18.1 flink
cd flink
tar xvf flink-cdc-${FLINK_CDC_VERSION}-bin.tar
ln -s flink-cdc-3.0.1 flink-cdc
cp flink-cdc-pipeline-connector-mysql-${MYSQL_PIPELINE_CONNECTOR_VERSION}.jar flink-cdc/lib/;
cp flink-cdc-pipeline-connector-starrocks-${STARROCKS_PIPELINE_CONNECTOR_VERSION}.jar flink-cdc/lib/;
echo "FLINK_HOME=$PWD" >> ~/.bashrc
echo "export FLINK_HOME=$PWD" >> ~/.zshrc
source ~/.bashrc

file=flink/conf/flink-conf.yaml
cp ${file} ${file}.bk
$SED -i "s@taskmanager.memory.process.size: 1728m@#taskmanager.memory.process.size: 1728m@g" ${file}
$SED -i "/#taskmanager.memory.process.size: 1728m/a\taskmanager.memory.process.size: 8192m" ${file}
$SED -i "s@taskmanager.numberOfTaskSlots: 1@#taskmanager.numberOfTaskSlots: 1@g" ${file}
$SED -i "/#taskmanager.numberOfTaskSlots: 1/a\taskmanager.numberOfTaskSlots: 8" ${file}
$SED -i "/# state.checkpoints.dir/a\state.checkpoints.dir: file:///data0/flink/state" ${file}
$SED -i "/# state.savepoints.dir/a\state.savepoints.dir: file:///data0/flink/state" ${file}
$SED -i "s@rest.bind-address: localhost@#rest.bind-address: localhost@g" ${file}
$SED -i "/#rest.bind-address: localhost/a\rest.bind-address: 0.0.0.0" ${file}
#very import, pekka execption block the schema change event.
echo "pekko.ask.timeout: 100s" >> ${file}
echo "web.timeout: 100000" >> ${file}
bin/start-cluster.sh

