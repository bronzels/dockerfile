#!/bin/bash
echo -e "query,time" > spark-query.csv
OLD_IFS="$IFS"
IFS=","
arr=($1)
IFS="$OLD_IFS"
#arr=(2 9)
#for num in {1..2}
for num in ${arr[*]}
do
  start=$(date +"%s.%9N")
  spark-submit \
    --class org.apache.spark.sql.hive.my.MySparkSQLCLIDriver \
    --name spark-sql-job-test-manual-10-q${num} \
    --conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss:3.3.1 \
    --conf spark.kubernetes.scheduler.volcano.podGroupTemplateFile=/app/hdfs/spark/work-dir/podgroups/volcano-halfavailable-podgroup.yaml \
    $SPARK_HOME/jars/my-spark-sql-cluster-3.jar \
    -f jfs://miniofs/tmp/spark-tpcds-10/q${num}.sql
  end=$(date +"%s.%9N")
  delta=`echo "scale=9;$end - $start" | bc`
  echo q${num},${delta}
  echo -e "q$num,${delta}" >> spark-query.csv
done
cat spark-query.csv

