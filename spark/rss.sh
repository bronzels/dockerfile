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

RSS_VERSION=0.1.4
spark_rev=3.3
SPARK_VERSION=3.3.1

cd ${MYSPARK_HOME}
wget -c https://github.com/apache/incubator-celeborn/archive/refs/tags/v${RSS_VERSION}.tar.gz
tar xzvf incubator-celeborn-${RSS_VERSION}.tar.gz
ln -s incubator-celeborn-${RSS_VERSION} celeborn
cd celeborn
./dev/make-distribution.sh -Pspark-${spark_rev}

cd ${MYSPARK_HOME}
git clone git@github.com:apache/incubator-celeborn.git
cd incubator-celeborn/docker
cp ../../celeborn/rss-${RSS_VERSION}-bin-release.tgz ./
tar xzvf rss-${RSS_VERSION}-bin-release.tgz
#为重新构建应用准备，copy RSS的client包
cp rss-${RSS_VERSION}-bin-release/spark/rss-shuffle-manager-${RSS_VERSION}-shaded.jar ${MYSPARK_HOME}/
file=Dockerfile
cp ${file} ${file}.bk
$SED -i '/ARG celeborn_gid=10006/a\ARG RSS_VERSION=\' ${file}
$SED -i 's/COPY /COPY rss-${RSS_VERSION}-bin-release\//g' ${file}
$SED -i 's/COPY rss-${RSS_VERSION}-bin-release\/jars/#COPY rss-${RSS_VERSION}-bin-release\/jars/g' ${file}

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

cd ${MYSPARK_HOME}
cd incubator-celeborn/charts/celeborn/

ansible all -m shell -a"rm -rf /data0/celeborn;mkdir -p /data0/celeborn/cache;mkdir -p /data0/celeborn/ratis"

kubectl create ns spark-rss
cp -rf templates templates.bk
find templates -name "*.yaml" | xargs $SED -i 's@    {{ - include "celeborn.labels" . | nindent 4 }}@{{ include "celeborn.labels" . | nindent 4 }}@g'
find templates -name "*.yaml" | xargs $SED -i 's@    {{- include "celeborn.labels" . | nindent 4 }}@{{ include "celeborn.labels" . | nindent 4 }}@g'
find templates -name "*.yaml" | xargs $SED -i 's@      {{- include "celeborn.selectorLabels" . | nindent 6 }}@{{ include "celeborn.selectorLabels" . | nindent 6 }}@g'
find templates -name "*.yaml" | xargs $SED -i 's@    {{- include "celeborn.selectorLabels" . | nindent 4 }}@{{ include "celeborn.selectorLabels" . | nindent 4 }}@g'
find templates -name "*.yaml" | xargs $SED -i 's@        {{- include "celeborn.selectorLabels" . | nindent 8 }}@{{ include "celeborn.selectorLabels" . | nindent 8 }}@g'
find templates -name "*.yaml" | xargs $SED -i 's@        {{- toYaml . | nindent 8 }}@{{- toYaml . | nindent 8 }}@g'
find templates -name "*.yaml" | xargs $SED -i 's@          {{- toYaml .Values.resources.master | nindent 12 }}@{{- toYaml .Values.resources.master | nindent 12 }}@g'
find templates -name "*.yaml" | xargs $SED -i 's@{ {@{{@g'
find templates -name "*.yaml" | xargs $SED -i 's@} }@}}@g'
helm install my -n spark-rss -f values.yaml \
  --set workerReplicas=3 \
  --set image.repository=harbor.my.org:1080/aliyunemr/remote-shuffle-service \
  --set image.pullPolicy=IfNotPresent \
  --set image.tag=${RSS_VERSION} \
  --set celebornVersion=${RSS_VERSION} \
  --set celeborn.celeborn.ha.master.ratis.raft.server.storage.dir=/data0/celeborn/ratis/ \
  --set celeborn.celeborn.worker.storage.dirs=/data0/celeborn/cache \
  --set environments.CELEBORN_MASTER_MEMORY=2g \
  --set environments.CELEBORN_WORKER_MEMORY=2g \
  --set environments.CELEBORN_WORKER_OFFHEAP_MEMORY=4g \
  ./
:<<EOF
  --set celeborn.ha.master.ratis.raft.server.storage.dir=/data0/celeborn/ratis/ \
  --set celeborn.worker.storage.dirs=/data0/celeborn/cache \
EOF

watch kubectl get all -n spark-rss