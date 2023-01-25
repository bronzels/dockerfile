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
NODE       CPU REQUESTS   CPU LIMITS     CPU UTIL      MEMORY REQUESTS   MEMORY LIMITS   MEMORY UTIL
*          6750m (24%)    10000m (35%)   575m (2%)   20408Mi (15%)     50516Mi (39%)   9726Mi (7%)
EOF

kubectl port-forward spark-test -n spark-operator 4040:4040 &

#删除已完成的driver pod
kubectl get pod -n spark-operator |grep spark-sql-job-test-manual |grep driver |grep Completed |awk '{print $1}'| xargs kubectl delete pod "$1" -n spark-operator

kubectl apply -f spark-test.yaml -n spark-operator
kubectl delete -f spark-test.yaml -n spark-operator
kubectl exec -it spark-test -n spark-operator -- /bin/bash
  echo "use tpcds_bin_partitioned_orc_10" > dbuse.sql


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
kubectl apply -f rss-juicefs-pvc-test-pod.yaml -n spark-operator
:<<EOF
kubectl delete -f rss-juicefs-pvc-test-pod.yaml -n spark-operator
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
    hadoop fs -put ${file} ${file}
    #hadoop fs -cat /tmp/spark-tpcds-10/q${num}.sql
    echo "q${num} done"
  done
  hadoop fs -mkdir /tmp/k8sup


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