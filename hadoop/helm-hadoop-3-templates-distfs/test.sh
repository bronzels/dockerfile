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

HDPHOME=${MYHOME}/workspace/dockerfile/hadoop/helm-hadoop-3

file=distfs-test.yaml
cp ${file}.template ${file}
#juicefs
mntpath=/app/hdfs/hadoop/distfsmnt
$SED -i 's@harbor.my.org:1080/chenseanxy/hadoop-ubussh@harbor.my.org:1080/chenseanxy/hadoop-ubussh-juicefs@g' ${file}
#cubefs
mntpath=/cfs/mnt
$SED -i 's@harbor.my.org:1080/chenseanxy/hadoop-ubussh@harbor.my.org:1080/chenseanxy/hadoop-ubussh-cubefs@g' ${file}
kubectl apply -f distfs-test.yaml
kubectl exec -it distfs-test -- /bin/bash
  #juicefs
  mkdir distfsmnt
  juicefs mount "redis://:redis@my-redis-master.redis.svc.cluster.local:6379/1" distfsmnt > distfsmnt.log 2>&1 &
  #cubefs
  /cfs/bin/start.sh > distfsmnt.log 2>&1 &

  dd if=/dev/zero of=${mntpath}/test-dd-w.dbf status=progress bs=2M count=1000 oflag=direct
  dd if=${mntpath}/test-dd-w.dbf of=/dev/null status=progress bs=2M
  dd if=${mntpath}/test-dd-w.dbf of=${mntpath}/test-dd-rw.dbf status=progress bs=4k
  echo "----------------------------------------------------------------------------------------------------------------------------------------"

  TARGET_PATH="${mntpath}/test-mdtest"
  FILE_SIZE=1024
  mdtest -n 1000 -w $i -e $FILE_SIZE -y -u -i 3 -N 1 -F -R -d $TARGET_PATH
  echo "----------------------------------------------------------------------------------------------------------------------------------------"

  path=${mntpath}
  for ioengine in {psync,libaio}
  do
    echo "ioengine:${ioengine}"
    for iotest in {read,randread,write,randwrite}
    do
      echo "iotest:${iotest}"
      for numjobs in {1,4}
      do
        echo "numjobs:${numjobs}"
        fio -directory=${path} \
            -ioengine=${ioengine} \
            -rw=${iotest} \
            -bs=4k \
            -direct=1 \
            -group_reporting=1 \
            -fallocate=none \
            -time_based=1 \
            -runtime=120 \
            -name=test_file_c \
            -numjobs=${numjobs} \
            -nrfiles=1 \
            -size=10G
        echo "----------------------------------------------------------------------------------------------------------------------------------------"
      done
    done
  done
kubectl port-forward -n hadoop svc/myhdp-hadoop-yarn-ui 8088:8088 &
#juicefs.cache-dir目录如果是root权限创建的，hdfs无法访问，不配置会在hdfs的home的.cache目录存放
helm install myhdp -n hadoop -f values.yaml \
  --set yarn.nodeManager.replicas=3 \
  --set yarn.nodeManager.resources.requests.memory="2048Mi" \
  --set yarn.nodeManager.resources.requests.cpu="1000m" \
  --set yarn.nodeManager.resources.limits.memory="2048Mi" \
  --set yarn.nodeManager.resources.limits.cpu="1000m" \
  ./
helm install myhdp -n hadoop -f values.yaml \
  --set yarn.nodeManager.replicas=3 \
  --set yarn.nodeManager.resources.requests.memory="4096Mi" \
  --set yarn.nodeManager.resources.requests.cpu="2000m" \
  --set yarn.nodeManager.resources.limits.memory="4096Mi" \
  --set yarn.nodeManager.resources.limits.cpu="2000m" \
  ./
helm install myhdp -n hadoop -f values.yaml \
  --set yarn.nodeManager.replicas=3 \
  --set yarn.nodeManager.resources.requests.memory="8192Mi" \
  --set yarn.nodeManager.resources.requests.cpu="4000m" \
  --set yarn.nodeManager.resources.limits.memory="8192Mi" \
  --set yarn.nodeManager.resources.limits.cpu="4000m" \
  ./
helm install myhdp -n hadoop -f values.yaml \
  --set yarn.nodeManager.replicas=3 \
  --set yarn.nodeManager.resources.requests.memory="16Gi" \
  --set yarn.nodeManager.resources.requests.cpu="4000m" \
  --set yarn.nodeManager.resources.limits.memory="16Gi" \
  --set yarn.nodeManager.resources.limits.cpu="4000m" \
  ./
kubectl exec -it -n hadoop myhdp-hadoop-yarn-rm-0 -- /bin/bash
  hadoop jar /app/hdfs/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-3.2.1-tests.jar TestDFSIO -write -nrFiles 5 -fileSize 128MB -resFile /tmp/TestDFSIOwrite.txt
  hdfs dfs -rm -r -f /teragen
  hadoop jar /app/hdfs/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.2.1.jar teragen -Dmapred.map.tasks=20 10000000 /teragen/out
  hdfs dfs -rm -r -f /terasort
  hadoop jar /app/hdfs/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.2.1.jar terasort -Dmapred.map.tasks=20 /teragen/out /terasort/out
echo "----------------------------------------------------------------------------------------------------------------------------------------"
