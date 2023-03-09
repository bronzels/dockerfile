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

MYSPARK_HOME=/Volumes/data/workspace/dockerfile/spark

:<<EOF
spark query on yarn
q1, timediff:346.991397060
q2, timediff:743.642260938
EOF

watch kube-capacity -u
:<<EOF
#before RSS cluster installed
NODE       CPU REQUESTS   CPU LIMITS     CPU UTIL      MEMORY REQUESTS   MEMORY LIMITS   MEMORY UTIL
*          6750m (24%)    10000m (35%)   575m (2%)   20408Mi (15%)     50516Mi (39%)   9726Mi (7%)
NODE       CPU REQUESTS   CPU LIMITS     CPU UTIL    MEMORY REQUESTS   MEMORY LIMITS   MEMORY UTIL
*          6750m (24%)    10000m (35%)   638m (2%)   20408Mi (15%)     50516Mi (39%)   7179Mi (5%)
#after RSS cluster installed
NODE       CPU REQUESTS   CPU LIMITS     CPU UTIL    MEMORY REQUESTS   MEMORY LIMITS   MEMORY UTIL
*          8250m (29%)    12500m (44%)   557m (1%)   21944Mi (17%)     56660Mi (44%)   12793Mi (10%)
EOF

kubectl port-forward spark-test -n spark-operator 4040:4040 &

kubectl port-forward svc/`kubectl get svc -n spark-operator |grep spark-sql-job-test-manual |awk '{print $1}'` -n spark-operator 4040:4040 &

#删除已完成的driver pod
kubectl get pod -n spark-operator |grep spark-sql-job-test-manual |grep driver |grep Completed |awk '{print $1}'| xargs kubectl delete pod "$1" -n spark-operator
kubectl get pod -n spark-operator |grep spark-sql-job |grep driver |grep -v "Running\|Pending" |awk '{print $1}'| xargs kubectl delete pod "$1" -n spark-operator


kubectl apply -f spark-test.yaml -n spark-operator
kubectl delete -f spark-test.yaml -n spark-operator
kubectl delete pod spark-test -n spark-operator --force --grace-period=0


ansible all -m shell -a"crictl images|grep spark-juicefs|awk '{print \$3}'|xargs crictl rmi"

kubectl logs -n spark-operator spark-sql-job-test-manual-10-q1-7cb9b28676975020-driver


kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- bash
  echo "use tpcds_bin_partitioned_orc_10" > dbuse.sql
  rm -rf /tmp/spark-tpcds-10
  hadoop fs -rm -r -f /tmp/spark-tpcds-10
  mkdir /tmp/spark-tpcds-10
  hadoop fs -mkdir /tmp/spark-tpcds-10
  for num in {1..99}
  do
    file=/tmp/spark-tpcds-10/q${num}.sql
    cat dbuse.sql > ${file}
    echo -e ";" >> ${file}
    cat hive-testbench/spark-queries-tpcds/q${num}.sql >> ${file}
    echo -e ";" >> ${file}
    #cat ${file}
    if [[ "$num" == "30" ]]; then
      sed -i 's/c_last_review_date_sk/c_last_review_date/g' ${file}
    fi
    hadoop fs -put ${file} ${file}
    #hadoop fs -cat /tmp/spark-tpcds-10/q${num}.sql
    echo "q${num} done"
  done
  hadoop fs -mkdir /tmp/k8sup
kubectl cp -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'`:/tmp/spark-tpcds-10 spark-tpcds-10


kubectl exec -it spark-test -n spark-operator -- /bin/bash

:<<EOF
test case
  fixed resource
EOF
  echo -e "query,time" > spark-query.csv
  for num in {1..2}
  do
    start=$(date +"%s.%9N")
    spark-sql \
      --master \
      k8s://https://kubernetes.default.svc.cluster.local:443 \
      --deploy-mode client \
      --name spark-sql-job-test-manual \
      --conf spark.kubernetes.namespace=spark-operator \
      --conf spark.kubernetes.authenticate.driver.serviceAccountName=default \
      --conf spark.kubernetes.driver.pod.name=`hostname` \
      --conf spark.driver.host=`hostname -i` \
      --conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs:3.3.1 \
      --conf spark.executor.instances=3 \
      --conf spark.executor.memory=4g \
      --conf spark.kubernetes.executor.request.cores=1 \
      --conf spark.kubernetes.executor.limit.cores=2 \
      -i dbuse.sql \
      -f spark-queries-tpcds/q${num}.sql
  #   -f /app/hdfs/spark/work-dir/test.sql
    end=$(date +"%s.%9N")
    delta=`echo "scale=9;$end - $start" | bc`
    echo q${num},${delta}
    echo -e "q$num,${delta}" >> spark-query.csv
  done
  cat spark-query.csv
:<<EOF
q1,24.706304598
q2,141.147401197
EOF


:<<EOF
test case
  dynamic allocation with shuffletracking
  executor.memory fixed 4G
EOF
  echo -e "query,time" > spark-query.csv
  for num in {1..2}
  do
    start=$(date +"%s.%9N")
    spark-sql \
      --master \
      k8s://https://kubernetes.default.svc.cluster.local:443 \
      --deploy-mode client \
      --name spark-sql-job-test-manual \
      --conf spark.kubernetes.namespace=spark-operator \
      --conf spark.kubernetes.authenticate.driver.serviceAccountName=default \
      --conf spark.kubernetes.driver.pod.name=`hostname` \
      --conf spark.driver.host=`hostname -i` \
      --conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs:3.3.1 \
      --conf spark.executor.memory=4g \
      --conf spark.dynamicAllocation.enabled=true \
      --conf spark.dynamicAllocation.shuffleTracking.enabled=true \
      --conf spark.dynamicAllocation.executorIdleTimeout=60s \
      --conf spark.dynamicAllocation.initialExecutors=3 \
      --conf spark.dynamicAllocation.minExecutors=1 \
      -i dbuse.sql \
      -f spark-queries-tpcds/q${num}.sql
  #   -f /app/hdfs/spark/work-dir/test.sql
    end=$(date +"%s.%9N")
    delta=`echo "scale=9;$end - $start" | bc`
    echo q${num},${delta}
    echo -e "q$num,${delta}" >> spark-query.csv
  done
  cat spark-query.csv
:<<EOF
q1,39.041577403
q2,106.537121287
q2,108.007699354
EOF


:<<EOF
test case
  dynamic allocation with shuffletracking
  executor.memory not fixed 4G
EOF
  echo -e "query,time" > spark-query.csv
  for num in {1..2}
  do
    start=$(date +"%s.%9N")
    spark-sql \
      --master \
      k8s://https://kubernetes.default.svc.cluster.local:443 \
      --deploy-mode client \
      --name spark-sql-job-test-manual \
      --conf spark.kubernetes.namespace=spark-operator \
      --conf spark.kubernetes.authenticate.driver.serviceAccountName=default \
      --conf spark.kubernetes.driver.pod.name=`hostname` \
      --conf spark.driver.host=`hostname -i` \
      --conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs:3.3.1 \
      --conf spark.dynamicAllocation.enabled=true \
      --conf spark.dynamicAllocation.shuffleTracking.enabled=true \
      --conf spark.dynamicAllocation.executorIdleTimeout=60s \
      --conf spark.dynamicAllocation.initialExecutors=3 \
      --conf spark.dynamicAllocation.minExecutors=1 \
      -i dbuse.sql \
      -f spark-queries-tpcds/q${num}.sql
  #   -f /app/hdfs/spark/work-dir/test.sql
    end=$(date +"%s.%9N")
    delta=`echo "scale=9;$end - $start" | bc`
    echo q${num},${delta}
    echo -e "q$num,${delta}" >> spark-query.csv
  done
  cat spark-query.csv
:<<EOF
q1,43.705806274
q2,108.482030476
q1,43.660220807
q2,108.960869015
EOF


:<<EOF
test case
  dynamic allocation with shuffletracking
  executor.memory fixed 4G
  request/limit cores 500m/1000m
EOF
  echo -e "query,time" > spark-query.csv
  for num in {1..2}
  do
    start=$(date +"%s.%9N")
    spark-sql \
      --master \
      k8s://https://kubernetes.default.svc.cluster.local:443 \
      --deploy-mode client \
      --name spark-sql-job-test-manual \
      --conf spark.kubernetes.namespace=spark-operator \
      --conf spark.kubernetes.authenticate.driver.serviceAccountName=default \
      --conf spark.kubernetes.driver.pod.name=`hostname` \
      --conf spark.driver.host=`hostname -i` \
      --conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs:3.3.1 \
      --conf spark.executor.memory=4g \
      --conf spark.kubernetes.executor.request.cores=500m \
      --conf spark.kubernetes.executor.limit.cores=1000m \
      --conf spark.dynamicAllocation.enabled=true \
      --conf spark.dynamicAllocation.shuffleTracking.enabled=true \
      --conf spark.dynamicAllocation.executorIdleTimeout=60s \
      --conf spark.dynamicAllocation.initialExecutors=3 \
      --conf spark.dynamicAllocation.minExecutors=1 \
      -i dbuse.sql \
      -f spark-queries-tpcds/q${num}.sql
    end=$(date +"%s.%9N")
    delta=`echo "scale=9;$end - $start" | bc`
    echo q${num},${delta}
    echo -e "q$num,${delta}" >> spark-query.csv
  done
  cat spark-query.csv
:<<EOF
q1,45.571436048
q2,116.019012626
q1,46.420251943
q2,117.879876710
EOF


:<<EOF
test case
  dynamic allocation with shuffletracking
  executor.memory fixed 4G
  request/limit cores 250m/500m
EOF
  echo -e "query,time" > spark-query.csv
  for num in {1..2}
  do
    start=$(date +"%s.%9N")
    spark-sql \
      --master \
      k8s://https://kubernetes.default.svc.cluster.local:443 \
      --deploy-mode client \
      --name spark-sql-job-test-manual \
      --conf spark.kubernetes.namespace=spark-operator \
      --conf spark.kubernetes.authenticate.driver.serviceAccountName=default \
      --conf spark.kubernetes.driver.pod.name=`hostname` \
      --conf spark.driver.host=`hostname -i` \
      --conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs:3.3.1 \
      --conf spark.executor.memory=4g \
      --conf spark.dynamicAllocation.enabled=true \
      --conf spark.dynamicAllocation.shuffleTracking.enabled=true \
      --conf spark.dynamicAllocation.executorIdleTimeout=60s \
      --conf spark.kubernetes.executor.request.cores=250m \
      --conf spark.kubernetes.executor.limit.cores=500m \
      --conf spark.dynamicAllocation.initialExecutors=3 \
      --conf spark.dynamicAllocation.minExecutors=1 \
      -i dbuse.sql \
      -f spark-queries-tpcds/q${num}.sql
    end=$(date +"%s.%9N")
    delta=`echo "scale=9;$end - $start" | bc`
    echo q${num},${delta}
    echo -e "q$num,${delta}" >> spark-query.csv
  done
  cat spark-query.csv
:<<EOF
q1,104.648819718
q2,158.504421685
EOF


:<<EOF
test case
  dynamic allocation with shuffletracking
  executor.memory fixed 4G
  localdir set to ssd faster than default emptydir
EOF
ansible all -m shell -a"rm -rf /sparklocal;mkdir /sparklocal"
  echo -e "query,time" > spark-query.csv
  for num in {1..2}
  do
    start=$(date +"%s.%9N")
    spark-sql \
      --master \
      k8s://https://kubernetes.default.svc.cluster.local:443 \
      --deploy-mode client \
      --name spark-sql-job-test-manual \
      --conf spark.kubernetes.namespace=spark-operator \
      --conf spark.kubernetes.authenticate.driver.serviceAccountName=default \
      --conf spark.kubernetes.driver.pod.name=`hostname` \
      --conf spark.driver.host=`hostname -i` \
      --conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs:3.3.1 \
      --conf spark.executor.memory=4g \
      --conf spark.dynamicAllocation.enabled=true \
      --conf spark.dynamicAllocation.shuffleTracking.enabled=true \
      --conf spark.dynamicAllocation.executorIdleTimeout=60s \
      --conf spark.dynamicAllocation.initialExecutors=3 \
      --conf spark.dynamicAllocation.minExecutors=1 \
      --conf spark.kubernetes.executor.volumes.hostPath.spark-local-dir-1.mount.path='/tmp/spark' \
      --conf spark.kubernetes.executor.volumes.hostPath.spark-local-dir-1.options.path=/sparklocal \
      --conf spark.local.dir='/tmp/spark' \
      -i dbuse.sql \
      -f spark-queries-tpcds/q${num}.sql
  #   -f /app/hdfs/spark/work-dir/test.sql
    end=$(date +"%s.%9N")
    delta=`echo "scale=9;$end - $start" | bc`
    echo q${num},${delta}
    echo -e "q$num,${delta}" >> spark-query.csv
  done
  cat spark-query.csv
:<<EOF
创建上千个container，只有1个在运行，手工停止
EOF


:<<EOF
test case
  dynamic allocation with shuffletracking
  executor.memory fixed 4G
  localdir set to OnDemand nfs PVC
EOF
kubectl apply -f rss-nfs-pvc.yaml -n spark-operator
#kubectl delete -f rss-nfs-pvc.yaml -n spark-operator
  echo -e "query,time" > spark-query.csv
  for num in {1..2}
  do
    start=$(date +"%s.%9N")
    spark-sql \
      --master \
      k8s://https://kubernetes.default.svc.cluster.local:443 \
      --deploy-mode client \
      --name spark-sql-job-test-manual \
      --conf spark.kubernetes.namespace=spark-operator \
      --conf spark.kubernetes.authenticate.driver.serviceAccountName=default \
      --conf spark.kubernetes.driver.pod.name=`hostname` \
      --conf spark.driver.host=`hostname -i` \
      --conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs:3.3.1 \
      --conf spark.executor.memory=4g \
      --conf spark.dynamicAllocation.enabled=true \
      --conf spark.dynamicAllocation.shuffleTracking.enabled=true \
      --conf spark.dynamicAllocation.executorIdleTimeout=60s \
      --conf spark.dynamicAllocation.initialExecutors=3 \
      --conf spark.dynamicAllocation.minExecutors=1 \
      --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.options.claimName=OnDemand \
      --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.options.storageClass=nfs-client \
      --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.options.sizeLimit=4Gi \
      --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.mount.path=/data \
      --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.mount.readOnly=false \
      -i dbuse.sql \
      -f spark-queries-tpcds/q${num}.sql
  #   -f /app/hdfs/spark/work-dir/test.sql
    end=$(date +"%s.%9N")
    delta=`echo "scale=9;$end - $start" | bc`
    echo q${num},${delta}
    echo -e "q$num,${delta}" >> spark-query.csv
  done
  cat spark-query.csv
:<<EOF
创建多少个executor pod就会创建多少个pvc，会在nfs里有大量archived pvc文件夹
rm -rf /Volumes/data/nfs/archived-spark-operator-spark-sql-job-test-manual-*
不能增加，会提示不能创建文件
      --conf spark.local.dir=/data \
q1,40.443544108
q2,114.907334498
EOF


:<<EOF
test case
  dynamic allocation with shuffletracking
  executor.memory fixed 4G
  localdir set to OnDemand juicefs PVC
EOF
kubectl apply -f rss-juicefs-pvc.yaml -n spark-operator
:<<EOF
kubectl delete -f rss-juicefs-pvc.yaml -n spark-operator
EOF
  echo -e "query,time" > spark-query.csv
  for num in {1..2}
  do
    start=$(date +"%s.%9N")
    spark-sql \
      --master \
      k8s://https://kubernetes.default.svc.cluster.local:443 \
      --deploy-mode client \
      --name spark-sql-job-test-manual \
      --conf spark.kubernetes.namespace=spark-operator \
      --conf spark.kubernetes.authenticate.driver.serviceAccountName=default \
      --conf spark.kubernetes.driver.pod.name=`hostname` \
      --conf spark.driver.host=`hostname -i` \
      --conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs:3.3.1 \
      --conf spark.executor.memory=4g \
      --conf spark.dynamicAllocation.enabled=true \
      --conf spark.dynamicAllocation.shuffleTracking.enabled=true \
      --conf spark.dynamicAllocation.executorIdleTimeout=60s \
      --conf spark.dynamicAllocation.initialExecutors=3 \
      --conf spark.dynamicAllocation.minExecutors=1 \
      --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.options.claimName=OnDemand \
      --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.options.storageClass=juicefs-sc \
      --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.options.sizeLimit=4Gi \
      --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.mount.path=/data \
      --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.mount.readOnly=false \
      -i dbuse.sql \
      -f spark-queries-tpcds/q${num}.sql
  #   -f /app/hdfs/spark/work-dir/test.sql
    end=$(date +"%s.%9N")
    delta=`echo "scale=9;$end - $start" | bc`
    echo q${num},${delta}
    echo -e "q$num,${delta}" >> spark-query.csv
  done
  cat spark-query.csv
:<<EOF
创建多少个executor pod就会创建多少个pvc，juicefs的pvc被删除时，文件也会被删除，不需要mount手工删除
不能增加，会提示不能创建文件
      --conf spark.local.dir=/data \
q1,179.812621891
q2,307.627771375
有错误提示
23/01/12 12:18:02 ERROR TaskSchedulerImpl: Lost executor 12 on 100.110.242.89:
The executor with id 12 exited with exit code -1(unexpected).
The API gave the following brief reason: Preempting
The API gave the following message: Preempted in order to admit critical pod

The API gave the following container statuses:



23/01/12 12:18:02 WARN TaskSetManager: Lost task 9.0 in stage 5.0 (TID 2042) (100.110.242.89 executor 12): ExecutorLostFailure (executor 12 exited caused by one of the running tasks) Reason:
The executor with id 12 exited with exit code -1(unexpected).
The API gave the following brief reason: Preempting
The API gave the following message: Preempted in order to admit critical pod

The API gave the following container statuses:



23/01/12 12:18:19 WARN TaskSetManager: Lost task 0.0 in stage 7.0 (TID 2047) (100.110.242.82 executor 29): FetchFailed(null, shuffleId=0, mapIndex=-1, mapId=-1, reduceId=0, message=
org.apache.spark.shuffle.MetadataFetchFailedException: Missing an output location for shuffle 0 partition 0
	at org.apache.spark.MapOutputTracker$.validateStatus(MapOutputTracker.scala:1705)
	at org.apache.spark.MapOutputTracker$.$anonfun$convertMapStatuses$10(MapOutputTracker.scala:1652)
	at org.apache.spark.MapOutputTracker$.$anonfun$convertMapStatuses$10$adapted(MapOutputTracker.scala:1651)
	at scala.collection.Iterator.foreach(Iterator.scala:943)
	at scala.collection.Iterator.foreach$(Iterator.scala:943)
	at scala.collection.AbstractIterator.foreach(Iterator.scala:1431)
	at org.apache.spark.MapOutputTracker$.convertMapStatuses(MapOutputTracker.scala:1651)
	at org.apache.spark.MapOutputTrackerWorker.getMapSizesByExecutorIdImpl(MapOutputTracker.scala:1294)
	at org.apache.spark.MapOutputTrackerWorker.getMapSizesByExecutorId(MapOutputTracker.scala:1256)
	at org.apache.spark.shuffle.sort.SortShuffleManager.getReader(SortShuffleManager.scala:140)
	at org.apache.spark.shuffle.ShuffleManager.getReader(ShuffleManager.scala:63)
	at org.apache.spark.shuffle.ShuffleManager.getReader$(ShuffleManager.scala:57)
	at org.apache.spark.shuffle.sort.SortShuffleManager.getReader(SortShuffleManager.scala:73)
	at org.apache.spark.sql.execution.ShuffledRowRDD.compute(ShuffledRowRDD.scala:208)
	at org.apache.spark.rdd.RDD.computeOrReadCheckpoint(RDD.scala:365)
	at org.apache.spark.rdd.RDD.iterator(RDD.scala:329)
	at org.apache.spark.rdd.MapPartitionsRDD.compute(MapPartitionsRDD.scala:52)
	at org.apache.spark.rdd.RDD.computeOrReadCheckpoint(RDD.scala:365)
	at org.apache.spark.rdd.RDD.iterator(RDD.scala:329)
	at org.apache.spark.rdd.MapPartitionsRDD.compute(MapPartitionsRDD.scala:52)
	at org.apache.spark.rdd.RDD.computeOrReadCheckpoint(RDD.scala:365)
	at org.apache.spark.rdd.RDD.iterator(RDD.scala:329)
	at org.apache.spark.shuffle.ShuffleWriteProcessor.write(ShuffleWriteProcessor.scala:59)
	at org.apache.spark.scheduler.ShuffleMapTask.runTask(ShuffleMapTask.scala:99)
	at org.apache.spark.scheduler.ShuffleMapTask.runTask(ShuffleMapTask.scala:52)
	at org.apache.spark.scheduler.Task.run(Task.scala:136)
	at org.apache.spark.executor.Executor$TaskRunner.$anonfun$run$3(Executor.scala:548)
	at org.apache.spark.util.Utils$.tryWithSafeFinally(Utils.scala:1504)
	at org.apache.spark.executor.Executor$TaskRunner.run(Executor.scala:551)
	at java.base/java.util.concurrent.ThreadPoolExecutor.runWorker(Unknown Source)
	at java.base/java.util.concurrent.ThreadPoolExecutor$Worker.run(Unknown Source)
	at java.base/java.lang.Thread.run(Unknown Source)

)
23/01/12 12:18:19 WARN TaskSetManager: Lost task 1.0 in stage 7.0 (TID 2048) (100.110.242.82 executor 29): FetchFailed(null, shuffleId=0, mapIndex=-1, mapId=-1, reduceId=28, message=
org.apache.spark.shuffle.MetadataFetchFailedException: Missing an output location for shuffle 0 partition 28
	at org.apache.spark.MapOutputTracker$.validateStatus(MapOutputTracker.scala:1705)
	at org.apache.spark.MapOutputTracker$.$anonfun$convertMapStatuses$10(MapOutputTracker.scala:1652)
	at org.apache.spark.MapOutputTracker$.$anonfun$convertMapStatuses$10$adapted(MapOutputTracker.scala:1651)
	at scala.collection.Iterator.foreach(Iterator.scala:943)
	at scala.collection.Iterator.foreach$(Iterator.scala:943)
	at scala.collection.AbstractIterator.foreach(Iterator.scala:1431)
	at org.apache.spark.MapOutputTracker$.convertMapStatuses(MapOutputTracker.scala:1651)
	at org.apache.spark.MapOutputTrackerWorker.getMapSizesByExecutorIdImpl(MapOutputTracker.scala:1294)
	at org.apache.spark.MapOutputTrackerWorker.getMapSizesByExecutorId(MapOutputTracker.scala:1256)
	at org.apache.spark.shuffle.sort.SortShuffleManager.getReader(SortShuffleManager.scala:140)
	at org.apache.spark.shuffle.ShuffleManager.getReader(ShuffleManager.scala:63)
	at org.apache.spark.shuffle.ShuffleManager.getReader$(ShuffleManager.scala:57)
	at org.apache.spark.shuffle.sort.SortShuffleManager.getReader(SortShuffleManager.scala:73)
	at org.apache.spark.sql.execution.ShuffledRowRDD.compute(ShuffledRowRDD.scala:208)
	at org.apache.spark.rdd.RDD.computeOrReadCheckpoint(RDD.scala:365)
	at org.apache.spark.rdd.RDD.iterator(RDD.scala:329)
	at org.apache.spark.rdd.MapPartitionsRDD.compute(MapPartitionsRDD.scala:52)
	at org.apache.spark.rdd.RDD.computeOrReadCheckpoint(RDD.scala:365)
	at org.apache.spark.rdd.RDD.iterator(RDD.scala:329)
	at org.apache.spark.rdd.MapPartitionsRDD.compute(MapPartitionsRDD.scala:52)
	at org.apache.spark.rdd.RDD.computeOrReadCheckpoint(RDD.scala:365)
	at org.apache.spark.rdd.RDD.iterator(RDD.scala:329)
	at org.apache.spark.shuffle.ShuffleWriteProcessor.write(ShuffleWriteProcessor.scala:59)
	at org.apache.spark.scheduler.ShuffleMapTask.runTask(ShuffleMapTask.scala:99)
	at org.apache.spark.scheduler.ShuffleMapTask.runTask(ShuffleMapTask.scala:52)
	at org.apache.spark.scheduler.Task.run(Task.scala:136)
	at org.apache.spark.executor.Executor$TaskRunner.$anonfun$run$3(Executor.scala:548)
	at org.apache.spark.util.Utils$.tryWithSafeFinally(Utils.scala:1504)
	at org.apache.spark.executor.Executor$TaskRunner.run(Executor.scala:551)
	at java.base/java.util.concurrent.ThreadPoolExecutor.runWorker(Unknown Source)
	at java.base/java.util.concurrent.ThreadPoolExecutor$Worker.run(Unknown Source)
	at java.base/java.lang.Thread.run(Unknown Source)

)
EOF


:<<EOF
test case
  dynamic allocation with shuffletracking
  executor.memory fixed 4G
  localdir set to tmps
EOF
  echo -e "query,time" > spark-query.csv
  for num in {1..2}
  do
    start=$(date +"%s.%9N")
    spark-sql \
      --master \
      k8s://https://kubernetes.default.svc.cluster.local:443 \
      --deploy-mode client \
      --name spark-sql-job-test-manual \
      --conf spark.kubernetes.namespace=spark-operator \
      --conf spark.kubernetes.authenticate.driver.serviceAccountName=default \
      --conf spark.kubernetes.driver.pod.name=`hostname` \
      --conf spark.driver.host=`hostname -i` \
      --conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs:3.3.1 \
      --conf spark.executor.memory=4g \
      --conf spark.dynamicAllocation.enabled=true \
      --conf spark.dynamicAllocation.shuffleTracking.enabled=true \
      --conf spark.dynamicAllocation.executorIdleTimeout=60s \
      --conf spark.dynamicAllocation.initialExecutors=3 \
      --conf spark.dynamicAllocation.minExecutors=1 \
      --conf spark.kubernetes.local.dirs.tmpfs=true \
      -i dbuse.sql \
      -f spark-queries-tpcds/q${num}.sql
  #   -f /app/hdfs/spark/work-dir/test.sql
    end=$(date +"%s.%9N")
    delta=`echo "scale=9;$end - $start" | bc`
    echo q${num},${delta}
    echo -e "q$num,${delta}" >> spark-query.csv
  done
  cat spark-query.csv
:<<EOF
q1,51.730795565
q2,116.075530680
23/01/13 02:52:15 ERROR Utils: Uncaught exception in thread dispatcher-CoarseGrainedScheduler
org.apache.spark.SparkException: Could not find CoarseGrainedScheduler.
	at org.apache.spark.rpc.netty.Dispatcher.postMessage(Dispatcher.scala:178)
	at org.apache.spark.rpc.netty.Dispatcher.postOneWayMessage(Dispatcher.scala:150)
	at org.apache.spark.rpc.netty.NettyRpcEnv.send(NettyRpcEnv.scala:193)
	at org.apache.spark.rpc.netty.NettyRpcEndpointRef.send(NettyRpcEnv.scala:563)
	at org.apache.spark.scheduler.cluster.CoarseGrainedSchedulerBackend.$anonfun$reviveOffers$1(CoarseGrainedSchedulerBackend.scala:630)
	at org.apache.spark.util.Utils$.tryLogNonFatalError(Utils.scala:1484)
	at org.apache.spark.scheduler.cluster.CoarseGrainedSchedulerBackend.reviveOffers(CoarseGrainedSchedulerBackend.scala:630)
	at org.apache.spark.scheduler.TaskSchedulerImpl.executorLost(TaskSchedulerImpl.scala:1004)
	at org.apache.spark.scheduler.cluster.CoarseGrainedSchedulerBackend$DriverEndpoint.disableExecutor(CoarseGrainedSchedulerBackend.scala:482)
	at org.apache.spark.scheduler.cluster.k8s.KubernetesClusterSchedulerBackend$KubernetesDriverEndpoint.$anonfun$onDisconnected$1(KubernetesClusterSchedulerBackend.scala:328)
	at org.apache.spark.scheduler.cluster.k8s.KubernetesClusterSchedulerBackend$KubernetesDriverEndpoint.$anonfun$onDisconnected$1$adapted(KubernetesClusterSchedulerBackend.scala:328)
	at scala.Option.foreach(Option.scala:407)
	at org.apache.spark.scheduler.cluster.k8s.KubernetesClusterSchedulerBackend$KubernetesDriverEndpoint.onDisconnected(KubernetesClusterSchedulerBackend.scala:328)
	at org.apache.spark.rpc.netty.Inbox.$anonfun$process$1(Inbox.scala:141)
	at org.apache.spark.rpc.netty.Inbox.safelyCall(Inbox.scala:213)
	at org.apache.spark.rpc.netty.Inbox.process(Inbox.scala:100)
	at org.apache.spark.rpc.netty.MessageLoop.org$apache$spark$rpc$netty$MessageLoop$$receiveLoop(MessageLoop.scala:75)
	at org.apache.spark.rpc.netty.MessageLoop$$anon$1.run(MessageLoop.scala:41)
	at java.base/java.util.concurrent.Executors$RunnableAdapter.call(Unknown Source)
	at java.base/java.util.concurrent.FutureTask.run(Unknown Source)
	at java.base/java.util.concurrent.ThreadPoolExecutor.runWorker(Unknown Source)
	at java.base/java.util.concurrent.ThreadPoolExecutor$Worker.run(Unknown Source)
	at java.base/java.lang.Thread.run(Unknown Source)
EOF


:<<EOF
test case
  dynamic allocation with shuffletracking
  executor.memory fixed lower to 2G
  localdir set to tmps
EOF
  echo -e "query,time" > spark-query.csv
  for num in {1..2}
  do
    start=$(date +"%s.%9N")
    spark-sql \
      --master \
      k8s://https://kubernetes.default.svc.cluster.local:443 \
      --deploy-mode client \
      --name spark-sql-job-test-manual \
      --conf spark.kubernetes.namespace=spark-operator \
      --conf spark.kubernetes.authenticate.driver.serviceAccountName=default \
      --conf spark.kubernetes.driver.pod.name=`hostname` \
      --conf spark.driver.host=`hostname -i` \
      --conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs:3.3.1 \
      --conf spark.executor.memory=2g \
      --conf spark.kubernetes.executor.limit.cores=2000m \
      --conf spark.dynamicAllocation.enabled=true \
      --conf spark.dynamicAllocation.shuffleTracking.enabled=true \
      --conf spark.dynamicAllocation.executorIdleTimeout=60s \
      --conf spark.kubernetes.local.dirs.tmpfs=true \
      --conf spark.dynamicAllocation.initialExecutors=3 \
      --conf spark.dynamicAllocation.minExecutors=1 \
      -i dbuse.sql \
      -f spark-queries-tpcds/q${num}.sql
  #   -f /app/hdfs/spark/work-dir/test.sql
    end=$(date +"%s.%9N")
    delta=`echo "scale=9;$end - $start" | bc`
    echo q${num},${delta}
    echo -e "q$num,${delta}" >> spark-query.csv
  done
  cat spark-query.csv
:<<EOF
q1,41.975624268
q2,108.801407158
EOF


:<<EOF
test case
  dynamic allocation with shuffletracking
  executor.memory fixed lower to 2G
EOF
#test case: dynamic allocation with shuffletracking, executor.memory fixed lower to 2G
  echo -e "query,time" > spark-query.csv
  for num in {1..2}
  do
    start=$(date +"%s.%9N")
    spark-sql \
      --master \
      k8s://https://kubernetes.default.svc.cluster.local:443 \
      --deploy-mode client \
      --name spark-sql-job-test-manual \
      --conf spark.kubernetes.namespace=spark-operator \
      --conf spark.kubernetes.authenticate.driver.serviceAccountName=default \
      --conf spark.kubernetes.driver.pod.name=`hostname` \
      --conf spark.driver.host=`hostname -i` \
      --conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs:3.3.1 \
      --conf spark.executor.memory=2g \
      --conf spark.dynamicAllocation.enabled=true \
      --conf spark.dynamicAllocation.shuffleTracking.enabled=true \
      --conf spark.dynamicAllocation.executorIdleTimeout=60s \
      --conf spark.dynamicAllocation.initialExecutors=3 \
      --conf spark.dynamicAllocation.minExecutors=1 \
      -i dbuse.sql \
      -f spark-queries-tpcds/q${num}.sql
  #   -f /app/hdfs/spark/work-dir/test.sql
    end=$(date +"%s.%9N")
    delta=`echo "scale=9;$end - $start" | bc`
    echo q${num},${delta}
    echo -e "q$num,${delta}" >> spark-query.csv
  done
  cat spark-query.csv
:<<EOF
q1,46.444110381
q2,111.827838235
EOF


:<<EOF
test case
  dynamic allocation with shuffletracking
  executor.memory fixed 4G
  scheduler set to volcano
EOF
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- bash
  echo -e "query,time" > spark-query.csv
  for num in {1..2}
  do
    start=$(date +"%s.%9N")
    spark-submit \
      --class org.apache.spark.sql.hive.my.MySparkSQLCLIDriver \
      --master \
      k8s://https://kubernetes.default.svc.cluster.local:443 \
      --deploy-mode cluster \
      --conf spark.submit.deployMode=cluster \
      --name spark-sql-job-test-manual \
      --conf spark.kubernetes.namespace=spark-operator \
      --conf spark.kubernetes.authenticate.driver.serviceAccountName=default \
      --conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs:3.3.1 \
      --conf spark.executor.memory=4g \
      --conf spark.dynamicAllocation.enabled=true \
      --conf spark.dynamicAllocation.shuffleTracking.enabled=true \
      --conf spark.dynamicAllocation.executorIdleTimeout=60s \
      --conf spark.dynamicAllocation.initialExecutors=3 \
      --conf spark.dynamicAllocation.minExecutors=1 \
      --conf spark.kubernetes.file.upload.path=jfs://miniofs/tmp/k8sup \
      --conf spark.kubernetes.scheduler.name=volcano \
      --conf spark.kubernetes.scheduler.volcano.podGroupTemplateFile=/app/hdfs/spark/work-dir/volcano-default-podgroup.yaml \
      --conf spark.kubernetes.driver.pod.featureSteps=org.apache.spark.deploy.k8s.features.VolcanoFeatureStep \
      --conf spark.kubernetes.executor.pod.featureSteps=org.apache.spark.deploy.k8s.features.VolcanoFeatureStep \
      $SPARK_HOME/jars/my-spark-sql-cluster-3.jar \
      -f jfs://miniofs/tmp/spark-tpcds-10/q${num}.sql
    end=$(date +"%s.%9N")
    delta=`echo "scale=9;$end - $start" | bc`
    echo q${num},${delta}
    echo -e "q$num,${delta}" >> spark-query.csv
  done
  cat spark-query.csv
:<<EOF
1, spark需要重新编译支持-Dvolcano，不然报错：
java.lang.ClassNotFoundException: org.apache.spark.deploy.k8s.features.VolcanoFeatureStep

2，还不支持client模式，有个ticket在解决：https://github.com/volcano-sh/volcano/pull/2358
23/01/19 07:17:21 WARN ExecutorPodsSnapshotsStoreImpl: Exception when notifying snapshot subscriber.
io.fabric8.kubernetes.client.KubernetesClientException: Failure executing: POST at: https://kubernetes.default.svc.cluster.local/api/v1/namespaces/spark-operator/pods. Message: admission webhook "validatepod.volcano.sh" denied the request: failed to get PodGroup for pod <spark-operator/spark-sql-job-test-manual-4f878885c8e3a550-exec-1>: podgroups.scheduling.volcano.sh "spark-c4e1f89a7cf8451da3013d464e56258b-podgroup" not found. Received status: Status(apiVersion=v1, code=400, details=null, kind=Status, message=admission webhook "validatepod.volcano.sh" denied the request: failed to get PodGroup for pod <spark-operator/spark-sql-job-test-manual-4f878885c8e3a550-exec-1>: podgroups.scheduling.volcano.sh "spark-c4e1f89a7cf8451da3013d464e56258b-podgroup" not found, metadata=ListMeta(_continue=null, remainingItemCount=null, resourceVersion=null, selfLink=null, additionalProperties={}), reason=null, status=Failure, additionalProperties={}).

q1,56.218652501
q2,120.528430892
EOF


:<<EOF
test case
  dynamic allocation with shuffletracking
  executor.memory fixed 4G
  remove resource conf redudant to volcano podgroup
EOF
  echo -e "query,time" > spark-query.csv
  for num in {1..2}
  do
    start=$(date +"%s.%9N")
    spark-submit \
      --class org.apache.spark.sql.hive.my.MySparkSQLCLIDriver \
      --master \
      k8s://https://kubernetes.default.svc.cluster.local:443 \
      --deploy-mode cluster \
      --conf spark.submit.deployMode=cluster \
      --name spark-sql-job-test-manual \
      --conf spark.kubernetes.namespace=spark-operator \
      --conf spark.kubernetes.authenticate.driver.serviceAccountName=default \
      --conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs:3.3.1 \
      --conf spark.dynamicAllocation.enabled=true \
      --conf spark.dynamicAllocation.shuffleTracking.enabled=true \
      --conf spark.dynamicAllocation.executorIdleTimeout=60s \
      --conf spark.kubernetes.file.upload.path=jfs://miniofs/tmp/k8sup \
      --conf spark.kubernetes.scheduler.name=volcano \
      --conf spark.kubernetes.scheduler.volcano.podGroupTemplateFile=/app/hdfs/spark/work-dir/podgroups/volcano-default-podgroup.yaml \
      --conf spark.kubernetes.driver.pod.featureSteps=org.apache.spark.deploy.k8s.features.VolcanoFeatureStep \
      --conf spark.kubernetes.executor.pod.featureSteps=org.apache.spark.deploy.k8s.features.VolcanoFeatureStep \
      $SPARK_HOME/jars/my-spark-sql-cluster-3.jar \
      -f jfs://miniofs/tmp/spark-tpcds-10/q${num}.sql
    end=$(date +"%s.%9N")
    delta=`echo "scale=9;$end - $start" | bc`
    echo q${num},${delta}
    echo -e "q$num,${delta}" >> spark-query.csv
  done
  cat spark-query.csv
:<<EOF
q1,56.218652501
q2,120.528430892
EOF


:<<EOF
test case
  dynamic allocation with shuffletracking
  scheduler set to volcano
  assigned to a queue with min resource by spark conf
EOF
  echo -e "query,time" > spark-query.csv
  for num in {1..2}
  do
    start=$(date +"%s.%9N")
    spark-submit \
      --class org.apache.spark.sql.hive.my.MySparkSQLCLIDriver \
      --master \
      k8s://https://kubernetes.default.svc.cluster.local:443 \
      --deploy-mode cluster \
      --conf spark.submit.deployMode=cluster \
      --name spark-sql-job-test-manual \
      --conf spark.kubernetes.namespace=spark-operator \
      --conf spark.kubernetes.authenticate.driver.serviceAccountName=default \
      --conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs:3.3.1 \
      --conf spark.dynamicAllocation.enabled=true \
      --conf spark.dynamicAllocation.shuffleTracking.enabled=true \
      --conf spark.dynamicAllocation.executorIdleTimeout=60s \
      --conf spark.kubernetes.file.upload.path=jfs://miniofs/tmp/k8sup \
      --conf spark.kubernetes.scheduler.name=volcano \
      --conf spark.kubernetes.scheduler.volcano.podgroup.queue=min \
      --conf spark.kubernetes.driver.pod.featureSteps=org.apache.spark.deploy.k8s.features.VolcanoFeatureStep \
      --conf spark.kubernetes.executor.pod.featureSteps=org.apache.spark.deploy.k8s.features.VolcanoFeatureStep \
      $SPARK_HOME/jars/my-spark-sql-cluster-3.jar \
      -f jfs://miniofs/tmp/spark-tpcds-10/q${num}.sql
    end=$(date +"%s.%9N")
    delta=`echo "scale=9;$end - $start" | bc`
    echo q${num},${delta}
    echo -e "q$num,${delta}" >> spark-query.csv
  done
  cat spark-query.csv
:<<EOF
还是有很多pending的任务，总任务数有到50（1）/100（2）
watch kube-capacity -u观察，CPU UTIL接近60%，MEMORY UTIL接近20%
不支持conf方式使用：https://github.com/apache/spark/pull/37802
q1,50.725082567
q2,116.245581167
EOF


:<<EOF
test case
  dynamic allocation with shuffletracking
  scheduler set to volcano
  assigned to a queue with all/half available resource by podgroup file
EOF
:<<EOF
  queue=allavailable
  queue=halfavailable
  queue=few
EOF
  echo -e "query,time" > spark-query.csv
  for num in {1..2}
  do
    start=$(date +"%s.%9N")
    spark-submit \
      --class org.apache.spark.sql.hive.my.MySparkSQLCLIDriver \
      --master \
      k8s://https://kubernetes.default.svc.cluster.local:443 \
      --deploy-mode cluster \
      --conf spark.submit.deployMode=cluster \
      --name spark-sql-job-test-manual \
      --conf spark.kubernetes.namespace=spark-operator \
      --conf spark.kubernetes.authenticate.driver.serviceAccountName=default \
      --conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs:3.3.1 \
      --conf spark.dynamicAllocation.enabled=true \
      --conf spark.dynamicAllocation.shuffleTracking.enabled=true \
      --conf spark.dynamicAllocation.executorIdleTimeout=60s \
      --conf spark.kubernetes.file.upload.path=jfs://miniofs/tmp/k8sup \
      --conf spark.kubernetes.scheduler.name=volcano \
      --conf spark.kubernetes.scheduler.volcano.podGroupTemplateFile=/app/hdfs/spark/work-dir/podgroups/volcano-${queue}-podgroup.yaml \
      --conf spark.kubernetes.driver.pod.featureSteps=org.apache.spark.deploy.k8s.features.VolcanoFeatureStep \
      --conf spark.kubernetes.executor.pod.featureSteps=org.apache.spark.deploy.k8s.features.VolcanoFeatureStep \
      $SPARK_HOME/jars/my-spark-sql-cluster-3.jar \
      -f jfs://miniofs/tmp/spark-tpcds-10/q${num}.sql
    end=$(date +"%s.%9N")
    delta=`echo "scale=9;$end - $start" | bc`
    echo q${num},${delta}
    echo -e "q$num,${delta}" >> spark-query.csv
  done
  cat spark-query.csv
:<<EOF
还是有很多pending的任务，总任务数有到50（1）/100（2）
allavailable
watch kubectl get queue all-available -o yaml观察，峰值
   cpu: "19"
   memory: 26752Mi
q1,49.395365928
q2,117.591562565
halfavailable
watch kubectl get queue half-available -o yaml观察，峰值
    cpu: "14"
    memory: 19712Mi
q1,42.146292450
q2,108.161868076
few
watch kubectl get queue few -o yaml观察，峰值
    cpu: "4"
    memory: 5632Mi
q1,31.356548507
q2,143.300491476
EOF


:<<EOF
test case
  dynamic allocation with shuffletracking
  scheduler set to volcano
  assigned to a queue with resource by podgroup file
  1 has lower priority than 2, start in almost same time in 2 term
EOF
  echo -e "query,time" > spark-query.csv
  for num in {1..2}
  :<<EOF
  num=1
  num=2
  queue=halfavailable
  queue=few
  queue=fewer
  EOF
  echo "num:${num}"
  echo "queue:${queue}"
  #分别exec在2个term进入同一个测试pod，执行同一段代码
  #开始
  if [[ "${num}" =~ "1" ]]; then
    priority=low
  else
    priority=high
  fi
  echo "priority:${priority}"
  start=$(date +"%s.%9N")
  spark-submit \
    --class org.apache.spark.sql.hive.my.MySparkSQLCLIDriver \
    --master \
    k8s://https://kubernetes.default.svc.cluster.local:443 \
    --deploy-mode cluster \
    --conf spark.submit.deployMode=cluster \
    --name spark-sql-job-test-manual-10-q${num} \
    --conf spark.kubernetes.namespace=spark-operator \
    --conf spark.kubernetes.authenticate.driver.serviceAccountName=default \
    --conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs:3.3.1 \
    --conf spark.dynamicAllocation.enabled=true \
    --conf spark.dynamicAllocation.shuffleTracking.enabled=true \
    --conf spark.dynamicAllocation.executorIdleTimeout=60s \
    --conf spark.kubernetes.file.upload.path=jfs://miniofs/tmp/k8sup \
    --conf spark.kubernetes.scheduler.name=volcano \
    --conf spark.kubernetes.scheduler.volcano.podGroupTemplateFile=/app/hdfs/spark/work-dir/podgroups/volcano-${queue}-podgroup-${priority}.yaml \
    --conf spark.kubernetes.driver.pod.featureSteps=org.apache.spark.deploy.k8s.features.VolcanoFeatureStep \
    --conf spark.kubernetes.executor.pod.featureSteps=org.apache.spark.deploy.k8s.features.VolcanoFeatureStep \
    $SPARK_HOME/jars/my-spark-sql-cluster-3.jar \
    -f jfs://miniofs/tmp/spark-tpcds-10/q${num}.sql
  end=$(date +"%s.%9N")
  delta=`echo "scale=9;$end - $start" | bc`
  echo q${num},${delta}
  echo -e "q$num,${delta}" >> spark-query.csv
  #结束
  cat spark-query.csv
:<<EOF
high 1000000000，low 0，先执行q2，有running的driver/executor以后，再执行q1，q1 pending无法执行
halfavailable，high 1000000000，low 0，q1/q2同时开始执行，q2先paste
q2,107.479897960
q1,145.464241198
few，high 1000000000，low 0，q1/q2同时开始执行，q1先paste
q1,33.752888970
q2,156.579792613
halfavailable，high 1000000000，low 0，q1/q2同时开始执行
q1,46.193245619
q2,141.829041291
few，high 1000000000，low -1000000000，q1/q2同时开始执行
q1,34.767383415
q2,154.887262673
fewer，high 1000000000，low -1000000000
q2完成以前，q1的driver pending无法创建，q2执行时间太长，delete q2的driver pod以后，q1开始执行
EOF


:<<EOF
test case
  dynamic allocation with shuffletracking
  scheduler set to volcano
  assigned to a queue with half available resource by podgroup file
  tune SAE/parallelism  options to reduce pending executors
EOF
  echo -e "query,time" > spark-query.csv
  for num in {1..2}
  do
    start=$(date +"%s.%9N")
    spark-submit \
      --class org.apache.spark.sql.hive.my.MySparkSQLCLIDriver \
      --master \
      k8s://https://kubernetes.default.svc.cluster.local:443 \
      --deploy-mode cluster \
      --conf spark.submit.deployMode=cluster \
      --name spark-sql-job-test-manual \
      --conf spark.kubernetes.namespace=spark-operator \
      --conf spark.kubernetes.authenticate.driver.serviceAccountName=default \
      --conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs:3.3.1 \
      --conf spark.sql.adaptive.enabled=true \
      --conf spark.sql.adaptive.shuffle.targetPostShuffleRowCount=10000 \
      --conf spark.dynamicAllocation.enabled=true \
      --conf spark.dynamicAllocation.shuffleTracking.enabled=true \
      --conf spark.sql.adaptive.join.enabled=true \
      --conf spark.sql.adaptive.skewedJoin.enabled=true \
      --conf spark.dynamicAllocation.executorIdleTimeout=60s \
      --conf spark.kubernetes.file.upload.path=jfs://miniofs/tmp/k8sup \
      --conf spark.kubernetes.scheduler.name=volcano \
      --conf spark.kubernetes.scheduler.volcano.podGroupTemplateFile=/app/hdfs/spark/work-dir/podgroups/volcano-halfavailable-podgroup.yaml \
      --conf spark.kubernetes.driver.pod.featureSteps=org.apache.spark.deploy.k8s.features.VolcanoFeatureStep \
      --conf spark.kubernetes.executor.pod.featureSteps=org.apache.spark.deploy.k8s.features.VolcanoFeatureStep \
      $SPARK_HOME/jars/my-spark-sql-cluster-3.jar \
      -f jfs://miniofs/tmp/spark-tpcds-10/q${num}.sql
    end=$(date +"%s.%9N")
    delta=`echo "scale=9;$end - $start" | bc`
    echo q${num},${delta}
    echo -e "q$num,${delta}" >> spark-query.csv
  done
  cat spark-query.csv
:<<EOF
1，所有SAE优化都没有减少pending executor数量
只有SAE enabled：
q1,44.764018888
q2,109.829161516
加上reduce shuffle设置
q1,39.702155049
q2,105.948528737
加上join和倾斜优化：
q1,37.804338660
q2,109.461007286
2，spark.default.parallelism不能减少pending executor数量
      --conf spark.default.parallelism=12 \
EOF


:<<EOF
test case
  dynamic allocation with shuffletracking
  scheduler set to volcano
  assigned to a queue with half available resource by podgroup file
  tune DA options to reduce pending executors
EOF
  echo -e "query,time" > spark-query.csv
  arr=(9)
  #for num in {1..2}
  for num in ${arr[*]}
  do
    start=$(date +"%s.%9N")
    spark-submit \
      --class org.apache.spark.sql.hive.my.MySparkSQLCLIDriver \
      --master \
      k8s://https://kubernetes.default.svc.cluster.local:443 \
      --deploy-mode cluster \
      --conf spark.submit.deployMode=cluster \
      --name spark-sql-job-test-manual-10-q${num} \
      --conf spark.kubernetes.namespace=spark-operator \
      --conf spark.kubernetes.authenticate.driver.serviceAccountName=default \
      --conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs:3.3.1 \
      --conf spark.dynamicAllocation.enabled=true \
      --conf spark.dynamicAllocation.shuffleTracking.enabled=true \
      --conf spark.dynamicAllocation.executorIdleTimeout=60s \
      --conf spark.dynamicAllocation.executorAllocationRatio=0.01 \
      --conf spark.kubernetes.file.upload.path=jfs://miniofs/tmp/k8sup \
      --conf spark.kubernetes.scheduler.name=volcano \
      --conf spark.kubernetes.scheduler.volcano.podGroupTemplateFile=/app/hdfs/spark/work-dir/podgroups/volcano-halfavailable-podgroup.yaml \
      --conf spark.kubernetes.driver.pod.featureSteps=org.apache.spark.deploy.k8s.features.VolcanoFeatureStep \
      --conf spark.kubernetes.executor.pod.featureSteps=org.apache.spark.deploy.k8s.features.VolcanoFeatureStep \
      $SPARK_HOME/jars/my-spark-sql-cluster-3.jar \
      -f jfs://miniofs/tmp/spark-tpcds-10/q${num}.sql
    end=$(date +"%s.%9N")
    delta=`echo "scale=9;$end - $start" | bc`
    echo q${num},${delta}
    echo -e "q$num,${delta}" >> spark-query.csv
  done
  cat spark-query.csv
:<<EOF
1，q1/q2, spark.dynamicAllocation.executorIdleTimeout，不能减少pending executor数量，应该是指running但是没有task执行的executor
      --conf spark.dynamicAllocation.executorIdleTimeout=15s \
q1,38.647023919
q2,107.183633694
2，q1/q2, spark.dynamicAllocation.executorAllocationRatio，峰值还是到40以上，70s以后q2会逐渐减少pending executor数量到全部都是running，q1运行时间短可能来不及
      --conf spark.dynamicAllocation.executorAllocationRatio=0.1 \
q1,38.348198092
q2,106.968077066
3，q9，总executor数目到300多
q9,638.805645036
3，q9, spark.dynamicAllocation.executorAllocationRatio，峰值大概40以上，70s以后会逐渐减少pending executor数量到全部都是running
      --conf spark.dynamicAllocation.executorAllocationRatio=0.01 \
q9,680.760188459
EOF


:<<EOF
test case
  dynamic allocation with shuffletracking
  scheduler set to volcano
  assigned to a queue with half available resource by podgroup file
  use maxpending to reduce pending executors
EOF
  echo -e "query,time" > spark-query.csv
  arr=(2 9)
  #for num in {1..2}
  for num in ${arr[*]}
  do
    start=$(date +"%s.%9N")
    spark-submit \
      --class org.apache.spark.sql.hive.my.MySparkSQLCLIDriver \
      --master \
      k8s://https://kubernetes.default.svc.cluster.local:443 \
      --deploy-mode cluster \
      --conf spark.submit.deployMode=cluster \
      --name spark-sql-job-test-manual-10-q${num} \
      --conf spark.kubernetes.namespace=spark-operator \
      --conf spark.kubernetes.authenticate.driver.serviceAccountName=default \
      --conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs:3.3.1 \
      --conf spark.kubernetes.allocation.maxPendingPods=10 \
      --conf spark.dynamicAllocation.enabled=true \
      --conf spark.dynamicAllocation.shuffleTracking.enabled=true \
      --conf spark.dynamicAllocation.executorIdleTimeout=60s \
      --conf spark.kubernetes.file.upload.path=jfs://miniofs/tmp/k8sup \
      --conf spark.kubernetes.scheduler.name=volcano \
      --conf spark.kubernetes.scheduler.volcano.podGroupTemplateFile=/app/hdfs/spark/work-dir/podgroups/volcano-halfavailable-podgroup.yaml \
      --conf spark.kubernetes.driver.pod.featureSteps=org.apache.spark.deploy.k8s.features.VolcanoFeatureStep \
      --conf spark.kubernetes.executor.pod.featureSteps=org.apache.spark.deploy.k8s.features.VolcanoFeatureStep \
      $SPARK_HOME/jars/my-spark-sql-cluster-3.jar \
      -f jfs://miniofs/tmp/spark-tpcds-10/q${num}.sql
    end=$(date +"%s.%9N")
    delta=`echo "scale=9;$end - $start" | bc`
    echo q${num},${delta}
    echo -e "q$num,${delta}" >> spark-query.csv
  done
  cat spark-query.csv
:<<EOF
pending数目一直控制在10个，q9性能有明显下降
q2,107.749156279
q9,725.406285522
EOF


:<<EOF
test case
  dynamic allocation with shuffletracking
  scheduler set to volcano
  assigned to a queue with half available resource by podgroup file
  use maxpending to reduce pending executors
  move common --conf from CLI to spark-defaults.conf
  RSS cluster installed but disabled as base line
EOF
  echo -e "query,time" > spark-query.csv
  arr=(2 9)
  #for num in {1..2}
  for num in ${arr[*]}
  do
    start=$(date +"%s.%9N")
    spark-submit \
      --class org.apache.spark.sql.hive.my.MySparkSQLCLIDriver \
      --name spark-sql-job-test-manual-10-q${num} \
      --conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss-tpc:3.3.1 \
      --conf spark.kubernetes.scheduler.volcano.podGroupTemplateFile=/app/hdfs/spark/work-dir/podgroups/volcano-halfavailable-podgroup.yaml \
      $SPARK_HOME/jars/my-spark-sql-cluster-3.jar \
      -f jfs://miniofs/tmp/spark-tpcds-10/q${num}.sql
    end=$(date +"%s.%9N")
    delta=`echo "scale=9;$end - $start" | bc`
    echo q${num},${delta}
    echo -e "q$num,${delta}" >> spark-query.csv
  done
  cat spark-query.csv
:<<EOF
q2,147.285537566
q9,778.070888849
EOF


:<<EOF
test case
  dynamic allocation with shuffletracking
  scheduler set to volcano
  assigned to a queue with half available resource by podgroup file
  use maxpending to reduce pending executors
  move common --conf from CLI to spark-defaults.conf
  RSS cluster enabled
EOF
  echo -e "query,time" > spark-query.csv
  arr=(2 9)
  #for num in {1..2}
  for num in ${arr[*]}
  do
    start=$(date +"%s.%9N")
    spark-submit \
      --class org.apache.spark.sql.hive.my.MySparkSQLCLIDriver \
      --name spark-sql-job-test-manual-10-q${num} \
      --conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss-tpc:3.3.1 \
      --conf spark.kubernetes.scheduler.volcano.podGroupTemplateFile=/app/hdfs/spark/work-dir/podgroups/volcano-halfavailable-podgroup.yaml \
      $SPARK_HOME/jars/my-spark-sql-cluster-3.jar \
      -f jfs://miniofs/tmp/spark-tpcds-10/q${num}.sql
    end=$(date +"%s.%9N")
    delta=`echo "scale=9;$end - $start" | bc`
    echo q${num},${delta}
    echo -e "q$num,${delta}" >> spark-query.csv
  done
  cat spark-query.csv
:<<EOF
1，RSS的2个master提示没有leader，剩余的1个master和2个worker没有明显错误提示
2，出现很多OOM executor，最后driver失败
localhost:harbor apple$ kubectl logs spark-sql-job-test-manual-10-q9-6603be85ec8b484f-driver -n spark-operator
++ id -u
+ myuid=1000
++ id -g
+ mygid=0
+ set +e
++ getent passwd 1000
+ uidentry=hdfs:x:1000:0::/app/hdfs:/bin/sh
+ set -e
+ '[' -z hdfs:x:1000:0::/app/hdfs:/bin/sh ']'
+ '[' -z /opt/java/openjdk ']'
+ SPARK_CLASSPATH=':/app/hdfs/spark/jars/*'
+ env
+ grep SPARK_JAVA_OPT_
+ sort -t_ -k4 -n
+ sed 's/[^=]*=\(.*\)/\1/g'
+ readarray -t SPARK_EXECUTOR_JAVA_OPTS
+ '[' -n '' ']'
+ '[' -z ']'
+ '[' -z ']'
+ '[' -n '' ']'
+ '[' -z ']'
+ '[' -z x ']'
+ SPARK_CLASSPATH='/opt/spark/conf::/app/hdfs/spark/jars/*'
+ case "$1" in
+ shift 1
+ CMD=("$SPARK_HOME/bin/spark-submit" --conf "spark.driver.bindAddress=$SPARK_DRIVER_BIND_ADDRESS" --deploy-mode client "$@")
+ exec /usr/bin/tini -s -- /app/hdfs/spark/bin/spark-submit --conf spark.driver.bindAddress=100.110.242.107 --deploy-mode client --properties-file /opt/spark/conf/spark.properties --class org.apache.spark.sql.hive.my.MySparkSQLCLIDriver spark-internal -f jfs://miniofs/tmp/spark-tpcds-10/q9.sql
23/01/26 05:28:15 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
Setting default log level to "WARN".
To adjust logging level use sc.setLogLevel(newLevel). For SparkR, use setLogLevel(newLevel).
Spark master: k8s://https://kubernetes.default.svc.cluster.local:443, Application Id: spark-c68a2df6a52e450588d61ab5154b1c38
Time taken: 0.873 seconds
23/01/26 05:37:07 ERROR TaskSchedulerImpl: Lost executor 13 on 100.86.155.194:
The executor with id 13 exited with exit code 137(SIGKILL, possible container OOM).



The API gave the following container statuses:


	 container name: spark-kubernetes-executor
	 container image: harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss-tpc:3.3.1
	 container state: terminated
	 container started at: 2023-01-26T05:28:32Z
	 container finished at: 2023-01-26T05:37:06Z
	 exit code: 137
	 termination reason: OOMKilled

23/01/26 05:37:07 WARN TaskSetManager: Lost task 25.0 in stage 8.0 (TID 9337) (100.86.155.194 executor 13): ExecutorLostFailure (executor 13 exited caused by one of the running tasks) Reason:
The executor with id 13 exited with exit code 137(SIGKILL, possible container OOM).



The API gave the following container statuses:


	 container name: spark-kubernetes-executor
	 container image: harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss-tpc:3.3.1
	 container state: terminated
	 container started at: 2023-01-26T05:28:32Z
	 container finished at: 2023-01-26T05:37:06Z
	 exit code: 137
	 termination reason: OOMKilled

23/01/26 05:37:32 ERROR TaskSchedulerImpl: Lost executor 12 on 100.86.155.219:
The executor with id 12 exited with exit code 137(SIGKILL, possible container OOM).



The API gave the following container statuses:


	 container name: spark-kubernetes-executor
	 container image: harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss-tpc:3.3.1
	 container state: terminated
	 container started at: 2023-01-26T05:28:31Z
	 container finished at: 2023-01-26T05:37:32Z
	 exit code: 137
	 termination reason: OOMKilled

23/01/26 05:37:32 WARN TaskSetManager: Lost task 0.0 in stage 9.0 (TID 9376) (100.86.155.219 executor 12): ExecutorLostFailure (executor 12 exited caused by one of the running tasks) Reason:
The executor with id 12 exited with exit code 137(SIGKILL, possible container OOM).



The API gave the following container statuses:


	 container name: spark-kubernetes-executor
	 container image: harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss-tpc:3.3.1
	 container state: terminated
	 container started at: 2023-01-26T05:28:31Z
	 container finished at: 2023-01-26T05:37:32Z
	 exit code: 137
	 termination reason: OOMKilled

23/01/26 05:37:36 ERROR TaskSchedulerImpl: Lost executor 9 on 100.95.202.155:
The executor with id 9 exited with exit code 137(SIGKILL, possible container OOM).



The API gave the following container statuses:


	 container name: spark-kubernetes-executor
	 container image: harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss-tpc:3.3.1
	 container state: terminated
	 container started at: 2023-01-26T05:28:32Z
	 container finished at: 2023-01-26T05:37:35Z
	 exit code: 137
	 termination reason: OOMKilled

23/01/26 05:37:36 WARN TaskSetManager: Lost task 0.1 in stage 9.0 (TID 9393) (100.95.202.155 executor 9): ExecutorLostFailure (executor 9 exited caused by one of the running tasks) Reason:
The executor with id 9 exited with exit code 137(SIGKILL, possible container OOM).



The API gave the following container statuses:


	 container name: spark-kubernetes-executor
	 container image: harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss-tpc:3.3.1
	 container state: terminated
	 container started at: 2023-01-26T05:28:32Z
	 container finished at: 2023-01-26T05:37:35Z
	 exit code: 137
	 termination reason: OOMKilled

23/01/26 05:38:12 ERROR TaskSchedulerImpl: Lost executor 5 on 100.110.242.97:
The executor with id 5 exited with exit code 137(SIGKILL, possible container OOM).



The API gave the following container statuses:


	 container name: spark-kubernetes-executor
	 container image: harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss-tpc:3.3.1
	 container state: terminated
	 container started at: 2023-01-26T05:28:26Z
	 container finished at: 2023-01-26T05:38:12Z
	 exit code: 137
	 termination reason: OOMKilled

23/01/26 05:38:12 WARN TaskSetManager: Lost task 20.0 in stage 9.0 (TID 9399) (100.110.242.97 executor 5): ExecutorLostFailure (executor 5 exited caused by one of the running tasks) Reason:
The executor with id 5 exited with exit code 137(SIGKILL, possible container OOM).



The API gave the following container statuses:


	 container name: spark-kubernetes-executor
	 container image: harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss-tpc:3.3.1
	 container state: terminated
	 container started at: 2023-01-26T05:28:26Z
	 container finished at: 2023-01-26T05:38:12Z
	 exit code: 137
	 termination reason: OOMKilled

23/01/26 05:38:19 ERROR TaskSchedulerImpl: Lost executor 4 on 100.86.155.243:
The executor with id 4 exited with exit code 137(SIGKILL, possible container OOM).



The API gave the following container statuses:


	 container name: spark-kubernetes-executor
	 container image: harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss-tpc:3.3.1
	 container state: terminated
	 container started at: 2023-01-26T05:28:30Z
	 container finished at: 2023-01-26T05:38:19Z
	 exit code: 137
	 termination reason: OOMKilled

23/01/26 05:38:19 WARN TaskSetManager: Lost task 0.2 in stage 9.0 (TID 9395) (100.86.155.243 executor 4): ExecutorLostFailure (executor 4 exited caused by one of the running tasks) Reason:
The executor with id 4 exited with exit code 137(SIGKILL, possible container OOM).



The API gave the following container statuses:


	 container name: spark-kubernetes-executor
	 container image: harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss-tpc:3.3.1
	 container state: terminated
	 container started at: 2023-01-26T05:28:30Z
	 container finished at: 2023-01-26T05:38:19Z
	 exit code: 137
	 termination reason: OOMKilled

23/01/26 05:38:23 ERROR TaskSchedulerImpl: Lost executor 1 on 100.110.242.65:
The executor with id 1 exited with exit code 137(SIGKILL, possible container OOM).



The API gave the following container statuses:


	 container name: spark-kubernetes-executor
	 container image: harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss-tpc:3.3.1
	 container state: terminated
	 container started at: 2023-01-26T05:28:22Z
	 container finished at: 2023-01-26T05:38:22Z
	 exit code: 137
	 termination reason: OOMKilled

23/01/26 05:38:23 WARN TaskSetManager: Lost task 0.3 in stage 9.0 (TID 9411) (100.110.242.65 executor 1): ExecutorLostFailure (executor 1 exited caused by one of the running tasks) Reason:
The executor with id 1 exited with exit code 137(SIGKILL, possible container OOM).



The API gave the following container statuses:


	 container name: spark-kubernetes-executor
	 container image: harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss-tpc:3.3.1
	 container state: terminated
	 container started at: 2023-01-26T05:28:22Z
	 container finished at: 2023-01-26T05:38:22Z
	 exit code: 137
	 termination reason: OOMKilled

23/01/26 05:38:23 ERROR TaskSetManager: Task 0 in stage 9.0 failed 4 times; aborting job
org.apache.spark.SparkException: Exception thrown in awaitResult:
	at org.apache.spark.util.ThreadUtils$.awaitResult(ThreadUtils.scala:318)
	at org.apache.spark.sql.execution.SubqueryExec.executeCollect(basicPhysicalOperators.scala:861)
	at org.apache.spark.sql.execution.ScalarSubquery.updateResult(subquery.scala:80)
	at org.apache.spark.sql.execution.SparkPlan.$anonfun$waitForSubqueries$1(SparkPlan.scala:262)
	at org.apache.spark.sql.execution.SparkPlan.$anonfun$waitForSubqueries$1$adapted(SparkPlan.scala:261)
	at scala.collection.mutable.ResizableArray.foreach(ResizableArray.scala:62)
	at scala.collection.mutable.ResizableArray.foreach$(ResizableArray.scala:55)
	at scala.collection.mutable.ArrayBuffer.foreach(ArrayBuffer.scala:49)
	at org.apache.spark.sql.execution.SparkPlan.waitForSubqueries(SparkPlan.scala:261)
	at org.apache.spark.sql.execution.SparkPlan.$anonfun$executeQuery$1(SparkPlan.scala:231)
	at org.apache.spark.rdd.RDDOperationScope$.withScope(RDDOperationScope.scala:151)
	at org.apache.spark.sql.execution.SparkPlan.executeQuery(SparkPlan.scala:229)
	at org.apache.spark.sql.execution.CodegenSupport.produce(WholeStageCodegenExec.scala:92)
	at org.apache.spark.sql.execution.CodegenSupport.produce$(WholeStageCodegenExec.scala:92)
	at org.apache.spark.sql.execution.ProjectExec.produce(basicPhysicalOperators.scala:42)
	at org.apache.spark.sql.execution.WholeStageCodegenExec.doCodeGen(WholeStageCodegenExec.scala:660)
	at org.apache.spark.sql.execution.WholeStageCodegenExec.doExecute(WholeStageCodegenExec.scala:723)
	at org.apache.spark.sql.execution.SparkPlan.$anonfun$execute$1(SparkPlan.scala:194)
	at org.apache.spark.sql.execution.SparkPlan.$anonfun$executeQuery$1(SparkPlan.scala:232)
	at org.apache.spark.rdd.RDDOperationScope$.withScope(RDDOperationScope.scala:151)
	at org.apache.spark.sql.execution.SparkPlan.executeQuery(SparkPlan.scala:229)
	at org.apache.spark.sql.execution.SparkPlan.execute(SparkPlan.scala:190)
	at org.apache.spark.sql.execution.SparkPlan.getByteArrayRdd(SparkPlan.scala:340)
	at org.apache.spark.sql.execution.SparkPlan.executeCollect(SparkPlan.scala:421)
	at org.apache.spark.sql.execution.adaptive.AdaptiveSparkPlanExec.$anonfun$executeCollect$1(AdaptiveSparkPlanExec.scala:345)
	at org.apache.spark.sql.execution.adaptive.AdaptiveSparkPlanExec.withFinalPlanUpdate(AdaptiveSparkPlanExec.scala:373)
	at org.apache.spark.sql.execution.adaptive.AdaptiveSparkPlanExec.executeCollect(AdaptiveSparkPlanExec.scala:345)
	at org.apache.spark.sql.execution.SparkPlan.executeCollectPublic(SparkPlan.scala:451)
	at org.apache.spark.sql.execution.HiveResult$.hiveResultString(HiveResult.scala:76)
	at org.apache.spark.sql.hive.thriftserver.SparkSQLDriver.$anonfun$run$2(SparkSQLDriver.scala:69)
	at org.apache.spark.sql.execution.SQLExecution$.$anonfun$withNewExecutionId$6(SQLExecution.scala:109)
	at org.apache.spark.sql.execution.SQLExecution$.withSQLConfPropagated(SQLExecution.scala:169)
	at org.apache.spark.sql.execution.SQLExecution$.$anonfun$withNewExecutionId$1(SQLExecution.scala:95)
	at org.apache.spark.sql.SparkSession.withActive(SparkSession.scala:779)
	at org.apache.spark.sql.execution.SQLExecution$.withNewExecutionId(SQLExecution.scala:64)
	at org.apache.spark.sql.hive.thriftserver.SparkSQLDriver.run(SparkSQLDriver.scala:69)
	at org.apache.spark.sql.hive.thriftserver.SparkSQLCLIDriver.processCmd(SparkSQLCLIDriver.scala:384)
	at org.apache.spark.sql.hive.thriftserver.SparkSQLCLIDriver.$anonfun$processLine$1(SparkSQLCLIDriver.scala:504)
	at org.apache.spark.sql.hive.thriftserver.SparkSQLCLIDriver.$anonfun$processLine$1$adapted(SparkSQLCLIDriver.scala:498)
	at scala.collection.Iterator.foreach(Iterator.scala:943)
	at scala.collection.Iterator.foreach$(Iterator.scala:943)
	at scala.collection.AbstractIterator.foreach(Iterator.scala:1431)
	at scala.collection.IterableLike.foreach(IterableLike.scala:74)
	at scala.collection.IterableLike.foreach$(IterableLike.scala:73)
	at scala.collection.AbstractIterable.foreach(Iterable.scala:56)
	at org.apache.spark.sql.hive.thriftserver.SparkSQLCLIDriver.processLine(SparkSQLCLIDriver.scala:498)
	at org.apache.hadoop.hive.cli.CliDriver.processLine(CliDriver.java:336)
	at org.apache.hadoop.hive.cli.CliDriver.processReader(CliDriver.java:474)
	at org.apache.hadoop.hive.cli.CliDriver.processFile(CliDriver.java:490)
	at org.apache.spark.sql.hive.my.MySparkSQLCLIDriver$.main(MySparkSQLCLIDriver.scala:188)
	at org.apache.spark.sql.hive.my.MySparkSQLCLIDriver.main(MySparkSQLCLIDriver.scala)
	at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke(Unknown Source)
	at java.base/jdk.internal.reflect.DelegatingMethodAccessorImpl.invoke(Unknown Source)
	at java.base/java.lang.reflect.Method.invoke(Unknown Source)
	at org.apache.spark.deploy.JavaMainApplication.start(SparkApplication.scala:52)
	at org.apache.spark.deploy.SparkSubmit.org$apache$spark$deploy$SparkSubmit$$runMain(SparkSubmit.scala:958)
	at org.apache.spark.deploy.SparkSubmit.doRunMain$1(SparkSubmit.scala:180)
	at org.apache.spark.deploy.SparkSubmit.submit(SparkSubmit.scala:203)
	at org.apache.spark.deploy.SparkSubmit.doSubmit(SparkSubmit.scala:90)
	at org.apache.spark.deploy.SparkSubmit$$anon$2.doSubmit(SparkSubmit.scala:1046)
	at org.apache.spark.deploy.SparkSubmit$.main(SparkSubmit.scala:1055)
	at org.apache.spark.deploy.SparkSubmit.main(SparkSubmit.scala)
Caused by: java.util.concurrent.ExecutionException: org.apache.spark.SparkException: Job aborted due to stage failure: Task 0 in stage 9.0 failed 4 times, most recent failure: Lost task 0.3 in stage 9.0 (TID 9411) (100.110.242.65 executor 1): ExecutorLostFailure (executor 1 exited caused by one of the running tasks) Reason:
The executor with id 1 exited with exit code 137(SIGKILL, possible container OOM).



The API gave the following container statuses:


	 container name: spark-kubernetes-executor
	 container image: harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss-tpc:3.3.1
	 container state: terminated
	 container started at: 2023-01-26T05:28:22Z
	 container finished at: 2023-01-26T05:38:22Z
	 exit code: 137
	 termination reason: OOMKilled

Driver stacktrace:
	at java.base/java.util.concurrent.FutureTask.report(Unknown Source)
	at java.base/java.util.concurrent.FutureTask.get(Unknown Source)
	at org.apache.spark.util.ThreadUtils$.awaitResult(ThreadUtils.scala:310)
	... 62 more
Caused by: org.apache.spark.SparkException: Job aborted due to stage failure: Task 0 in stage 9.0 failed 4 times, most recent failure: Lost task 0.3 in stage 9.0 (TID 9411) (100.110.242.65 executor 1): ExecutorLostFailure (executor 1 exited caused by one of the running tasks) Reason:
The executor with id 1 exited with exit code 137(SIGKILL, possible container OOM).



The API gave the following container statuses:


	 container name: spark-kubernetes-executor
	 container image: harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss-tpc:3.3.1
	 container state: terminated
	 container started at: 2023-01-26T05:28:22Z
	 container finished at: 2023-01-26T05:38:22Z
	 exit code: 137
	 termination reason: OOMKilled

Driver stacktrace:
	at org.apache.spark.scheduler.DAGScheduler.failJobAndIndependentStages(DAGScheduler.scala:2674)
	at org.apache.spark.scheduler.DAGScheduler.$anonfun$abortStage$2(DAGScheduler.scala:2610)
	at org.apache.spark.scheduler.DAGScheduler.$anonfun$abortStage$2$adapted(DAGScheduler.scala:2609)
	at scala.collection.mutable.ResizableArray.foreach(ResizableArray.scala:62)
	at scala.collection.mutable.ResizableArray.foreach$(ResizableArray.scala:55)
	at scala.collection.mutable.ArrayBuffer.foreach(ArrayBuffer.scala:49)
	at org.apache.spark.scheduler.DAGScheduler.abortStage(DAGScheduler.scala:2609)
	at org.apache.spark.scheduler.DAGScheduler.$anonfun$handleTaskSetFailed$1(DAGScheduler.scala:1182)
	at org.apache.spark.scheduler.DAGScheduler.$anonfun$handleTaskSetFailed$1$adapted(DAGScheduler.scala:1182)
	at scala.Option.foreach(Option.scala:407)
	at org.apache.spark.scheduler.DAGScheduler.handleTaskSetFailed(DAGScheduler.scala:1182)
	at org.apache.spark.scheduler.DAGSchedulerEventProcessLoop.doOnReceive(DAGScheduler.scala:2862)
	at org.apache.spark.scheduler.DAGSchedulerEventProcessLoop.onReceive(DAGScheduler.scala:2804)
	at org.apache.spark.scheduler.DAGSchedulerEventProcessLoop.onReceive(DAGScheduler.scala:2793)
	at org.apache.spark.util.EventLoop$$anon$1.run(EventLoop.scala:49)

23/01/26 05:38:23 WARN ExecutorPodsWatchSnapshotSource: Kubernetes client has been closed.
23/01/26 05:38:24 WARN ShuffleClientImpl: Shuffle client has been shutdown!
Exception in thread "main" java.lang.RuntimeException: MySparkSQLCLIDriver exit with code(1)
	at org.apache.spark.sql.hive.my.MySparkSQLCLIDriver$.main(MySparkSQLCLIDriver.scala:204)
	at org.apache.spark.sql.hive.my.MySparkSQLCLIDriver.main(MySparkSQLCLIDriver.scala)
	at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke(Unknown Source)
	at java.base/jdk.internal.reflect.DelegatingMethodAccessorImpl.invoke(Unknown Source)
	at java.base/java.lang.reflect.Method.invoke(Unknown Source)
	at org.apache.spark.deploy.JavaMainApplication.start(SparkApplication.scala:52)
	at org.apache.spark.deploy.SparkSubmit.org$apache$spark$deploy$SparkSubmit$$runMain(SparkSubmit.scala:958)
	at org.apache.spark.deploy.SparkSubmit.doRunMain$1(SparkSubmit.scala:180)
	at org.apache.spark.deploy.SparkSubmit.submit(SparkSubmit.scala:203)
	at org.apache.spark.deploy.SparkSubmit.doSubmit(SparkSubmit.scala:90)
	at org.apache.spark.deploy.SparkSubmit$$anon$2.doSubmit(SparkSubmit.scala:1046)
	at org.apache.spark.deploy.SparkSubmit$.main(SparkSubmit.scala:1055)
	at org.apache.spark.deploy.SparkSubmit.main(SparkSubmit.scala)
EOF


:<<EOF
test case
  dynamic allocation with shuffletracking
  scheduler set to volcano
  assigned to a queue with half available resource by podgroup file
  use maxpending to reduce pending executors
  move common --conf from CLI to spark-defaults.conf
  RSS cluster enabled
  Fix executor memory to 2G to avoid executor OOM
  #Increase off-heap memory to avoid executor OOM
EOF
  echo -e "query,time" > spark-query.csv
  arr=(2 9)
  #for num in {1..2}
  for num in ${arr[*]}
  do
    start=$(date +"%s.%9N")
    spark-submit \
      --class org.apache.spark.sql.hive.my.MySparkSQLCLIDriver \
      --name spark-sql-job-test-manual-10-q${num} \
      --conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss-tpc:3.3.1 \
      --conf spark.kubernetes.scheduler.volcano.podGroupTemplateFile=/app/hdfs/spark/work-dir/podgroups/volcano-halfavailable-podgroup.yaml \
      --conf spark.executor.memory=2g \
      $SPARK_HOME/jars/my-spark-sql-cluster-3.jar \
      -f jfs://miniofs/tmp/spark-tpcds-10/q${num}.sql
    end=$(date +"%s.%9N")
    delta=`echo "scale=9;$end - $start" | bc`
    echo q${num},${delta}
    echo -e "q$num,${delta}" >> spark-query.csv
  done
  cat spark-query.csv
:<<EOF
q9还是有executor OOM，少了一些，driver没有失败
q2,115.748011617
q9,775.697776053
EOF


:<<EOF
test case
  dynamic allocation with shuffletracking
  scheduler set to volcano
  assigned to a queue with half available resource by podgroup file
  use maxpending to reduce pending executors
  move common --conf from CLI to spark-defaults.conf
  RSS cluster enabled
  Fix executor memory to 4G to avoid executor OOM
  #Increase off-heap memory to avoid executor OOM
EOF
  echo -e "query,time" > spark-query.csv
  arr=(9)
  #for num in {1..2}
  for num in ${arr[*]}
  do
    start=$(date +"%s.%9N")
    spark-submit \
      --class org.apache.spark.sql.hive.my.MySparkSQLCLIDriver \
      --name spark-sql-job-test-manual-10-q${num} \
      --conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss-tpc:3.3.1 \
      --conf spark.kubernetes.scheduler.volcano.podGroupTemplateFile=/app/hdfs/spark/work-dir/podgroups/volcano-halfavailable-podgroup.yaml \
      --conf spark.executor.memory=4g \
      $SPARK_HOME/jars/my-spark-sql-cluster-3.jar \
      -f jfs://miniofs/tmp/spark-tpcds-10/q${num}.sql
    end=$(date +"%s.%9N")
    delta=`echo "scale=9;$end - $start" | bc`
    echo q${num},${delta}
    echo -e "q$num,${delta}" >> spark-query.csv
  done
  cat spark-query.csv
:<<EOF
q9,685.477269435

Time taken: 672.422 seconds, Fetched 1 row(s)
357.850483	1038.882336	1721.298328	2404.876780	3086.395444

有2个RSS master报错no leader，重启后不报错，但是重启时作业driver报错
23/01/26 06:27:34 WARN RssHARetryClient: Master leader is not present currently, please check masters' status!
23/01/26 06:27:34 WARN RssHARetryClient: Master leader is not present currently, please check masters' status!
23/01/26 06:27:35 WARN RssHARetryClient: Master leader is not present currently, please check masters' status!
23/01/26 06:27:35 WARN RssHARetryClient: Master leader is not present currently, please check masters' status!
23/01/26 06:27:37 WARN RssHARetryClient: Master leader is not present currently, please check masters' status!
23/01/26 06:27:37 WARN RssHARetryClient: Master leader is not present currently, please check masters' status!
23/01/26 06:27:38 WARN RssHARetryClient: Master leader is not present currently, please check masters' status!
23/01/26 06:27:38 WARN RssHARetryClient: Master leader is not present currently, please check masters' status!
23/01/26 06:27:40 ERROR RssHARetryClient: Send rpc with failure, has tried 15, max try 15!
org.apache.celeborn.common.exception.CelebornException: Exception thrown in awaitResult:
        at org.apache.celeborn.common.util.ThreadUtils$.awaitResult(ThreadUtils.scala:231)                                                                                                                       Handling at org.apache.celeborn.common.rpc.RpcTimeout.awaitResult(RpcTimeout.scala:74)
        at org.apache.celeborn.common.haclient.RssHARetryClient.sendMessageInner(RssHARetryClient.java:150)
        at org.apache.celeborn.common.haclient.RssHARetryClient.lambda$send$0(RssHARetryClient.java:109)                                                                                                         E0126 14:at java.base/java.util.concurrent.Executors$RunnableAdapter.call(Unknown Source)80 -> 18080: Timeout occurred
        at java.base/java.util.concurrent.FutureTask.run(Unknown Source)                                                                                                                                         Handling at java.base/java.util.concurrent.ThreadPoolExecutor.runWorker(Unknown Source)
        at java.base/java.util.concurrent.ThreadPoolExecutor$Worker.run(Unknown Source)
        at java.base/java.lang.Thread.run(Unknown Source)ndling connection for 2080
Caused by: org.apache.celeborn.common.haclient.MasterNotLeaderException: Master:celeborn-master-2.celeborn-master-svc.spark-rss.svc.cluster.local:9097 is not the leader. Suggested leader is Master:leader is not
 present.                                                                                                      Handling connection for 2080
        at org.apache.celeborn.service.deploy.master.clustermeta.ha.HAHelper.checkShouldProcess(HAHelper.java:51)                                                                                                E0126 14:at org.apache.celeborn.service.deploy.master.Master.executeWithLeaderChecker(Master.scala:191)imeout occurred
        at org.apache.celeborn.service.deploy.master.Master$$anonfun$receiveAndReply$1.applyOrElse(Master.scala:216) E0126 14:25:53.078565   27098 portforward.go:368] error creating forwarding stream for port 2080 -> 1at org.apache.celeborn.common.rpc.netty.Inbox.$anonfun$process$1(Inbox.scala:115)
        at org.apache.celeborn.common.rpc.netty.Inbox.safelyCall(Inbox.scala:222)
RSS worker也有报错：
23/01/26 14:31:11,147 WARN [worker-forward-message-scheduler] RssHARetryClient: Connect to celeborn-master-1.celeborn-master-svc.spark-rss.svc.cluster.local:9097 failed.
org.apache.celeborn.common.rpc.RpcTimeoutException: Futures timed out after [30000 milliseconds]. This timeout is controlled by celeborn.rpc.lookupTimeout
	at org.apache.celeborn.common.rpc.RpcTimeout.org$apache$celeborn$common$rpc$RpcTimeout$$createRpcTimeoutException(RpcTimeout.scala:46)
	at org.apache.celeborn.common.rpc.RpcTimeout$$anonfun$addMessageIfTimeout$1.applyOrElse(RpcTimeout.scala:61)
	at org.apache.celeborn.common.rpc.RpcTimeout$$anonfun$addMessageIfTimeout$1.applyOrElse(RpcTimeout.scala:57)
	at scala.runtime.AbstractPartialFunction.apply(AbstractPartialFunction.scala:38)
	at org.apache.celeborn.common.rpc.RpcTimeout.awaitResult(RpcTimeout.scala:75)
	at org.apache.celeborn.common.rpc.RpcEnv.setupEndpointRefByURI(RpcEnv.scala:96)
	at org.apache.celeborn.common.rpc.RpcEnv.setupEndpointRef(RpcEnv.scala:104)
	at org.apache.celeborn.common.haclient.RssHARetryClient.setupEndpointRef(RssHARetryClient.java:251)
	at org.apache.celeborn.common.haclient.RssHARetryClient.getOrSetupRpcEndpointRef(RssHARetryClient.java:227)
	at org.apache.celeborn.common.haclient.RssHARetryClient.sendMessageInner(RssHARetryClient.java:148)
	at org.apache.celeborn.common.haclient.RssHARetryClient.askSync(RssHARetryClient.java:118)
	at org.apache.celeborn.service.deploy.worker.Worker.org$apache$celeborn$service$deploy$worker$Worker$$heartBeatToMaster(Worker.scala:261)
	at org.apache.celeborn.service.deploy.worker.Worker$$anon$1.$anonfun$run$1(Worker.scala:290)
	at org.apache.celeborn.common.util.Utils$.tryLogNonFatalError(Utils.scala:193)
	at org.apache.celeborn.service.deploy.worker.Worker$$anon$1.run(Worker.scala:290)
	at java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:511)
	at java.util.concurrent.FutureTask.runAndReset(FutureTask.java:308)
	at java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.access$301(ScheduledThreadPoolExecutor.java:180)
	at java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.run(ScheduledThreadPoolExecutor.java:294)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
	at java.lang.Thread.run(Thread.java:748)
Caused by: java.util.concurrent.TimeoutException: Futures timed out after [30000 milliseconds]
	at scala.concurrent.impl.Promise$DefaultPromise.ready(Promise.scala:259)
	at scala.concurrent.impl.Promise$DefaultPromise.result(Promise.scala:263)
	at org.apache.celeborn.common.util.ThreadUtils$.awaitResult(ThreadUtils.scala:227)
	at org.apache.celeborn.common.rpc.RpcTimeout.awaitResult(RpcTimeout.scala:74)
	... 17 more
23/01/26 14:31:11,150 INFO [worker-forward-message-scheduler] RssHARetryClient: connect to master celeborn-master-2.celeborn-master-svc.spark-rss.svc.cluster.local:9097.
EOF


:<<EOF
test case
  dynamic allocation without shuffletracking
  scheduler set to volcano
  assigned to a queue with half available resource by podgroup file
  use maxpending to reduce pending executors
  move common --conf from CLI to spark-defaults.conf
  RSS cluster enabled
  Fix executor memory to 4G to avoid executor OOM
  #Increase off-heap memory to avoid executor OOM
  Reboot RSS cluster to make sure no impact to job
EOF
  echo -e "query,time" > spark-query.csv
  arr=(1)
  #for num in {1..2}
  for num in ${arr[*]}
  do
    start=$(date +"%s.%9N")
    spark-submit \
      --deploy-mode cluster \
      --class org.apache.spark.sql.hive.my.MySparkSQLCLIDriver \
      --name spark-sql-job-test-manual-10-q${num} \
      --conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss:3.3.1 \
      --conf spark.kubernetes.scheduler.volcano.podGroupTemplateFile=/app/hdfs/spark/work-dir/podgroups/volcano-halfavailable-podgroup.yaml \
      --conf spark.executor.memory=4g \
      $SPARK_HOME/jars/my-spark-sql-cluster-3.jar \
      -f jfs://miniofs/tmp/spark-tpcds-10/q${num}.sql
    end=$(date +"%s.%9N")
    delta=`echo "scale=9;$end - $start" | bc`
    echo q${num},${delta}
    echo -e "q$num,${delta}" >> spark-query.csv
  done
  cat spark-query.csv
:<<EOF
1，with shuffletracking by mistake
作业driver没有报错，rss集群还有1个master报错not leader，其他正常
q9,683.564783875
357.850483	1038.882336	1721.298328	2404.876780	3086.395444
Time taken: 671.606 seconds, Fetched 1 row(s)

2，without shuffletracking
357.850483	1038.882336	1721.298328	2404.876780	3086.395444
Time taken: 738.08 seconds, Fetched 1 row(s)
q9,752.514148249
EOF


:<<EOF
test case
  dynamic allocation without shuffletracking
  scheduler set to volcano
  assigned to a queue with half available resource by podgroup file
  use maxpending to reduce pending executors
  move common --conf from CLI to spark-defaults.conf
  RSS cluster enabled
  Fix executor memory to 4G to avoid executor OOM
  #Increase off-heap memory to avoid executor OOM
  Reboot RSS cluster to make sure no impact to job
  Try spark-sql with volcano
EOF
  echo -e "query,time" > spark-query.csv
  arr=(1)
  #for num in {1..2}
  for num in ${arr[*]}
  do
    start=$(date +"%s.%9N")
    #spark-submit \
    #  --deploy-mode cluster \
    #  --class org.apache.spark.sql.hive.my.MySparkSQLCLIDriver \
    #  $SPARK_HOME/jars/my-spark-sql-cluster-3.jar \
    spark-sql \
      --deploy-mode client \
      --name spark-sql-job-test-manual-10-q${num} \
      --conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss:3.3.1 \
      --conf spark.kubernetes.scheduler.volcano.podGroupTemplateFile=/app/hdfs/spark/work-dir/podgroups/volcano-halfavailable-podgroup.yaml \
      --conf spark.executor.memory=4g \
      -f jfs://miniofs/tmp/spark-tpcds-10/q${num}.sql
    end=$(date +"%s.%9N")
    delta=`echo "scale=9;$end - $start" | bc`
    echo q${num},${delta}
    echo -e "q$num,${delta}" >> spark-query.csv
  done
  cat spark-query.csv
:<<EOF
volcano需要用podgroup处理driver的资源，但是client模式driver和发起命令的已经存在的pod是同一个，无法处理，所以用volcano就必须用cluster模式
23/01/30 10:12:51 WARN ExecutorPodsSnapshotsStoreImpl: Exception when notifying snapshot subscriber.
io.fabric8.kubernetes.client.KubernetesClientException: Failure executing: POST at: https://kubernetes.default.svc.cluster.local/api/v1/namespaces/spark-operator/pods. Message: admission webhook "validatepod.volcano.sh" denied the request: failed to get PodGroup for pod <spark-operator/spark-sql-job-test-manual-10-q1-89a4df860229efaa-exec-3>: podgroups.scheduling.volcano.sh "spark-0f19d22bb4564761a869067c3c54eb51-podgroup" not found. Received status: Status(apiVersion=v1, code=400, details=null, kind=Status, message=admission webhook "validatepod.volcano.sh" denied the request: failed to get PodGroup for pod <spark-operator/spark-sql-job-test-manual-10-q1-89a4df860229efaa-exec-3>: podgroups.scheduling.volcano.sh "spark-0f19d22bb4564761a869067c3c54eb51-podgroup" not found, metadata=ListMeta(_continue=null, remainingItemCount=null, resourceVersion=null, selfLink=null, additionalProperties={}), reason=null, status=Failure, additionalProperties={}).
EOF


#9
:<<EOF
357.850483	1038.882336	1721.298328	2404.876780	3086.395444
Time taken: 700.797 seconds, Fetched 1 row(s)
EOF

#1
:<<EOF
AAAAAAAAAAAAFAAA
AAAAAAAAAAAAHAAA
AAAAAAAAAAAAHAAA
AAAAAAAAAAABCAAA
AAAAAAAAAAACGAAA
AAAAAAAAAAADAAAA
AAAAAAAAAAAFBAAA
AAAAAAAAAAAFFAAA
AAAAAAAAAAAFHAAA
AAAAAAAAAAAHAAAA
AAAAAAAAAAAHBAAA
AAAAAAAAAAAHCAAA
AAAAAAAAAAAIEAAA
AAAAAAAAAAAIHAAA
AAAAAAAAAAANAAAA
AAAAAAAAAAANBAAA
AAAAAAAAAAAOBAAA
AAAAAAAAAAAPAAAA
AAAAAAAAAABAHAAA
AAAAAAAAAABBBAAA
AAAAAAAAAABDHAAA
AAAAAAAAAABEBAAA
AAAAAAAAAABEEAAA
AAAAAAAAAABIAAAA
AAAAAAAAAABJGAAA
AAAAAAAAAABNFAAA
AAAAAAAAAABPFAAA
AAAAAAAAAACADAAA
AAAAAAAAAACDAAAA
AAAAAAAAAACGBAAA
AAAAAAAAAACHGAAA
AAAAAAAAAACLAAAA
AAAAAAAAAADCEAAA
AAAAAAAAAADDGAAA
AAAAAAAAAADEHAAA
AAAAAAAAAADGGAAA
AAAAAAAAAADLGAAA
AAAAAAAAAADODAAA
AAAAAAAAAAEACAAA
AAAAAAAAAAEAHAAA
AAAAAAAAAAECDAAA
AAAAAAAAAAEDDAAA
AAAAAAAAAAEFCAAA
AAAAAAAAAAEFDAAA
AAAAAAAAAAEGDAAA
AAAAAAAAAAEGEAAA
AAAAAAAAAAEHCAAA
AAAAAAAAAAEIEAAA
AAAAAAAAAAEJBAAA
AAAAAAAAAAEKEAAA
AAAAAAAAAAELAAAA
AAAAAAAAAAELEAAA
AAAAAAAAAAEMCAAA
AAAAAAAAAAENFAAA
AAAAAAAAAAEPAAAA
AAAAAAAAAAEPEAAA
AAAAAAAAAAFAFAAA
AAAAAAAAAAFAFAAA
AAAAAAAAAAFAGAAA
AAAAAAAAAAFBAAAA
AAAAAAAAAAFBFAAA
AAAAAAAAAAFEDAAA
AAAAAAAAAAFHBAAA
AAAAAAAAAAFJEAAA
AAAAAAAAAAFMEAAA
AAAAAAAAAAFNBAAA
AAAAAAAAAAFNFAAA
AAAAAAAAAAFOAAAA
AAAAAAAAAAFOGAAA
AAAAAAAAAAFOGAAA
AAAAAAAAAAFPAAAA
AAAAAAAAAAFPBAAA
AAAAAAAAAAGAAAAA
AAAAAAAAAAGBDAAA
AAAAAAAAAAGCCAAA
AAAAAAAAAAGCDAAA
AAAAAAAAAAGDCAAA
AAAAAAAAAAGFGAAA
AAAAAAAAAAGGGAAA
AAAAAAAAAAGHEAAA
AAAAAAAAAAGIDAAA
AAAAAAAAAAGMAAAA
AAAAAAAAAAGPFAAA
AAAAAAAAAAHBAAAA
AAAAAAAAAAHBBAAA
AAAAAAAAAAHBFAAA
AAAAAAAAAAHCBAAA
AAAAAAAAAAHCHAAA
AAAAAAAAAAHDBAAA
AAAAAAAAAAHEAAAA
AAAAAAAAAAHEFAAA
AAAAAAAAAAHFAAAA
AAAAAAAAAAHFBAAA
AAAAAAAAAAHFCAAA
AAAAAAAAAAHKBAAA
AAAAAAAAAAHMBAAA
AAAAAAAAAAHNAAAA
AAAAAAAAAAICDAAA
AAAAAAAAAAIDBAAA
AAAAAAAAAAIDFAAA
Time taken: 166.423 seconds, Fetched 100 row(s)

#2
5270	NULL	NULL	NULL	1.64	NULL	NULL	NULL
5270	NULL	NULL	NULL	1.64	NULL	NULL	NULL
5270	NULL	NULL	NULL	1.64	NULL	NULL	NULL
5270	NULL	NULL	NULL	1.64	NULL	NULL	NULL
5270	NULL	NULL	NULL	1.64	NULL	NULL	NULL
5270	NULL	NULL	NULL	1.64	NULL	NULL	NULL
5270	NULL	NULL	NULL	1.64	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5271	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5272	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5273	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5274	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5275	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5276	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5277	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5278	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5279	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5280	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5281	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5282	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5283	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5284	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5285	NULL	NULL	NULL	1.08	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5286	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5287	NULL	NULL	NULL	0.93	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5288	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5289	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5290	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5291	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5292	NULL	NULL	NULL	0.94	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5293	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5294	NULL	NULL	NULL	0.95	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5295	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5296	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL		NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5297	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5298	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5299	NULL	NULL	NULL	1.09	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5300	NULL	NULL	NULL	0.96	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5301	NULL	NULL	NULL	0.45	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5302	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5303	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5304	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5305	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5306	NULL	NULL	NULL	1.01	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5307	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5308	NULL	NULL	NULL	0.98	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5309	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5310	NULL	NULL	NULL	1.00	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5311	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5312	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5313	NULL	NULL	NULL	0.97	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5314	NULL	NULL	NULL	0.64	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5315	NULL	NULL	NULL	1.04	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5316	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5317	NULL	NULL	NULL	1.02	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5318	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5319	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5320	NULL	NULL	NULL	0.99	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5321	NULL	NULL	NULL	1.03	NULL	NULL	NULL
5322	NULL	NULL	NULL	1.79	NULL	NULL	NULL
5322	NULL	NULL	NULL	1.79	NULL	NULL	NULL
5322	NULL	NULL	NULL	1.79	NULL	NULL	NULL
5322	NULL	NULL	NULL	1.79	NULL	NULL	NULL
5322	NULL	NULL	NULL	1.79	NULL	NULL	NULL
5322	NULL	NULL	NULL	1.79	NULL	NULL	NULL
5322	NULL	NULL	NULL	1.79	NULL	NULL	NULL
Time taken: 291.873 seconds, Fetched 2513 row(s)
EOF