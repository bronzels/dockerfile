kubectl apply -f juicefs-test.yaml
kubectl exec -it juicefs-test -- /bin/bash
  mkdir jfsmnt
  juicefs mount "redis://my-redis-ha.redis.svc.cluster.local:6379/1" jfsmnt > jfsmnt.log 2>&1 &

  dd if=/dev/zero of=/usr/local/hadoop/jfsmnt/test-dd-w.dbf status=progress bs=2M count=1000 oflag=direct
  dd if=/usr/local/hadoop/jfsmnt/test-dd-w.dbf of=/dev/null status=progress bs=2M
  dd if=/usr/local/hadoop/jfsmnt/test-dd-w.dbf of=/usr/local/hadoop/jfsmnt/test-dd-rw.dbf status=progress bs=4k
  echo "----------------------------------------------------------------------------------------------------------------------------------------"

  TARGET_PATH="/usr/local/hadoop/jfsmnt/test-mdtest"
  FILE_SIZE=1024
  mdtest -n 1000 -w $i -e $FILE_SIZE -y -u -i 3 -N 1 -F -R -d $TARGET_PATH
  echo "----------------------------------------------------------------------------------------------------------------------------------------"

  path=/usr/local/hadoop/jfsmnt
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
helm install myhdp -n hadoop -f values.yaml \
  --set yarn.nodeManager.replicas=3 \
  --set yarn.nodeManager.resources.requests.memory="2048Mi" \
  --set yarn.nodeManager.resources.requests.cpu="1000m" \
  --set yarn.nodeManager.resources.limits.memory="2048Mi" \
  --set yarn.nodeManager.resources.limits.cpu="1000m" \
  ./
kubectl exec -it -n hadoop myhdp-hadoop-yarn-rm-0 -- /bin/bash
  su hdfs
    /usr/local/hadoop/bin/hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-3.2.1-tests.jar TestDFSIO -write -nrFiles 5 -fileSize 128MB -resFile /tmp/TestDFSIOwrite.txt
    /usr/local/hadoop/bin/hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.2.1.jar teragen -Dmapred.map.tasks=20 10000000 /teragen/out
    /usr/local/hadoop/bin/hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.2.1.jar terasort -Dmapred.map.tasks=20 /teragen/out /terasort/out
helm install myhdp -n hadoop -f values.yaml \
  --set yarn.nodeManager.replicas=3 \
  --set yarn.nodeManager.resources.requests.memory="4096Mi" \
  --set yarn.nodeManager.resources.requests.cpu="2000m" \
  --set yarn.nodeManager.resources.limits.memory="4096Mi" \
  --set yarn.nodeManager.resources.limits.cpu="2000m" \
  ./
kubectl exec -it -n hadoop myhdp-hadoop-yarn-rm-0 -- /bin/bash
  su hdfs
    /usr/local/hadoop/bin/hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-3.2.1-tests.jar TestDFSIO -write -nrFiles 5 -fileSize 128MB -resFile /tmp/TestDFSIOwrite.txt
    /usr/local/hadoop/bin/hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.2.1.jar teragen -Dmapred.map.tasks=20 10000000 /teragen/out
    /usr/local/hadoop/bin/hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.2.1.jar terasort -Dmapred.map.tasks=20 /teragen/out /terasort/out
