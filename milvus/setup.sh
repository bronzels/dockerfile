#1. 拉取源码：
git clone -b 0.10.0 https://github.com/milvus-io/milvus-helm.git

#2. 部署 Milvus：
cd milvus-helm/charts/milvus
cp values.yaml values.yaml.bk
#将 Milvus Server Configuration 部分的 service.type 修改为 NodePort。
:<<\EOF
## Expose the Milvus service to be accessed from outside the cluster (LoadBalancer service).
## or access it from within the cluster (ClusterIP service). Set the service type and the port to serve it.
## ref: http://kubernetes.io/docs/user-guide/services/
##
service:
  type: NodePort
  port: 19530
  nodePort: 30502
  annotations: {}
  labels: {}
EOF

kubectl create ns vector
helm install mymv -n vector --set cluster.enabled=true --set persistence.enabled=true --set mysql.enabled=true .
#helm uninstall mymv -n vector
#kubectl delete pvc data-mymv-etcd-0 -n vector
#kubectl get pvc -n vector
kubectl get pod -n vector
kubectl get svc -n vector

mkdir -p /home/milvus/volumes/etcd
mkdir -p /home/milvus/volumes/minio
mkdir -p /home/milvus/volumes/milvus
:<<\EOF
CPU需要支持以下指令集中的任意一个
SSE4.2
AVX
AVX2
AVX512
EOF
lscpu | grep -e sse4_2 -e avx -e avx2 -e avx512

wget -c https://github.com/milvus-io/milvus/releases/download/v2.4.10/milvus-standalone-docker-compose.yml
#修改DOCKER_VOLUME_DIRECTORY指向固定目录
export MYMILVUS_HOME=/home/milvus

docker compose -f milvus-standalone-docker-compose.yml up -d
#while ! docker compose -f milvus-standalone-docker-compose.yml up -d; do sleep 2 ; done ; echo succeed
docker run -d \
--restart=always \
--name=attu \
-p 8003:3000 \
-e MILVUS_URL=192.168.3.14:19530 \
zilliz/attu:v2.3.1

git clone git@github.com:milvus-io/bootcamp
mkdir ~/.kaggle
mv /workspace/dockerfile/milvus/kaggle.json ~/.kaggle/

export KAGGLE_USERNAME=bronzels
export KAGGLE_KEY=7ca32efd0cee4ee48cb62016944eb3fd
export TOKENIZERS_PARALLELISM=true

import kaggle dependency
import kaggle
kaggle.api.authenticate()
kaggle.api.dataset_download_files('rounakbanik/the-movies-dataset', path='dataset', unzip=True)

pip install sentence_transformers
