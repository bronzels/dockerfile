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
