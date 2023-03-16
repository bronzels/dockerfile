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

cd ${FLINK_HOME}/test

mkdir testsql
cd testsql
echo "USE hive.tpcds_bin_partitioned_orc_10;SHOW TABLES;" > show_tables.sql
echo "USE hive.tpcds_bin_partitioned_orc_10;SELECT * FROM date_dim LIMIT 5;" > select_date_dim_5.sql
echo "USE hive.tpcds_bin_partitioned_orc_10;SELECT * FROM store_sales LIMIT 5;" > select_store_sales_limit_5.sql
echo "USE hive.tpcds_bin_partitioned_orc_10;SELECT COUNT(1) FROM store_sales;" > select_count_store_sales.sql

mkdir testsql-hivecat
cd testsql-hivecat
arr=(show_tables select_date_dim_5 select_store_sales_limit_5 select_count_store_sales)
for torun in ${arr[*]}
do
  torun=${torun}.sql
  cat ../../setting.sql > ${torun}
  cat ../testsql/${torun} >> ${torun}
  cat ${torun}
done

SQL_FILE_HOME=/app/hdfs/hive
HDFS_SQL_FILE_HOME=/tmp

arr=(show_tables select_date_dim_5 select_store_sales_limit_5 select_count_store_sales)
for torun in ${arr[*]}
do
  torun=${torun}.sql
  kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- \
    rm -f ${SQL_FILE_HOME}/${torun}
  kubectl cp ${torun} -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'`:${SQL_FILE_HOME}/${torun}
  kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- \
    hadoop fs -rm -f ${HDFS_SQL_FILE_HOME}/${torun}
  kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- \
    hadoop fs -put ${torun} ${HDFS_SQL_FILE_HOME}/${torun}
  cd ${FLINK_HOME}/flink-kubernetes-operator-release-${FLINKOP_VERSION}/examples/flink-sql-runner-example/sql-runner.yaml sql-runner.yaml
  $SED -i '' sql-runner.yaml
done

arr=(show_tables)
for torun in ${arr[*]}
do
  torun=${torun}.sql
  cp ${FLINK_HOME}/flink-kubernetes-operator-release-${FLINKOP_VERSION}/examples/flink-sql-runner-example/sql-runner.yaml sql-runner.yaml
  $SED -i "/    args:/d" sql-runner.yaml
  $SED -i "/ jarURI: local:/a\    args: [\"/opt/flink/usrlib/testsql-hivecat/${torun}\"]" sql-runner.yaml
  #$SED -i "/ jarURI: local:/a\    args: [\"local:///opt/flink/usrlib/testsql/${torun}\"]" sql-runner.yaml
  #$SED -i "/ jarURI: local:/a\    args: [\"jfs://miniofs/tmp/${torun}\"]" sql-runner.yaml
  cat sql-runner.yaml
  kubectl create -n flink -f sql-runner.yaml
  kubectl logs -f -n flink `kubectl get pod -n flink | grep sql-runner | awk '{print $1}'`
  kubectl logs -n flink `kubectl get pod -n flink | grep sql-runner | awk '{print $1}'`
  kubectl delete -n flink -f sql-runner.yaml
  kubectl get pod -n flink |grep -v Running |grep sql-runner|awk '{print $1}'| xargs kubectl delete pod "$1" -n flink --force --grace-period=0
done
:<<EOF
1, operator提供的example里执行SQL文件的接口，不能执行SET命令

2, 不再报错找不到core/hive等xml，但是flink官方image的docker-entrypoint.sh似乎根据FlinkDeployment李的job/task配置，cat修改flink-conf.yaml，
但是operator自己生成的job pod里，用configmap方式挂载了conf目录导致flink-conf.yaml不可写，最终导致job配置没有写入flink-conf.yaml。
localhost:test apple$ kubectl logs -f -n flink `kubectl get pod -n flink | grep sql-runner | awk '{print $1}'`
/docker-entrypoint.sh: line 73: /opt/flink/conf/flink-conf.yaml: Permission denied
/docker-entrypoint.sh: line 73: /opt/flink/conf/flink-conf.yaml: Permission denied
/docker-entrypoint.sh: line 73: /opt/flink/conf/flink-conf.yaml: Permission denied
/docker-entrypoint.sh: line 89: /opt/flink/conf/flink-conf.yaml.tmp: Read-only file system
[ERROR] The execution result is empty.
[ERROR] Could not get JVM parameters and dynamic configurations properly.
[ERROR] Raw output from BashJavaUtils:
WARNING: sun.reflect.Reflection.getCallerClass is not supported. This will impact performance.
INFO  [] - Loading configuration property: taskmanager.numberOfTaskSlots, 2
INFO  [] - Loading configuration property: classloader.check-leaked-classloader, false
Exception in thread "main" org.apache.flink.configuration.IllegalConfigurationException: JobManager memory configuration failed: Either required fine-grained memory (jobmanager.memory.heap.size), or Total Flink Memory size (Key: 'jobmanager.memory.flink.size' , default: null (fallback keys: [])), or Total Process Memory size (Key: 'jobmanager.memory.process.size' , default: null (fallback keys: [])) need to be configured explicitly.
	at org.apache.flink.runtime.jobmanager.JobManagerProcessUtils.processSpecFromConfigWithNewOptionToInterpretLegacyHeap(JobManagerProcessUtils.java:78)
	at org.apache.flink.runtime.util.bash.BashJavaUtils.getJmResourceParams(BashJavaUtils.java:98)
	at org.apache.flink.runtime.util.bash.BashJavaUtils.runCommand(BashJavaUtils.java:69)
	at org.apache.flink.runtime.util.bash.BashJavaUtils.main(BashJavaUtils.java:56)
Caused by: org.apache.flink.configuration.IllegalConfigurationException: Either required fine-grained memory (jobmanager.memory.heap.size), or Total Flink Memory size (Key: 'jobmanager.memory.flink.size' , default: null (fallback keys: [])), or Total Process Memory size (Key: 'jobmanager.memory.process.size' , default: null (fallback keys: [])) need to be configured explicitly.
	at org.apache.flink.runtime.util.config.memory.ProcessMemoryUtils.failBecauseRequiredOptionsNotConfigured(ProcessMemoryUtils.java:129)
	at org.apache.flink.runtime.util.config.memory.ProcessMemoryUtils.memoryProcessSpecFromConfig(ProcessMemoryUtils.java:86)
	at org.apache.flink.runtime.jobmanager.JobManagerProcessUtils.processSpecFromConfig(JobManagerProcessUtils.java:83)
	at org.apache.flink.runtime.jobmanager.JobManagerProcessUtils.processSpecFromConfigWithNewOptionToInterpretLegacyHeap(JobManagerProcessUtils.java:73)
	... 3 more
EOF

kubectl get pod -n flink
watch kubectl get pod -n flink

kubectl apply -f flink-test.yaml -n flink
kubectl delete -f flink-test.yaml -n flink
kubectl delete pod flink-test -n flink --force --grace-period=0


ansible all -m shell -a"crictl images|grep spark-juicefs|awk '{print \$3}'|xargs crictl rmi"

kubectl exec -it -n flink `kubectl get pod -n flink | grep flink-test | awk '{print $1}'` -- bash

