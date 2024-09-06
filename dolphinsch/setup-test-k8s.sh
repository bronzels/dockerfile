
helm repo add pfisterer-hadoop https://pfisterer.github.io/apache-hadoop-helm/
helm install hadoop -n hadoop \
 pfisterer-hadoop/hadoop \
 --create-namespace
helm pull pfisterer-hadoop/hadoop
cd hadoop
kubectl create ns hadoop
helm install hadoop -n hadoop ./ \
  --create-namespace 

cd ${MYDOLPHINSCH_HOME}/apache-dolphinscheduler-${DOLPHINSCH_REV}-src
cd deploy/kubernetes/dolphinscheduler
while ! helm repo add bitnami https://charts.bitnami.com/bitnami; do sleep 2 ; done ; echo succeed
helm repo list| grep http >> ../helm_repos.txt
helm repo list| grep http | awk '{print $1}' | grep -v bitnami | xargs 
helm repo remove
while ! helm dependency build .; do sleep 2 ; done ; echo succeed
file=values.yaml
cp ${file} ${file}.bk
:<<EOF
master:
  replicas: "3"
  ->
  replicas: "1"
worker:
  replicas: "3"
  ->
  replicas: "1"
conf:
  common:
    resource.hdfs.root.user: hdfs
    resource.hdfs.fs.defaultFS: hdfs://mycluster:8020
    resource.storage.type: S3
    ->
    resource.hdfs.root.user: root
    resource.hdfs.fs.defaultFS: hdfs://hadoop-hadoop-hdfs-nn.hadoop:9000
    resource.storage.type: HDFS
EOF
#while ! helm install dolphinsch -n dolphinsch bitnami/dolphinscheduler --create-namespace; do sleep 2 ; done ; echo succeed
helm install dolphinscheduler . --set image.tag=3.2.1 -n dolphinsch --create-namespace