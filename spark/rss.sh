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

MYSPARK_HOME=${MYHOME}/workspace/dockerfile/spark

#RSS_VERSION=0.3.0-SNAPSHOT
RSS_VERSION=0.2.0-incubating
spark_rev=3.3
SPARK_VERSION=3.3.1
#RSS_HOME=${MYSPARK_HOME}/incubator-celeborn
RSS_HOME=${MYSPARK_HOME}/incubator-celeborn-${RSS_VERSION}-rc3

cd ${MYSPARK_HOME}

wget -c https://github.com/apache/incubator-celeborn/archive/refs/tags/v0.2.0-incubating-rc3.tar.gz
tar xzvf incubator-celeborn-${RSS_VERSION}.tar.gz
:<<EOF
git clone git@github.com:apache/incubator-celeborn.git
EOF
#cd incubator-celeborn-${RSS_VERSION}
cd ${RSS_HOME}
./build/make-distribution.sh -Pspark-${spark_rev}
cp service/target/celeborn-service_2.12-${RSS_VERSION}.jar docker/

cd docker
tar xzvf ../apache-celeborn-${RSS_VERSION}-bin.tgz
#为重新构建应用准备，copy RSS的client包
cp apache-celeborn-${RSS_VERSION}-bin/spark/celeborn-client-spark-3-shaded_2.12-${RSS_VERSION}.jar ${MYSPARK_HOME}/
file=Dockerfile
cp ${file} ${file}.bk
$SED -i '/ARG celeborn_gid=10006/a\ARG RSS_VERSION=\' ${file}
$SED -i 's/COPY /COPY apache-celeborn-${RSS_VERSION}-bin\//g' ${file}
#$SED -i 's/COPY apache-celeborn-${RSS_VERSION}-bin\/jars/#COPY apache-celeborn-${RSS_VERSION}-bin\/jars/g' ${file}
#$SED -i '/COPY apache-celeborn-${RSS_VERSION}-bin\/RELEASE \/opt\/celeborn\/RELEASE/iCOPY server-common-0.1.4.jar /opt/celeborn/master-jars/' ${file}
#$SED -i '/COPY apache-celeborn-${RSS_VERSION}-bin\/RELEASE \/opt\/celeborn\/RELEASE/iCOPY server-common-0.1.4.jar /opt/celeborn/worker-jars/' ${file}
#$SED -i '/COPY apache-celeborn-${RSS_VERSION}-bin\/RELEASE \/opt\/celeborn\/RELEASE/iCOPY celeborn-service_2.12-${RSS_VERSION}.jar /opt/celeborn/master-jars/' ${file}
#$SED -i '/COPY apache-celeborn-${RSS_VERSION}-bin\/RELEASE \/opt\/celeborn\/RELEASE/iCOPY celeborn-service_2.12-${RSS_VERSION}.jar /opt/celeborn/worker-jars/' ${file}
docker build ./ --progress=plain --build-arg RSS_VERSION="${RSS_VERSION}" -t harbor.my.org:1080/aliyunemr/remote-shuffle-service:${RSS_VERSION}
docker push harbor.my.org:1080/aliyunemr/remote-shuffle-service:${RSS_VERSION}


#为重新构建spark准备，copy RSS的spark patch 支持dynamic allocation和celeborn rss
cd ${MYSPARK_HOME}
cp -rf spark-${SPARK_VERSION} spark-${SPARK_VERSION}.rss
:<<EOF
cd spark-${SPARK_VERSION}.rss
patch -p1 spark-${SPARK_VERSION}.rss < ${MYSPARK_HOME}/incubator-celeborn/assets/spark-patch/RSS_RDA_spark3.patch
EOF
#3.3.1打patch会失败，根据patch手工修改spark-${SPARK_VERSION}.rss源码，比较以后打补丁校验
cd ${MYSPARK_HOME}
find spark-${SPARK_VERSION}.rss -name "*.orig" | xargs rm -f
find spark-${SPARK_VERSION}.rss -name "*.rej" | xargs rm -f
cp -rf spark-${SPARK_VERSION} spark-${SPARK_VERSION}.2patch
diff -uprN spark-${SPARK_VERSION} spark-${SPARK_VERSION}.rss > RSS_RDA_spark3.patch.${SPARK_VERSION}
cd spark-${SPARK_VERSION}.2patch
patch -p1 < ../RSS_RDA_spark3.patch.${SPARK_VERSION}
cd ${MYSPARK_HOME}
diff spark-${SPARK_VERSION}.2patch spark-${SPARK_VERSION}.rss

cd ${RSS_HOME}
#cd charts/celeborn/
cd docker/helm

ansible all -m shell -a"rm -rf /data0/celeborn;mkdir -p /data0/celeborn/cache;mkdir -p /data0/celeborn/ratis;chmod a+rwx /data0/celeborn/cache;chmod a+rwx /data0/celeborn/ratis"
ansible all -m shell -a"ls -l /data0/celeborn"

kubectl create ns spark-rss
cp -rf templates templates.bk
:<<EOF
find templates -name "*.yaml" | xargs $SED -i 's@    {{ - include "celeborn.labels" . | nindent 4 }}@{{ include "celeborn.labels" . | nindent 4 }}@g'
find templates -name "*.yaml" | xargs $SED -i 's@    {{- include "celeborn.labels" . | nindent 4 }}@{{ include "celeborn.labels" . | nindent 4 }}@g'
find templates -name "*.yaml" | xargs $SED -i 's@      {{- include "celeborn.selectorLabels" . | nindent 6 }}@{{ include "celeborn.selectorLabels" . | nindent 6 }}@g'
find templates -name "*.yaml" | xargs $SED -i 's@    {{- include "celeborn.selectorLabels" . | nindent 4 }}@{{ include "celeborn.selectorLabels" . | nindent 4 }}@g'
find templates -name "*.yaml" | xargs $SED -i 's@        {{- include "celeborn.selectorLabels" . | nindent 8 }}@{{ include "celeborn.selectorLabels" . | nindent 8 }}@g'
find templates -name "*.yaml" | xargs $SED -i 's@        {{- toYaml . | nindent 8 }}@{{- toYaml . | nindent 8 }}@g'
find templates -name "*.yaml" | xargs $SED -i 's@          {{- toYaml .Values.resources.master | nindent 12 }}@{{- toYaml .Values.resources.master | nindent 12 }}@g'
find templates -name "*.yaml" | xargs $SED -i 's@{ {@{{@g'
find templates -name "*.yaml" | xargs $SED -i 's@} }@}}@g'
EOF
file=templates/master-statefulset.yaml
$SED -i 's@{{ index $dirs 0 }}/ratis@{{get .Values.celeborn "celeborn.ha.master.ratis.raft.server.storage.dir"}}@g' $file
$SED -i '/{{- $dirs := get .Values.celeborn "celeborn.worker.storage.dirs" | splitList ","}}/d' $file
$SED -i '/          - "until {{ range until (.Values.masterReplicas |int) }}nslookup celeborn-master-{{ . }}.celeborn-master-svc && {{ end }}true; do echo waiting for master; sleep 2; done && /d' $file
$SED -i '/        resources:/i\          - "/opt/celeborn/sbin/start-master.sh && until {{ range until (.Values.masterReplicas |int) }}nslookup celeborn-master-{{ . }}.celeborn-master-svc && {{ end }}true; do echo waiting for master; sleep 2; done && echo exit of master replicas checking && tail -f /opt/celeborn/logs/`ls /opt/celeborn/logs`"\' ${file}
file=templates/worker-statefulset.yaml
$SED -i 's/            path: {{ $dir }}\/worker/            path: {{ $dir }}/g' $file
$SED -i '/          - "until {{ range until (.Values.masterReplicas |int) }}nslookup celeborn-master-{{ . }}.celeborn-master-svc && {{ end }}true; do echo waiting for master; sleep 2; done && /d' $file
$SED -i '/        resources:/i\          - "until {{ range until (.Values.masterReplicas |int) }}nslookup celeborn-master-{{ . }}.celeborn-master-svc && {{ end }}true; do echo waiting for master; sleep 2; done && echo exit of master replicas checking && /opt/celeborn/sbin/start-worker.sh && tail -f /opt/celeborn/logs/`ls /opt/celeborn/logs`"\' ${file}
#不知道什么原因，这2个配置无法用--set传入
file=values.yaml
cp ${file} ${file}.bk
$SED -i 's@  celeborn.ha.master.ratis.raft.server.storage.dir: /mnt/rss_ratis/@  celeborn.ha.master.ratis.raft.server.storage.dir: /data0/celeborn/ratis@g' $file
$SED -i 's@  celeborn.worker.storage.dirs: /mnt/disk1,/mnt/disk2,/mnt/disk3,/mnt/disk4@  celeborn.worker.storage.dirs: /data0/celeborn/cache@g' $file
:<<EOF
file=templates/configmap.yaml
$SED -i 's@    *.sink.prometheusServlet.class=org.apache.celeborn.common.metrics.sink.PrometheusServlet@    *.sink.prometheusServlet.class=com.aliyun.emr.rss.common.metrics.sink.PrometheusServlet@g' $file
#EOF
helm install my -n spark-rss -f values.yaml \
  --set workerReplicas=2 \
  --set image.repository=harbor.my.org:1080/aliyunemr/remote-shuffle-service \
  --set image.pullPolicy=IfNotPresent \
  --set image.tag=${RSS_VERSION} \
  --set celebornVersion=${RSS_VERSION} \
  --set environments.CELEBORN_MASTER_MEMORY=2g \
  --set environments.CELEBORN_WORKER_MEMORY=2g \
  --set environments.CELEBORN_WORKER_OFFHEAP_MEMORY=4g \
  ./

:<<EOF
  --set celeborn.celeborn.metrics.enabled=false \
  --set podMonitor.enable=false \

  --set environments.CELEBORN_NO_DAEMONIZE=0 \

  --set celeborn.celeborn.ha.master.ratis.raft.server.storage.dir=/data0/celeborn/ratis \
  --set celeborn.celeborn.worker.storage.dirs=/data0/celeborn/cache \

  --set celeborn.ha.master.ratis.raft.server.storage.dir=/data0/celeborn/ratis \
  --set celeborn.worker.storage.dirs=/data0/celeborn/cache \

EOF
helm uninstall my -n spark-rss

watch kubectl get all -n spark-rss

kubectl cp -n spark-rss ${MYSPARK_HOME}/celeborn/bin/rss-class `kubectl get pod -n spark-rss | grep Running | grep master-0 | awk '{print $1}'`:/opt/celeborn/bin/rss-class
