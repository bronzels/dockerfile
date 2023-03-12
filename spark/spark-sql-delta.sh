#!/bin/bash

path=$1
echo "DEBUG >>>>>> path:${path}"
prefix=$2
echo "DEBUG >>>>>> prefix:${prefix}"
SED=sed
name=${prefix}`echo ${path}|$SED 's/\\//\-/g'|$SED 's/\./\-/g'|$SED '1,/\-/s/\-//'`
echo "DEBUG >>>>>> name:${name}"
start=$(date +"%s.%9N")
spark-submit \
  --deploy-mode cluster \
  --class org.apache.spark.sql.hive.my.MySparkSQLCLIDriver \
  --name ${name} \
  --conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss:3.3.1 \
  --conf spark.kubernetes.scheduler.volcano.podGroupTemplateFile=/app/hdfs/spark/work-dir/podgroups/volcano-halfavailable-podgroup.yaml \
  --conf spark.executor.memory=4g \
  $SPARK_HOME/jars/my-spark-sql-cluster-3.jar \
  -f jfs://miniofs${path}
end=$(date +"%s.%9N")
delta=`echo "scale=9;$end - $start" | bc`
echo "DEBUG >>>>>> delta:${delta}"
echo -e "${name},${delta}" > ${name}.delta
