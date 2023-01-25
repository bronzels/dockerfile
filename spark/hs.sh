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

SPARK_VERSION=3.3.1

git clone git@github.com:banzaicloud/banzai-charts.git
mv banzai-charts/spark-hs ./
rm -rf banzai-charts
cd spark-hs
cp -rf templates templates.bk
$SED -i 's@/opt/spark@/app/hdfs/spark@g' templates/deployment.yaml
$SED -i 's@extensions/v1beta1@apps/v1@g' templates/deployment.yaml
$SED -i '/  replicas:/i\  selector:\n    matchLabels:\n      app: {{ template "spark-hs.fullname" . }}' templates/deployment.yaml
$SED -i '/          - name: SPARK_NO_DAEMONIZE/i\          - name: HADOOP_USER_NAME\' templates/deployment.yaml
$SED -i '/          - name: SPARK_NO_DAEMONIZE/i\            value: hdfs\' templates/deployment.yaml
$SED -i '/    {{- printf "oci:\/\/%s@%s" .Values.sparkEventLogStorage.logDirectory .Values.sparkEventLogStorage.oracleNamespace }}/a\    {{- .Values.sparkEventLogStorage.logDirectory }}\' templates/deployment.yaml
$SED -i '/    {{- printf "oci:\/\/%s@%s" .Values.sparkEventLogStorage.logDirectory .Values.sparkEventLogStorage.oracleNamespace }}/a\  {{- else }}\' templates/deployment.yaml
$SED -i '/  spark-defaults.conf: |-i\  bootstrap.sh: |-\n#!\/bin\/bash\n    # append his credentials\n    envsubst < \/app\/hdfs\/spark\/prepared_conf\/spark-defaults.conf > \/app\/hdfs\/spark\/conf\/spark-defaults.conf\n    envsubst < \/app\/hdfs\/spark\/prepared_conf\/spark-defaults.conf > \/app\/hdfs\/spark\/conf\/spark-defaults.conf\n    \/app\/hdfs\/spark\/sbin\/start-history-server.sh' templates/spark-configmap.yaml
cp ${MYSPARK_HOME}/hs-spark-configmap.yaml templates/spark-configmap.yaml
cp ${MYSPARK_HOME}/hs-deployment.yaml templates/deployment.yaml

#构建spark image准备
wget -c https://github.com/a8m/envsubst/releases/download/v1.2.0/envsubst-Linux-x86_64 -o envsubst
chmod +x envsubst

helm install myhs -n spark-operator -f values.yaml \
  --set image.repository=harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss \
  --set image.tag=${SPARK_VERSION} \
  --set sparkEventLogStorage.logDirectory=jfs://miniofs/jobhistory/sparklogs \
  ./
helm uninstall myhs -n spark-operator

kubectl apply -f rss-juicefs-pvc.yaml -n spark-operator

kubectl port-forward -n spark-operator svc/myhs-spark-hs 2080:80 &
kubectl port-forward -n spark-operator myhs-spark-hs-b79b47f69-qd8lf 18081:18081 &

hadoop fs -get /jobhistory/sparklogs sparklogs
kubectl cp -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'`:/app/hdfs/hive/sparklogs sparklogs
kubectl cp sparklogs -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep myhs-spark-hs | awk '{print $1}'`:/app/hdfs/spark/sparklogs
#kubectl cp spark-default.conf -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep spark-test | awk '{print $1}'`:/app/hdfs/spark/conf/spark-default.conf
kubectl exec -it -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep myhs-spark-hs | awk '{print $1}'` -- bash
  spark-submit \
    --master \
    k8s://https://kubernetes.default.svc.cluster.local:443 \
    --deploy-mode cluster \
    --name spark-pi \
    --class org.apache.spark.examples.SparkPi \
    --conf spark.executor.instances=5 \
    --conf spark.kubernetes.namespace=spark-operator \
    --conf spark.kubernetes.file.upload.path=jfs://miniofs/tmp/k8sup \
    --conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss:3.3.1 \
    --conf spark.kubernetes.authenticate.driver.serviceAccountName=default \
    --conf spark.eventLog.enabled=true \
    --conf spark.eventLog.dir=jfs://miniofs/jobhistory/sparklogs \
    /app/hdfs/spark/examples/jars/spark-examples_2.12-3.3.1.jar
cat > ${SPARK_HOME}/conf/log4j.properties <<-EOF
log4j.rootLogger=debug,historyserver
log4j.appender.historyserver=org.apache.log4j.RollingFileAppender
log4j.appender.historyserver.layout=org.apache.log4j.PatternLayout
log4j.appender.historyserver.layout.ConversionPattern=%d{yy/MM/dd HH:mm:ss} %p %c{1}: %m%n
log4j.appender.historyserver.Threshold=INFO log4j.appender.historyserver.ImmediateFlush=TRUE
log4j.appender.historyserver.Append=TRUE log4j.appender.historyserver.File=${SPARK_HOME}/logs/historyserver.log
log4j.appender.historyserver.MaxFileSize=1GB log4j.appender.historyserver.MaxBackupIndex=2
log4j.appender.historyserver.Encoding=UTF-8
EOF
/opt/java/openjdk/bin/java -cp /app/hdfs/spark/conf/:/app/hdfs/spark/jars/* -Dspark.history.fs.logDirectory=file://app/hdfs/spark/sparklogs -Xmx1g org.apache.spark.deploy.history.HistoryServer
export SPARK_HISTORY_OPTS="$SPARK_HISTORY_OPTS -Dspark.history.ui.port=18081"


helm install myhs -n spark-operator -f values.yaml \
  --set image.repository=harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss \
  --set image.tag=${SPARK_VERSION} \
  --set sparkEventLogStorage.logDirectory=file:///tmp/sparklogs \
  ./
  spark-submit \
    --master \
    k8s://https://kubernetes.default.svc.cluster.local:443 \
    --deploy-mode cluster \
    --name spark-pi \
    --class org.apache.spark.examples.SparkPi \
    --conf spark.executor.instances=5 \
    --conf spark.kubernetes.namespace=spark-operator \
    --conf spark.kubernetes.file.upload.path=jfs://miniofs/tmp/k8sup \
    --conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss:3.3.1 \
    --conf spark.kubernetes.authenticate.driver.serviceAccountName=default \
    --conf spark.eventLog.enabled=true \
    --conf spark.kubernetes.driver.volumes.persistentVolumeClaim.juicefsvol.mount.path=/tmp/sparklogs \
    --conf spark.kubernetes.driver.volumes.persistentVolumeClaim.juicefsvol.readOnly=false \
    --conf spark.kubernetes.driver.volumes.persistentVolumeClaim.juicefsvol.options.claimName=rss-juicefs-pvc \
    --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.juicefsvol.mount.path=/tmp/sparklogs \
    --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.juicefsvol.readOnly=false \
    --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.juicefsvol.options.claimName=rss-juicefs-pvc \
    --conf spark.eventLog.dir=file:///tmp/sparklogs \
    /app/hdfs/spark/examples/jars/spark-examples_2.12-3.3.1.jar


  spark-submit \
    --name spark-pi \
    --class org.apache.spark.examples.SparkPi \
    --conf spark.executor.instances=5 \
    --conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss:3.3.1 \
    /app/hdfs/spark/examples/jars/spark-examples_2.12-3.3.1.jar
:<<EOF
    --master \
    k8s://https://kubernetes.default.svc.cluster.local:443 \
    --deploy-mode cluster \
    --conf spark.kubernetes.namespace=spark-operator \
    --conf spark.kubernetes.authenticate.driver.serviceAccountName=default \
    --conf spark.kubernetes.file.upload.path=jfs://miniofs/tmp/k8sup \
    --conf spark.eventLog.enabled=true \
    --conf spark.kubernetes.driver.volumes.persistentVolumeClaim.juicefsvol.mount.path=/tmp/sparklogs \
    --conf spark.kubernetes.driver.volumes.persistentVolumeClaim.juicefsvol.readOnly=false \
    --conf spark.kubernetes.driver.volumes.persistentVolumeClaim.juicefsvol.options.claimName=rss-juicefs-pvc \
    --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.juicefsvol.mount.path=/tmp/sparklogs \
    --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.juicefsvol.readOnly=false \
    --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.juicefsvol.options.claimName=rss-juicefs-pvc \
    --conf spark.eventLog.dir=file:///tmp/sparklogs \
EOF