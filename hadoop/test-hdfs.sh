kubectl port-forward -n hadoop svc/my-hadoop-yarn-ui 8088:8088 &
#juicefs.cache-dir目录如果是root权限创建的，hdfs无法访问，不配置会在hdfs的home的.cache目录存放
helm install my -n hadoop -f values.yaml \
  --set yarn.nodeManager.replicas=3 \
  --set yarn.nodeManager.resources.requests.memory="2048Mi" \
  --set yarn.nodeManager.resources.requests.cpu="1000m" \
  --set yarn.nodeManager.resources.limits.memory="2048Mi" \
  --set yarn.nodeManager.resources.limits.cpu="1000m" \
  ./
helm install my -n hadoop -f values.yaml \
  --set yarn.nodeManager.replicas=3 \
  --set yarn.nodeManager.resources.requests.memory="4096Mi" \
  --set yarn.nodeManager.resources.requests.cpu="2000m" \
  --set yarn.nodeManager.resources.limits.memory="4096Mi" \
  --set yarn.nodeManager.resources.limits.cpu="2000m" \
  ./
helm install my -n hadoop -f values.yaml \
  --set yarn.nodeManager.replicas=3 \
  --set yarn.nodeManager.resources.requests.memory="8192Mi" \
  --set yarn.nodeManager.resources.requests.cpu="4000m" \
  --set yarn.nodeManager.resources.limits.memory="8192Mi" \
  --set yarn.nodeManager.resources.limits.cpu="4000m" \
  ./
helm install my -n hadoop -f values.yaml \
  --set yarn.nodeManager.replicas=3 \
  --set yarn.nodeManager.resources.requests.memory="16384Mi" \
  --set yarn.nodeManager.resources.requests.cpu="4000m" \
  --set yarn.nodeManager.resources.limits.memory="16384Mi" \
  --set yarn.nodeManager.resources.limits.cpu="4000m" \
  ./
kubectl exec -it -n hadoop my-hadoop-yarn-rm-0 -- /bin/bash
  hadoop jar /app/hdfs/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-3.2.1-tests.jar TestDFSIO -write -nrFiles 5 -fileSize 128MB -resFile /tmp/TestDFSIOwrite.txt
  hdfs dfs -rm -r -f /teragen
  hadoop jar /app/hdfs/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.2.1.jar teragen -Dmapred.map.tasks=20 10000000 /teragen/out
  hdfs dfs -rm -r -f /terasort
  hadoop jar /app/hdfs/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.2.1.jar terasort -Dmapred.map.tasks=20 /teragen/out /terasort/out
echo "----------------------------------------------------------------------------------------------------------------------------------------"
