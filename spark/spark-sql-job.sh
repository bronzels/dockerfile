#!/bin/bash
container_image=$1
echo "container_image:${container_image}"
setting_sql_file=$2
echo "setting_sql_file:${setting_sql_file}"
execute_sql_file=$3
echo "execute_sql_file:${execute_sql_file}"
start=$(date +"%s.%9N")
spark-sql \
  --master \
  k8s://https://${K8S_APISERVER} \
  --deploy-mode client \
  --name ${MY_POD_NAME} \
  --conf spark.kubernetes.namespace=spark-operator \
  --conf spark.kubernetes.authenticate.driver.serviceAccountName=default \
  --conf spark.kubernetes.driver.pod.name=${MY_POD_NAME} \
  --conf spark.driver.host=${MY_POD_IP} \
  --conf spark.kubernetes.container.image=${container_image} \
  --conf spark.executor.memory=${SPARK_EXECUTOR_MEMORY} \
  --conf spark_kubernetes_executor_request_cores=${SPARK_KUBERNETES_EXECUTOR_REQUEST_CORES} \
  --conf spark_kubernetes_executor_limit_cores=${SPARK_KUBERNETES_EXECUTOR_LIMIT_CORES} \
  --conf spark.dynamicAllocation.enabled=true \
  --conf spark.dynamicAllocation.initialExecutors=3 \
  --conf spark.dynamicAllocation.minExecutors=1 \
  --conf spark.dynamicAllocation.shuffleTracking.enabled=true \
  --conf spark.dynamicAllocation.executorIdleTimeout=60s \
  --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.options.claimName=rss-juicefs-pvc \
  --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.options.sizeLimit=4Gi \
  --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.mount.path=/data \
  --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.mount.readOnly=false \
  -i ${setting_sql_file} \
  -f ${execute_sql_file}
end=$(date +"%s.%9N")
echo timediff:`echo "scale=9;$end - $start" | bc`

