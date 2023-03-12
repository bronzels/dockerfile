#!/bin/bash
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

WORK_HOME=${MYHOME}/workspace
PRJ_HOME=${WORK_HOME}/dockerfile

FLINK_HOME=${PRJ_HOME}/flink

FLINK_VERSION=1.15.3
FLINK_SHORT_VERSION=1.15
FLINKOP_VERSION=1.3.1


cd ${FLINK_HOME}/flink-kubernetes-operator-release-${FLINKOP_VERSION}
cd examples/flink-sql-runner-example

cp sql-example.yaml sql-runner.yaml
file=sql-runner.yaml

$SED -i "s@image: flink-sql-runner-example:latest@image: harbor.my.org:1080/flink/flink-juicefs:${FLINK_VERSION}@g" ${file}
$SED -i "s@  name: sql-example@  name: sql-runner@g" ${file}

kubectl create -n flink -f sql-runner.yaml

kubectl get all -n flink
watch kubectl get all -n flink

cd ${FLINK_HOME}/test

echo "USE hive.tpcds_bin_partitioned_orc_10;SELECT * FROM store_sales LIMIT 5;" > select_store_sales_limit_5.sql
torun=select_store_sales_limit_5.sql
SQL_FILE_HOME=/app/hdfs/hive
HDFS_SQL_FILE_HOME=/tmp

kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- \
  rm -rf ${SQL_FILE_HOME}/${torun}
kubectl cp ${torun} -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'`:${SQL_FILE_HOME}/${torun}
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- \
  hadoop fs -rm -f ${HDFS_SQL_FILE_HOME}/${torun}
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- \
  hadoop fs -put ${torun} ${HDFS_SQL_FILE_HOME}/${torun}
