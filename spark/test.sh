#spark query on yarn
#q1, timediff:346.991397060
#q2, timediff:743.642260938

kubectl port-forward spark-sql-job-test-qhgk9 4040:4040 &

kubectl apply -f spark-test.yaml -n spark-operator
kubectl delete -f spark-test.yaml -n spark-operator
kubectl exec -it spark-test -n spark-operator -- /bin/bash
  echo "use tpcds_bin_partitioned_orc_10" > dbuse.sql

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
kubectl get pod -n spark-operator |grep spark-sql-job-test-manual|awk '{print $1}'| xargs kubectl delete pod "$1" -n spark-operator
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