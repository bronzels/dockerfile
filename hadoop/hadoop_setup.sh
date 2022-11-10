#HDPHOME=~/charts/stable/hadoop
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Mac detected."
    #mac
    HDPHOME=/Volumes/data/workspace/cluster-sh-k8s/hadoop/helm-hadoop-3
    SED=gsed
else
    echo "Assuming linux by default."
    #linux
    HDPHOME=~/helm-hadoop-3
    SED=sed
fi
cd ${HDPHOME}


helm uninstall myhdp -n hadoop
kubectl get pvc -n hadoop | grep hdfs | awk '{print $1}' | xargs kubectl delete pvc -n hadoop
kubectl get pv -n hadoop | grep hdfs | awk '{print $1}' | xargs kubectl delete pv
ansible all -m shell -a"rm -rf /data0/hdfs"
ansible all -m shell -a"mkdir -p /data0/hdfs/pvdn"
sudo ssh dtpct mkdir -p /data0/hdfs/pvnn
kubectl apply -f hdfs-pv-nn.yaml
kubectl apply -f pvs/
kubectl get pv

#chmod a+x tools/calc_resources.sh
#helm install myhadoop $(tools/calc_resources.sh 50) -n hadoop -f values.yaml \
helm install myhdp -n hadoop -f values.yaml \
  --set hdfs.dataNode.replicas=2 \
  --set yarn.nodeManager.replicas=2 \
  --set persistence.nameNode.enabled=true \
  --set persistence.nameNode.storageClass=hdfs-local-storage-nn \
  --set persistence.dataNode.enabled=true \
  --set persistence.dataNode.storageClass=hdfs-local-storage-dn \
  --set persistence.nameNode.size=20Gi \
  --set persistence.dataNode.size=80Gi \
  --set hdfs.dataNode.resources.requests.memory="2048Mi" \
  --set hdfs.dataNode.resources.requests.cpu="1000m" \
  --set hdfs.dataNode.resources.limits.memory="2048Mi" \
  --set hdfs.dataNode.resources.limits.cpu="1000m" \
  --set yarn.nodeManager.resources.requests.memory="2048Mi" \
  --set yarn.nodeManager.resources.requests.cpu="1000m" \
  --set yarn.nodeManager.resources.limits.memory="2048Mi" \
  --set yarn.nodeManager.resources.limits.cpu="1000m" \
  ./
:<<EOF
  --set persistence.dataNode.storageClass=rook-ceph-block \
  --set persistence.nameNode.size=128Gi \
  --set persistence.dataNode.size=512Gi \
  --set hdfs.dataNode.resources.requests.memory="4096Mi" \
  --set hdfs.dataNode.resources.requests.cpu="2000m" \
  --set hdfs.dataNode.resources.limits.memory="8196Mi" \
  --set hdfs.dataNode.resources.limits.cpu="4000m" \
  --set yarn.nodeManager.resources.requests.memory="16384Mi" \
  --set yarn.nodeManager.resources.requests.cpu="4000m" \
  --set yarn.nodeManager.resources.limits.memory="65536Mi" \
  --set yarn.nodeManager.resources.limits.cpu="14000m" \
EOF
:<<EOF
helm uninstall myhdp -n hadoop
kubectl get pvc -n hadoop | awk '{print $1}' | xargs kubectl delete pvc -n hadoop

kubectl describe pod myhdp-hadoop-hdfs-dn-1 -n hadoop
kubectl describe pod myhdp-hadoop-yarn-nm-0 -n hadoop
kubectl exec -it myhdp-hadoop-yarn-rm-0 -n hadoop bash

kubectl get configmap myhdp-hadoop -n hadoop -o yaml

kubectl get pod -n hadoop -o wide
kubectl get pvc -n hadoop -o wide
kubectl get svc -n hadoop -o wide

kubectl exec -n hadoop -it myhdp-hadoop-hdfs-nn-0 -- /usr/local/hadoop/bin/hdfs dfs -ls /
yarn: http://master01:31088/cluster
hdfs: http://master01:30870/dfshealth.html#tab-overview

EOF

:<<EOF
NOTES:
1. You can check the status of HDFS by running this command:
   kubectl exec -n hadoop -it myhdp-hadoop-hdfs-nn-0 -- /usr/local/hadoop/bin/hdfs dfsadmin -report

2. You can list the yarn nodes by running this command:
   kubectl exec -n hadoop -it myhdp-hadoop-yarn-rm-0 -- /usr/local/hadoop/bin/yarn node -list

3. Create a port-forward to the yarn resource manager UI:
   kubectl port-forward -n hadoop myhdp-hadoop-yarn-rm-0 8088:8088

   Then open the ui in your browser:

   open http://localhost:8088

4. You can run included hadoop tests like this:
   kubectl exec -n hadoop -it myhdp-hadoop-yarn-nm-0 -- /usr/local/hadoop/bin/hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-2.9.0-tests.jar TestDFSIO -write -nrFiles 5 -fileSize 128MB -resFile /tmp/TestDFSIOwrite.txt

5. You can list the mapreduce jobs like this:
   kubectl exec -n hadoop -it myhdp-hadoop-yarn-rm-0 -- /usr/local/hadoop/bin/mapred job -list

6. This chart can also be used with the zeppelin chart
    helm install --namespace hadoop --set hadoop.useConfigMap=true,hadoop.configMapName=myhdp-hadoop stable/zeppelin

7. You can scale the number of yarn nodes like this:
   helm upgrade myhdp --set yarn.nodeManager.replicas=4 stable/hadoop

   Make sure to update the values.yaml if you want to make this permanent.
EOF

:<<EOF

#2.9.0
   kubectl exec -n hadoop -it myhdp-hadoop-yarn-nm-0 -- /usr/local/hadoop/bin/hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-2.9.0-tests.jar TestDFSIO -write -nrFiles 5 -fileSize 128MB -resFile /tmp/TestDFSIOwrite.txt
#3.2.1
   kubectl exec -n hadoop -it myhdp-hadoop-yarn-nm-0 -- /usr/local/hadoop/bin/hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-3.2.1-tests.jar TestDFSIO -write -nrFiles 5 -fileSize 128MB -resFile /tmp/TestDFSIOwrite.txt
2022-11-07 08:33:05,734 INFO sasl.SaslDataTransferClient: SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2022-11-07 08:33:05,742 INFO fs.TestDFSIO: ----- TestDFSIO ----- : write
2022-11-07 08:33:05,742 INFO fs.TestDFSIO:             Date & time: Mon Nov 07 08:33:05 UTC 2022
2022-11-07 08:33:05,742 INFO fs.TestDFSIO:         Number of files: 5
2022-11-07 08:33:05,742 INFO fs.TestDFSIO:  Total MBytes processed: 640
2022-11-07 08:33:05,742 INFO fs.TestDFSIO:       Throughput mb/sec: 3.44
2022-11-07 08:33:05,742 INFO fs.TestDFSIO:  Average IO rate mb/sec: 4.24
2022-11-07 08:33:05,742 INFO fs.TestDFSIO:   IO rate std deviation: 2.52
2022-11-07 08:33:05,742 INFO fs.TestDFSIO:      Test exec time sec: 81.65
2022-11-07 08:33:05,742 INFO fs.TestDFSIO:
#3.1.1
   kubectl exec -n hadoop -it myhdp-hadoop-yarn-nm-0 -- /usr/local/hadoop/bin/hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-3.1.1-tests.jar TestDFSIO -write -nrFiles 5 -fileSize 128MB -resFile /tmp/TestDFSIOwrite.txt
EOF

:<<EOF
#5台物理机，64 core、512G的
----- TestDFSIO ----- : write
           Date & time: Mon Nov 07 17:06:27 CST 2022
       Number of files: 5
Total MBytes processed: 640.0
     Throughput mb/sec: 115.31531531531532
Average IO rate mb/sec: 126.87004089355469
 IO rate std deviation: 46.914197663583266
    Test exec time sec: 61.293
EOF

kubectl exec -n hadoop -it myhdp-hadoop-yarn-nm-0 -- /usr/local/hadoop/bin/hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.2.1.jar teragen -Dmapred.map.tasks=20 10000000 /teragen/out
kubectl exec -n hadoop -it myhdp-hadoop-yarn-nm-0 -- /usr/local/hadoop/bin/hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.2.1.jar terasort -Dmapred.map.tasks=20 /teragen/out /terasort/out
:<<EOF
2022-11-07 08:47:09,757 INFO mapreduce.Job: Counters: 34
	File System Counters
		FILE: Number of bytes read=0
		FILE: Number of bytes written=4534910
		FILE: Number of read operations=0
		FILE: Number of large read operations=0
		FILE: Number of write operations=0
		HDFS: Number of bytes read=1697
		HDFS: Number of bytes written=1000000000
		HDFS: Number of read operations=120
		HDFS: Number of large read operations=0
		HDFS: Number of write operations=40
		HDFS: Number of bytes read erasure-coded=0
	Job Counters
		Launched map tasks=21
		Other local map tasks=21
		Total time spent by all maps in occupied slots (ms)=407922
		Total time spent by all reduces in occupied slots (ms)=0
		Total time spent by all map tasks (ms)=407922
		Total vcore-milliseconds taken by all map tasks=407922
		Total megabyte-milliseconds taken by all map tasks=417712128
	Map-Reduce Framework
		Map input records=10000000
		Map output records=10000000
		Input split bytes=1697
		Spilled Records=0
		Failed Shuffles=0
		Merged Map outputs=0
		GC time elapsed (ms)=4204
		CPU time spent (ms)=43010
		Physical memory (bytes) snapshot=6051799040
		Virtual memory (bytes) snapshot=53353488384
		Total committed heap usage (bytes)=8327790592
		Peak Map Physical memory (bytes)=352542720
		Peak Map Virtual memory (bytes)=2672865280
	org.apache.hadoop.examples.terasort.TeraGen$Counters
		CHECKSUM=21472776955442690
	File Input Format Counters
		Bytes Read=0
	File Output Format Counters
		Bytes Written=1000000000
EOF


helm install myhdp -n hadoop -f values.yaml \
  --set hdfs.dataNode.replicas=2 \
  --set yarn.nodeManager.replicas=2 \
  --set persistence.nameNode.enabled=true \
  --set persistence.nameNode.storageClass=hdfs-local-storage-nn \
  --set persistence.dataNode.enabled=true \
  --set persistence.dataNode.storageClass=hdfs-local-storage-dn \
  --set persistence.nameNode.size=20Gi \
  --set persistence.dataNode.size=80Gi \
  --set hdfs.dataNode.resources.requests.memory="4096Mi" \
  --set hdfs.dataNode.resources.requests.cpu="2000m" \
  --set hdfs.dataNode.resources.limits.memory="4096Mi" \
  --set hdfs.dataNode.resources.limits.cpu="2000m" \
  --set yarn.nodeManager.resources.requests.memory="4096Mi" \
  --set yarn.nodeManager.resources.requests.cpu="2000m" \
  --set yarn.nodeManager.resources.limits.memory="4096Mi" \
  --set yarn.nodeManager.resources.limits.cpu="2000m" \
  ./
:<<EOF
EOF
kubectl exec -n hadoop -it myhdp-hadoop-yarn-nm-0 -- /usr/local/hadoop/bin/hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-3.2.1-tests.jar TestDFSIO -write -nrFiles 5 -fileSize 128MB -resFile /tmp/TestDFSIOwrite.txt
:<<EOF
2022-11-08 02:40:11,586 INFO sasl.SaslDataTransferClient: SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2022-11-08 02:40:11,595 INFO fs.TestDFSIO: ----- TestDFSIO ----- : write
2022-11-08 02:40:11,602 INFO fs.TestDFSIO:             Date & time: Tue Nov 08 02:40:11 UTC 2022
2022-11-08 02:40:11,602 INFO fs.TestDFSIO:         Number of files: 5
2022-11-08 02:40:11,602 INFO fs.TestDFSIO:  Total MBytes processed: 640
2022-11-08 02:40:11,602 INFO fs.TestDFSIO:       Throughput mb/sec: 69.49
2022-11-08 02:40:11,602 INFO fs.TestDFSIO:  Average IO rate mb/sec: 70.54
2022-11-08 02:40:11,602 INFO fs.TestDFSIO:   IO rate std deviation: 8.7
2022-11-08 02:40:11,602 INFO fs.TestDFSIO:      Test exec time sec: 25.45
2022-11-08 02:40:11,602 INFO fs.TestDFSIO:
EOF
kubectl exec -n hadoop -it myhdp-hadoop-yarn-nm-0 -- /usr/local/hadoop/bin/hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.2.1.jar teragen -Dmapred.map.tasks=20 10000000 /teragen/out
kubectl exec -n hadoop -it myhdp-hadoop-yarn-nm-0 -- /usr/local/hadoop/bin/hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.2.1.jar terasort -Dmapred.map.tasks=20 /teragen/out /terasort/out
:<<EOF
EOF

helm install myhdp -n hadoop -f values.yaml \
  --set hdfs.dataNode.replicas=2 \
  --set yarn.nodeManager.replicas=2 \
  --set persistence.nameNode.enabled=true \
  --set persistence.nameNode.storageClass=hdfs-local-storage-nn \
  --set persistence.dataNode.enabled=true \
  --set persistence.dataNode.storageClass=hdfs-local-storage-dn \
  --set persistence.nameNode.size=20Gi \
  --set persistence.dataNode.size=80Gi \
  --set hdfs.dataNode.resources.requests.memory="8192Mi" \
  --set hdfs.dataNode.resources.requests.cpu="3000m" \
  --set hdfs.dataNode.resources.limits.memory="8192Mi" \
  --set hdfs.dataNode.resources.limits.cpu="3000m" \
  --set yarn.nodeManager.resources.requests.memory="8192Mi" \
  --set yarn.nodeManager.resources.requests.cpu="3000m" \
  --set yarn.nodeManager.resources.limits.memory="8192Mi" \
  --set yarn.nodeManager.resources.limits.cpu="3000m" \
  ./
:<<EOF
EOF
kubectl exec -n hadoop -it myhdp-hadoop-yarn-nm-0 -- /usr/local/hadoop/bin/hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-3.2.1-tests.jar TestDFSIO -write -nrFiles 5 -fileSize 128MB -resFile /tmp/TestDFSIOwrite.txt
:<<EOF
2022-11-08 03:06:12,962 INFO sasl.SaslDataTransferClient: SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2022-11-08 03:06:12,975 INFO fs.TestDFSIO: ----- TestDFSIO ----- : write
2022-11-08 03:06:12,975 INFO fs.TestDFSIO:             Date & time: Tue Nov 08 03:06:12 UTC 2022
2022-11-08 03:06:12,975 INFO fs.TestDFSIO:         Number of files: 5
2022-11-08 03:06:12,975 INFO fs.TestDFSIO:  Total MBytes processed: 640
2022-11-08 03:06:12,975 INFO fs.TestDFSIO:       Throughput mb/sec: 65.62
2022-11-08 03:06:12,975 INFO fs.TestDFSIO:  Average IO rate mb/sec: 67.81
2022-11-08 03:06:12,975 INFO fs.TestDFSIO:   IO rate std deviation: 13.59
2022-11-08 03:06:12,975 INFO fs.TestDFSIO:      Test exec time sec: 22.61
2022-11-08 03:06:12,975 INFO fs.TestDFSIO:
EOF
kubectl exec -n hadoop -it myhdp-hadoop-yarn-nm-0 -- /usr/local/hadoop/bin/hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-3.2.1-tests.jar TestDFSIO -write -nrFiles 6 -fileSize 1024MB -resFile /tmp/TestDFSIOwrite.txt
:<<EOF
2022-11-08 03:15:28,984 INFO sasl.SaslDataTransferClient: SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2022-11-08 03:15:28,997 INFO fs.TestDFSIO: ----- TestDFSIO ----- : write
2022-11-08 03:15:29,008 INFO fs.TestDFSIO:             Date & time: Tue Nov 08 03:15:28 UTC 2022
2022-11-08 03:15:29,008 INFO fs.TestDFSIO:         Number of files: 6
2022-11-08 03:15:29,008 INFO fs.TestDFSIO:  Total MBytes processed: 6144
2022-11-08 03:15:29,008 INFO fs.TestDFSIO:       Throughput mb/sec: 9.07
2022-11-08 03:15:29,008 INFO fs.TestDFSIO:  Average IO rate mb/sec: 9.25
2022-11-08 03:15:29,008 INFO fs.TestDFSIO:   IO rate std deviation: 1.42
2022-11-08 03:15:29,008 INFO fs.TestDFSIO:      Test exec time sec: 152.76
2022-11-08 03:15:29,009 INFO fs.TestDFSIO:
EOF
kubectl exec -n hadoop -it myhdp-hadoop-yarn-nm-0 -- /usr/local/hadoop/bin/hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.2.1.jar teragen -Dmapred.map.tasks=20 10000000 /teragen/out
kubectl exec -n hadoop -it myhdp-hadoop-yarn-nm-0 -- /usr/local/hadoop/bin/hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.2.1.jar terasort -Dmapred.map.tasks=20 /teragen/out /terasort/out
:<<EOF
EOF
