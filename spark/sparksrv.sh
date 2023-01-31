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

cd ${MYSPARK_HOME}

git clone git@github.com:banzaicloud/banzai-charts.git
mv banzai-charts/spark-hs ./sparksrv
rm -rf banzai-charts
cd sparksrv
cp -rf templates templates.bk
$SED -i 's@/opt/spark@/app/hdfs/spark@g' templates/deployment.yaml
$SED -i 's@extensions/v1beta1@apps/v1@g' templates/deployment.yaml
$SED -i '/  replicas:/i\  selector:\n    matchLabels:\n      app: {{ template "spark-hs.fullname" . }}' templates/deployment.yaml
$SED -i '/          - name: SPARK_NO_DAEMONIZE/i\          - name: HADOOP_USER_NAME\' templates/deployment.yaml
$SED -i '/          - name: SPARK_NO_DAEMONIZE/i\            value: hdfs\' templates/deployment.yaml
$SED -i '/    {{- printf "oci:\/\/%s@%s" .Values.sparkEventLogStorage.logDirectory .Values.sparkEventLogStorage.oracleNamespace }}/a\    {{- .Values.sparkEventLogStorage.logDirectory }}\' templates/deployment.yaml
$SED -i '/    {{- printf "oci:\/\/%s@%s" .Values.sparkEventLogStorage.logDirectory .Values.sparkEventLogStorage.oracleNamespace }}/a\  {{- else }}\' templates/deployment.yaml
$SED -i '/  spark-defaults.conf: |-i\  bootstrap.sh: |-\n#!\/bin\/bash\n    # append his credentials\n    envsubst < \/app\/hdfs\/spark\/prepared_conf\/spark-defaults.conf > \/app\/hdfs\/spark\/conf\/spark-defaults.conf\n    envsubst < \/app\/hdfs\/spark\/prepared_conf\/spark-defaults.conf > \/app\/hdfs\/spark\/conf\/spark-defaults.conf\n    \/app\/hdfs\/spark\/sbin\/start-history-server.sh' templates/spark-configmap.yaml
file=values.yaml
cp ${file} ${file}.bk
$SED -i '/service:/a\  internalPortThrift: 10000' ${file}
$SED -i '/service:/a\  externalPortThrift: 4040' ${file}
$SED -i 's/{{ template "spark-hs.fullname" . }}/{{ template "spark-hs.fullname" . }}-hs/g' templates/service.yaml
file=Chart.yaml
cp ${file} ${file}.bk
find . -name "*.yaml" | xargs $SED -i 's/spark-hs/sparksrv/g'
$SED -i 's/A Helm chart for Spark HS in Kubernetes/A Helm chart for Spark HS and Thrift in Kubernetes/g' ${file}
$SED -i 's/spark-hs/sparksrv/g' templates/_helpers.tpl
cp ${MYSPARK_HOME}/sparksrv-spark-configmap.yaml templates/spark-configmap.yaml
cp ${MYSPARK_HOME}/sparksrv-deployment.yaml templates/deployment.yaml
#cp ${MYSPARK_HOME}/sparksrv-deployment-thrift.yaml templates/deployment-thrift.yaml
#cp ${MYSPARK_HOME}/sparksrv-service-thrift.yaml templates/service-thrift.yaml

#构建spark image准备
wget -c https://github.com/a8m/envsubst/releases/download/v1.2.0/envsubst-Linux-x86_64 -o envsubst
chmod +x envsubst

:<<EOF
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- bash
  hadoop fs -rm -r -f /jobhistory/sparklogs
  hadoop fs -mkdir /jobhistory/sparklogs
  hadoop fs -chmod 777 /jobhistory/sparklogs
EOF

helm install mysrv -n spark-operator -f values.yaml \
  --set image.repository=harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss \
  --set image.tag=${SPARK_VERSION} \
  --set sparkEventLogStorage.logDirectory=file:///tmp/sparklogs \
  ./
#  --set sparkEventLogStorage.logDirectory=jfs://miniofs/jobhistory/sparklogs \
helm uninstall mysrv -n spark-operator
#卸载以后重新安装，会出现history pvc无法挂载的情况，需要删除几个和Running pvc pod在同一节点的几个Terminating的pod
kubectl get pod -n kube-system -o wide | grep juicefs | grep pvc
kubectl get pod -n kube-system | grep juicefs | grep pvc | grep Terminating | awk '{print $1}' | xargs kubectl patch pod $1 -n kube-system -p '{"metadata":{"finalizers":null}}'
kubectl get pod -n kube-system -o wide | grep juicefs | grep pvc

kubectl apply -f rss-juicefs-pvc.yaml -n spark-operator

#需要先卸载hs，不能同时加载
kubectl apply -f rss-juicefs-pvc-test-pod.yaml -n spark-operator
kubectl delete -f rss-juicefs-pvc-test-pod.yaml -n spark-operator
kubectl exec -it -n spark-operator rss-juicefs-pvc-test-pod -- /bin/bash

kubectl port-forward -n spark-operator svc/mysrv-sparksrv-hs 2080:80 &
kubectl port-forward -n spark-operator svc/mysrv-sparksrv-thrs 4040:4040 &

hadoop fs -get /jobhistory/sparklogs sparklogs
kubectl cp -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'`:/app/hdfs/hive/sparklogs sparklogs
kubectl cp sparklogs -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep myhs-spark-hs | awk '{print $1}'`:/app/hdfs/spark/sparklogs
#kubectl cp spark-default.conf -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep spark-test | awk '{print $1}'`:/app/hdfs/spark/conf/spark-default.conf
kubectl logs -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep mysrv-sparksrv-hs | awk '{print $1}'`
kubectl exec -it -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep mysrv-sparksrv-hs | awk '{print $1}'` -- bash
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

#用volcano就必须用cluster模式，podgroup需要修改driver资源，但是spark-sql只能用client模式提交
git clone git@github.com:zhfk/spark-sql-cluster-mode.git
#基于spark3再次手工修改spark-sql-cluster-mode-3，打包jar进入，试用新SQLCli入口函数，用spark-submit方式提交sql作业

kubectl logs -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep mysrv-sparksrv-thrs | awk '{print $1}'`
kubectl exec -it -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep mysrv-sparksrv-thrs | awk '{print $1}'` -- bash
  beeline -u jdbc:hive2://mysrv-sparksrv-thrs:4040
  SHOW DATABASES;
  USE tpcds_bin_partitioned_orc_10;
  SHOW TABLES;
  SELECT * FROM store_sales LIMIT 5;
  #thrift server是用client方式提交一个作业到集群
  #实际测试，作业无法执行成功，只好放弃thrift server
  #而且业界同意thrift server不是一个生产级的方案，因为thrift server的client方式driver资源固定，不适合不同类型的作业对driver资源有不同要求