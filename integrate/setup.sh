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

INT_HOME=${PRJ_HOME}/integrate

#TARGET_BUILT=hadoop2hive2
TARGET_BUILT=hadoop3hive3

FLINK_VERSION=1.16.1
FLINK_SHORT_VERSION=1.16

:<<EOF

FLINK_VERSION=1.17.0
FLINK_SHORT_VERSION=1.17

FLINK_VERSION=1.15.4
FLINK_SHORT_VERSION=1.15

FLINK_VERSION=1.15.4
FLINK_SHORT_VERSION=1.15
EOF

BITSAIL_REV=0.1.0

CHUNJUN_REV=master

SEATUNNEL_VERSION=2.3.4

INLONG_VERSION=1.11.0

export PATH=$PATH:${INT_HOME}

cd ${INT_HOME}


# bitsail start--------------------------------------------
unzip bitsail-master.zip
tar xzvf release-0.1.0.tar.gz
cd bitsail-release-0.1.0/
file=build.sh
cp ${file} ${file}.bk
#$SED -i 's/mvn clean package/mvn clean package -Denforcer.skip=true/g' ${file}
build.sh flink-1.16,flink-1.16-embedded
cp ${INT_HOME}/bitsail-master/bitsail-dist/src/main/resources/Dockerfile ${INT_HOME}/bitsail-release-${BITSAIL_REV}/
file=Dockerfile
cp ${file} ${file}.bk

cp ${INT_HOME}/bitsail-release-${BITSAIL_REV}/${file} ${INT_HOME}/${file}-bitsail

DOCKER_BUILDKIT=1 docker build ./ --progress=plain\
 --build-arg FLINK_VERSION="${FLINK_VERSION}"\
 --build-arg TARGET_BUILT="${TARGET_BUILT}"\
 -t harbor.my.org:1080/integrate/bitsail:${BITSAIL_REV}
docker push harbor.my.org:1080/integrate/bitsail:${BITSAIL_REV}

cp ${INT_HOME}/${file}-bitsail ${INT_HOME}/bitsail-release-${BITSAIL_REV}/${file} 

# bitsail end--------------------------------------------


# chunjun start--------------------------------------------
unzip chunjun-master.zip

# chunjun end--------------------------------------------


# seatunnel start--------------------------------------------
#setup flink-kubernetes-operator 1.3.1(1.8.0, 1.6.1  have compatibility issues)
#only for seatunnel compatibility concern
#FLINK_SHORT_VERSION=1.18
#FLINK_SHORT_VERSION=1.13
FLINK_SHORT_VERSION=1.15

wget "https://archive.apache.org/dist/seatunnel/${SEATUNNEL_VERSION}/apache-seatunnel-${SEATUNNEL_VERSION}-bin.tar.gz"
#tar -xzvf "apache-seatunnel-${SEATUNNEL_VERSION}-bin.tar.gz"
DOCKER_BUILDKIT=1 docker build -f Dockerfile-seatunnel ./ --progress=plain\
 --build-arg SEATUNNEL_VERSION="${SEATUNNEL_VERSION}"\
 --build-arg FLINK_SHORT_VERSION="${FLINK_SHORT_VERSION}"\
 -t harbor.my.org:1080/integrate/seatunnel:${SEATUNNEL_VERSION}-flink-${FLINK_SHORT_VERSION}
docker push harbor.my.org:1080/integrate/seatunnel:${SEATUNNEL_VERSION}-flink-${FLINK_SHORT_VERSION}
ansible all -m shell -a"docker rmi harbor.my.org:1080/integrate/seatunnel:${SEATUNNEL_VERSION}-flink-${FLINK_SHORT_VERSION}"

kubectl create cm -n flink seatunnel-config --from-file=seatunnel-config
kubectl delete cm -n flink seatunnel-config

cp seatunnel-flink-template.yaml seatunnel-yaml/seatunnel-flink-streaming-fake.yaml
$SED -i 's@seatunnel-flink-streaming-example@seatunnel-flink-streaming-fake@g' seatunnel-yaml/seatunnel-flink-streaming-fake.yaml
$SED -i 's@            - key: seatunnel.streaming.conf@            - key: seatunnel.streaming.fake.conf@g' seatunnel-yaml/seatunnel-flink-streaming-fake.yaml
kubectl apply -n flink -f seatunnel-yaml/seatunnel-flink-streaming-fake.yaml
kubectl delete -n flink -f seatunnel-yaml/seatunnel-flink-streaming-fake.yaml
kubectl logs -f -n flink deploy/seatunnel-flink-streaming-fake

cp seatunnel-flink-template.yaml seatunnel-yaml/seatunnel-flink-streaming-mongo2mysql.yaml
$SED -i 's@seatunnel-flink-streaming-example@seatunnel-flink-streaming-mongo2mysql@g' seatunnel-yaml/seatunnel-flink-streaming-mongo2mysql.yaml
$SED -i 's@            - key: seatunnel.streaming.conf@            - key: seatunnel.streaming.mongo2mysql.conf@g' seatunnel-yaml/seatunnel-flink-streaming-mongo2mysql.yaml
kubectl apply -n flink -f seatunnel-yaml/seatunnel-flink-streaming-mongo2mysql.yaml
kubectl delete -n flink -f seatunnel-yaml/seatunnel-flink-streaming-mongo2mysql.yaml
kubectl logs -f -n flink deploy/seatunnel-flink-streaming.mongo2mysql


kubectl get pod -n flink |grep -v Running |awk '{print $1}'| xargs kubectl delete -n flink pod "$1" --force --grace-period=0

:<<EOF
#flinkVersion: v1_13
版本1.8的operator在flink版本是1.13时不创建pod
#flinkVersion: v1_18/v1_15
2024-04-16 09:08:09,370 WARN  org.apache.flink.client.deployment.application.ApplicationDispatcherBootstrap [] - Application failed unexpectedly: 
java.util.concurrent.CompletionException: org.apache.flink.client.deployment.application.ApplicationExecutionException: Could not execute application.
	at java.util.concurrent.CompletableFuture.encodeThrowable(Unknown Source) ~[?:?]
	at java.util.concurrent.CompletableFuture.completeThrowable(Unknown Source) ~[?:?]
	at java.util.concurrent.CompletableFuture$UniCompose.tryFire(Unknown Source) ~[?:?]
	at java.util.concurrent.CompletableFuture.postComplete(Unknown Source) ~[?:?]
	at java.util.concurrent.CompletableFuture.completeExceptionally(Unknown Source) ~[?:?]
	at org.apache.flink.client.deployment.application.ApplicationDispatcherBootstrap.runApplicationEntryPoint(ApplicationDispatcherBootstrap.java:337) ~[flink-dist-1.18.1.jar:1.18.1]
	at org.apache.flink.client.deployment.application.ApplicationDispatcherBootstrap.lambda$runApplicationAsync$2(ApplicationDispatcherBootstrap.java:254) ~[flink-dist-1.18.1.jar:1.18.1]
	at java.util.concurrent.Executors$RunnableAdapter.call(Unknown Source) ~[?:?]
	at java.util.concurrent.FutureTask.run(Unknown Source) ~[?:?]
	at org.apache.flink.runtime.concurrent.pekko.ActorSystemScheduledExecutorAdapter$ScheduledFutureTask.run(ActorSystemScheduledExecutorAdapter.java:172) ~[?:?]
	at org.apache.flink.runtime.concurrent.ClassLoadingUtils.runWithContextClassLoader(ClassLoadingUtils.java:68) ~[flink-dist-1.18.1.jar:1.18.1]
	at org.apache.flink.runtime.concurrent.ClassLoadingUtils.lambda$withContextClassLoader$0(ClassLoadingUtils.java:41) ~[flink-dist-1.18.1.jar:1.18.1]
	at org.apache.pekko.dispatch.TaskInvocation.run(AbstractDispatcher.scala:59) [flink-rpc-akka78bcc542-096b-48c6-9ddf-0d105a068c14.jar:1.18.1]
	at org.apache.pekko.dispatch.ForkJoinExecutorConfigurator$PekkoForkJoinTask.exec(ForkJoinExecutorConfigurator.scala:57) [flink-rpc-akka78bcc542-096b-48c6-9ddf-0d105a068c14.jar:1.18.1]
	at java.util.concurrent.ForkJoinTask.doExec(Unknown Source) [?:?]
	at java.util.concurrent.ForkJoinPool$WorkQueue.topLevelExec(Unknown Source) [?:?]
	at java.util.concurrent.ForkJoinPool.scan(Unknown Source) [?:?]
	at java.util.concurrent.ForkJoinPool.runWorker(Unknown Source) [?:?]
	at java.util.concurrent.ForkJoinWorkerThread.run(Unknown Source) [?:?]
Caused by: org.apache.flink.client.deployment.application.ApplicationExecutionException: Could not execute application.
	... 14 more
Caused by: java.lang.NoSuchMethodError: 'org.apache.flink.table.api.EnvironmentSettings$Builder org.apache.flink.table.api.EnvironmentSettings$Builder.useBlinkPlanner()'


EOF
# seatunnel end--------------------------------------------



# inlong end--------------------------------------------
#install cert-manager
#install local-provisioner

helm repo add apache https://pulsar.apache.org/charts
helm repo update
kubectl create ns pulsar
git clone git@github.com:apache/pulsar-helm-chart
cd pulsar-helm-chart
file=scripts/pulsar/common_auth.sh
cp ${file} ${file}.bk
#curl --retry 10 -L -o $install_script https://raw.githubusercontent.com/streamnative/pulsarctl/master/install.sh
wget -c https://raw.githubusercontent.com/streamnative/pulsarctl/master/install.sh -o ./scripts/pulsar/install.sh
./scripts/pulsar/prepare_helm_release.sh \
    -n pulsar \
    -k pulsar-mini \
    -c
#Your Helm version is not supported. Please upgrade to Helm 3.10.0 or later. The recommended version is currently 3.12.3 or newer.
#upgrade helm to latest above 3.10
while ! helm install \
    --values examples/values-minikube.yaml \
    --set initialize=true \
    --namespace pulsar \
    pulsar-mini apache/pulsar; do sleep 2 ; done ; echo succeed
while ! helm pull apache/pulsar; do sleep 2 ; done ; echo succeed
kubectl get pods -n pulsar
kubectl get pod -n pulsar |grep -v Running |awk '{print $1}'| xargs kubectl delete -n pulsar pod "$1" --force --grace-period=0


kubectl create namespace inlong
wget -c https://downloads.apache.org/inlong/${INLONG_VERSION}/apache-inlong-${INLONG_VERSION}-bin.tar.gz
tar xzvf apache-inlong-${INLONG_VERSION}-bin.tar.gz
cd apache-inlong-${INLONG_VERSION}-bin
file=values.yaml
cp ${file} ${file}.bk
helm upgrade inlong --install -n inlong ./
# inlong end--------------------------------------------
