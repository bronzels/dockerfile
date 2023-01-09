if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Mac detected."
    #mac
    MVNREPOHOME=/Volumes/data/m2/repository
    SED=gsed
else
    echo "Assuming linux by default."
    #linux
    MVNREPOHOME=~/m2repository
    SED=sed
fi

#SPARK_VERSION=3.3.0
SPARK_VERSION=3.3.1
HADOOP_VERSION=3.2.1
HIVEREV=3.1.2
wget -c https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz
docker build ./ --progress=plain --build-arg SPARK_VERSION="${SPARK_VERSION}" --build-arg HADOOP_VERSION="${HADOOP_VERSION}" --build-arg HIVEREV="${HIVEREV}" -t harbor.my.org:1080/bronzels/spark-hadoop-${HADOOP_VERSION}-juicefs:${SPARK_VERSION}
docker push harbor.my.org:1080/bronzels/spark-hadoop-${HADOOP_VERSION}-juicefs:${SPARK_VERSION}

mv ../spark-${SPARK_VERSION}-bin-hadoop3.tgz ./
docker build ./ -f Dockerfile.min --progress=plain --build-arg SPARK_VERSION="${SPARK_VERSION}" --build-arg HADOOP_VERSION="${HADOOP_VERSION}" --build-arg HIVEREV="${HIVEREV}" -t harbor.my.org:1080/bronzels/spark-juicefs:${SPARK_VERSION}
docker push harbor.my.org:1080/bronzels/spark-juicefs:${SPARK_VERSION}

mv ./spark-${SPARK_VERSION}-bin-hadoop3.tgz ../
cp ../image/sources-22.04.list sources.list
#docker build ./ -f Dockerfile.tpc --progress=plain --build-arg SPARK_VERSION="${SPARK_VERSION}" -t harbor.my.org:1080/bronzels/spark-juicefs-tpc:${SPARK_VERSION}
docker build ./ -f Dockerfile.tpc --progress=plain -t harbor.my.org:1080/bronzels/spark-juicefs-tpc:${SPARK_VERSION}
docker push harbor.my.org:1080/bronzels/spark-juicefs-tpc:${SPARK_VERSION}

helm repo add spark-operator https://googlecloudplatform.github.io/spark-on-k8s-operator

#helm install my spark-operator/spark-operator --namespace spark-operator --create-namespace --set image.tag=v1beta2-1.3.3-3.1.1
helm install my spark-operator/spark-operator \
  --namespace spark-operator --create-namespace \
  --set image.repository=registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-spark-operator-spark-operator-v1beta2-1.3.0-3.1.1 \
  --set image.tag=1.0

#gcr.io/spark-operator/spark-operator:v1beta2-1.3.3-3.1.1
#registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-spark-operator-spark-operator-v1beta2-1.3.3-3.1.1:

#gcr.io/spark-operator/spark-operator:v1beta2-1.3.2-3.1.1
#registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-spark-operator-spark-operator-v1beta2-1.3.2-3.1.1:

#gcr.io/spark-operator/spark-operator:v1beta2-1.3.0-3.1.1
#registry.cn-hangzhou.aliyuncs.com/bronzels/gcr.io-spark-operator-spark-operator-v1beta2-1.3.0-3.1.1:

#docker
ansible all -m shell -a"docker images|grep spark-juicefs"
ansible all -m shell -a"docker images|grep spark-juicefs|awk '{print \$3}'|xargs docker rmi -f"
#containerd
ansible all -m shell -a"crictl images|grep spark-juicefs"
ansible all -m shell -a"crictl images|grep spark-juicefs|awk '{print \$3}'|xargs crictl rmi"

kubectl apply -f app-pi-nfs-pvc.yaml -n spark-operator
kubectl apply -f app-pi.yaml -n spark-operator
kubectl delete -f app-pi.yaml -n spark-operator

kubectl apply -f clusterrole-endpoints-reader.yaml
kubectl create clusterrolebinding endpoints-reader-default \
  --clusterrole=endpoints-reader  \
  --serviceaccount=spark-operator:default

kubectl apply -f spark-test.yaml -n spark-operator
kubectl delete -f spark-test.yaml -n spark-operator
kubectl exec -it spark-test -n spark-operator -- /bin/bash
  echo "use tpcds_bin_partitioned_orc_10" > dbuse.sql

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
    --conf spark.executor.memory=16g \
    --conf spark.kubernetes.executor.request.cores=1 \
    --conf spark.kubernetes.executor.limit.cores=3 \
    -i dbuse.sql \
    -f spark-queries-tpcds/q1.sql
#   -f /app/hdfs/spark/work-dir/test.sql
  end=$(date +"%s.%9N")
  echo timediff:`echo "scale=9;$end - $start" | bc`
:<<EOF
23/01/08 13:38:48 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
Setting default log level to "WARN".
To adjust logging level use sc.setLogLevel(newLevel). For SparkR, use setLogLevel(newLevel).
Spark master: k8s://https://kubernetes.default.svc.cluster.local:443, Application Id: spark-eef11d1254d747ba919c78e0a8f8ed33

Time taken: 20.619 seconds, Fetched 100 row(s)
23/01/08 13:39:42 WARN ExecutorPodsWatchSnapshotSource: Kubernetes client has been closed.
timediff:56.016297846
EOF

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
    --conf spark.dynamicAllocation.initialExecutors=3 \
    --conf spark.dynamicAllocation.minExecutors=1 \
    --conf spark.dynamicAllocation.shuffleTracking.enabled=true \
    --conf spark.dynamicAllocation.executorIdleTimeout=60s \
	  -i dbuse.sql \
    -f spark-queries-tpcds/q1.sql
#   -f /app/hdfs/spark/work-dir/test.sql
  end=$(date +"%s.%9N")
  echo timediff:`echo "scale=9;$end - $start" | bc`
:<<EOF
23/01/08 13:43:52 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
Setting default log level to "WARN".
To adjust logging level use sc.setLogLevel(newLevel). For SparkR, use setLogLevel(newLevel).
23/01/08 13:43:54 WARN Utils: spark.executor.instances less than spark.dynamicAllocation.minExecutors is invalid, ignoring its setting, please update your configs.
23/01/08 13:43:54 WARN Utils: spark.executor.instances less than spark.dynamicAllocation.minExecutors is invalid, ignoring its setting, please update your configs.
Spark master: k8s://https://kubernetes.default.svc.cluster.local:443, Application Id: spark-3344e754d26f4c1ea5de09bd947ea832

Time taken: 32.648 seconds, Fetched 100 row(s)
23/01/08 13:44:32 WARN ExecutorPodsWatchSnapshotSource: Kubernetes client has been closed.
timediff:43.783524359
EOF

kubectl apply -f spark-sql-job-test.yaml -n spark-operator
:<<EOF
            - name: SPARK_KUBERNETES_EXECUTOR_REQUEST_CORES
              value: "500m"
            - name: SPARK_KUBERNETES_EXECUTOR_LIMIT_CORES
              value: "1000m"
  --conf spark_kubernetes_executor_request_cores=${SPARK_KUBERNETES_EXECUTOR_REQUEST_CORES} \
  --conf spark_kubernetes_executor_limit_cores=${SPARK_KUBERNETES_EXECUTOR_LIMIT_CORES} \
container_image:harbor.my.org:1080/bronzels/spark-juicefs-tpc:3.3.1
setting_sql_file:dbuse.sql
execute_sql_file:spark-queries-tpcds/q1.sql
Warning: Ignoring non-Spark config property: spark_kubernetes_executor_request_cores
Warning: Ignoring non-Spark config property: spark_kubernetes_executor_limit_cores
23/01/09 11:30:30 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
Setting default log level to "WARN".
To adjust logging level use sc.setLogLevel(newLevel). For SparkR, use setLogLevel(newLevel).
23/01/09 11:30:33 WARN Utils: spark.executor.instances less than spark.dynamicAllocation.minExecutors is invalid, ignoring its setting, please update your configs.
23/01/09 11:30:33 WARN Utils: spark.executor.instances less than spark.dynamicAllocation.minExecutors is invalid, ignoring its setting, please update your configs.
Spark master: k8s://https://kubernetes.default.svc.cluster.local:443, Application Id: spark-61a692c43f124b4986f601395b58adab

Time taken: 28.632 seconds, Fetched 100 row(s)
23/01/09 11:31:31 WARN ExecutorPodsWatchSnapshotSource: Kubernetes client has been closed.
timediff:63.703939564


container_image:harbor.my.org:1080/bronzels/spark-juicefs-tpc:3.3.1
setting_sql_file:dbuse.sql
execute_sql_file:spark-queries-tpcds/q1.sql
Warning: Ignoring non-Spark config property: spark_kubernetes_executor_request_cores
Warning: Ignoring non-Spark config property: spark_kubernetes_executor_limit_cores
23/01/09 12:05:59 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
Setting default log level to "WARN".
To adjust logging level use sc.setLogLevel(newLevel). For SparkR, use setLogLevel(newLevel).
23/01/09 12:06:02 WARN Utils: spark.executor.instances less than spark.dynamicAllocation.minExecutors is invalid, ignoring its setting, please update your configs.
23/01/09 12:06:02 WARN Utils: spark.executor.instances less than spark.dynamicAllocation.minExecutors is invalid, ignoring its setting, please update your configs.
Spark master: k8s://https://kubernetes.default.svc.cluster.local:443, Application Id: spark-a9017575774b417c8c9b8686f8c670e1

Time taken: 24.262 seconds, Fetched 100 row(s)
23/01/09 12:06:31 WARN ExecutorPodsWatchSnapshotSource: Kubernetes client has been closed.
timediff:35.618597369
EOF
:<<EOF
container_image:harbor.my.org:1080/bronzels/spark-juicefs-tpc:3.3.1
setting_sql_file:dbuse.sql
execute_sql_file:spark-queries-tpcds/q1.sql
23/01/09 11:38:41 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
Setting default log level to "WARN".
To adjust logging level use sc.setLogLevel(newLevel). For SparkR, use setLogLevel(newLevel).
23/01/09 11:38:43 WARN Utils: spark.executor.instances less than spark.dynamicAllocation.minExecutors is invalid, ignoring its setting, please update your configs.
23/01/09 11:38:44 WARN Utils: spark.executor.instances less than spark.dynamicAllocation.minExecutors is invalid, ignoring its setting, please update your configs.
Spark master: k8s://https://kubernetes.default.svc.cluster.local:443, Application Id: spark-3d299e5b1f8f493fac63920766945156
Time taken: 24.336 seconds, Fetched 100 row(s)

23/01/09 11:39:29 WARN ExecutorPodsWatchSnapshotSource: Kubernetes client has been closed.
timediff:51.228572458

container_image:harbor.my.org:1080/bronzels/spark-juicefs-tpc:3.3.1
setting_sql_file:dbuse.sql
execute_sql_file:spark-queries-tpcds/q1.sql
23/01/09 11:57:51 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
Setting default log level to "WARN".
To adjust logging level use sc.setLogLevel(newLevel). For SparkR, use setLogLevel(newLevel).
23/01/09 11:57:53 WARN Utils: spark.executor.instances less than spark.dynamicAllocation.minExecutors is invalid, ignoring its setting, please update your configs.
23/01/09 11:57:53 WARN Utils: spark.executor.instances less than spark.dynamicAllocation.minExecutors is invalid, ignoring its setting, please update your configs.
Spark master: k8s://https://kubernetes.default.svc.cluster.local:443, Application Id: spark-96e8a7fd9131493c99a0bfa1d83fc520

Time taken: 25.44 seconds, Fetched 100 row(s)
23/01/09 11:58:24 WARN ExecutorPodsWatchSnapshotSource: Kubernetes client has been closed.
timediff:36.953211027
EOF

kubectl port-forward spark-sql-job-test-qhgk9 4040:4040 &

kubectl apply -f rss-juicefs-pvc.yaml -n spark-operator

cat << \EOF > rss-juicefs-pvc-test-pod.yaml
kind: Pod
apiVersion: v1
metadata:
  name: test-pod
spec:
  containers:
  - name: test-pod
    image: busybox:1.24
    command:
      - "/bin/sh"
    args:
      - "-c"
      - "echo 'success' > /mnt/SUCCESS && exit 0 || exit 1"
    volumeMounts:
      - name: juicefs-pvc
        mountPath: "/mnt"
  restartPolicy: "Never"
  volumes:
    - name: juicefs-pvc
      persistentVolumeClaim:
        claimName: rss-juicefs-pvc
EOF
kubectl apply -f rss-juicefs-pvc-test-pod.yaml -n spark-operator
kubectl delete -f rss-juicefs-pvc-test-pod.yaml -n spark-operator

:<<EOF
  --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.options.claimName=rss-juicefs-pvc \
  --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.options.sizeLimit=4Gi \
  --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.mount.path=/data \
  --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.mount.readOnly=false \

      volumes:
        - name: juicefs-pv
          persistentVolumeClaim:
            claimName: rss-juicefs-pvc

container_image:harbor.my.org:1080/bronzels/spark-juicefs-tpc:3.3.1
setting_sql_file:dbuse.sql
execute_sql_file:spark-queries-tpcds/q1.sql
Warning: Ignoring non-Spark config property: spark_kubernetes_executor_request_cores
Warning: Ignoring non-Spark config property: spark_kubernetes_executor_limit_cores
23/01/09 13:34:58 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
Setting default log level to "WARN".
To adjust logging level use sc.setLogLevel(newLevel). For SparkR, use setLogLevel(newLevel).
23/01/09 13:35:00 WARN Utils: spark.executor.instances less than spark.dynamicAllocation.minExecutors is invalid, ignoring its setting, please update your configs.
23/01/09 13:35:01 WARN Utils: spark.executor.instances less than spark.dynamicAllocation.minExecutors is invalid, ignoring its setting, please update your configs.
Spark master: k8s://https://kubernetes.default.svc.cluster.local:443, Application Id: spark-2fd4ffea95234cb29c1f15ecf6c272ef

Time taken: 26.506 seconds, Fetched 100 row(s)
23/01/09 13:35:32 WARN ExecutorPodsWatchSnapshotSource: Kubernetes client has been closed.
timediff:37.827658118

setting_sql_file:dbuse.sql
execute_sql_file:spark-queries-tpcds/q1.sql
Warning: Ignoring non-Spark config property: spark_kubernetes_executor_request_cores
Warning: Ignoring non-Spark config property: spark_kubernetes_executor_limit_cores
23/01/09 13:37:23 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
Setting default log level to "WARN".
To adjust logging level use sc.setLogLevel(newLevel). For SparkR, use setLogLevel(newLevel).
23/01/09 13:37:25 WARN Utils: spark.executor.instances less than spark.dynamicAllocation.minExecutors is invalid, ignoring its setting, please update your configs.
23/01/09 13:37:26 WARN Utils: spark.executor.instances less than spark.dynamicAllocation.minExecutors is invalid, ignoring its setting, please update your configs.
Spark master: k8s://https://kubernetes.default.svc.cluster.local:443, Application Id: spark-52d46a2054654875a91f42b5e851ba0c

Time taken: 25.594 seconds, Fetched 100 row(s)
23/01/09 13:37:56 WARN ExecutorPodsWatchSnapshotSource: Kubernetes client has been closed.
timediff:36.765423572
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
EOF