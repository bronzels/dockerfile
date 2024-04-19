if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Mac detected."
    #mac
    os=darwin
    MYHOME=/Volumes/data
    SED=gsed
    bin=/Users/apple/bin
else
    echo "Assuming linux by default."
    #linux
    os=linux
    MYHOME=~
    SED=sed
    bin=/usr/local/bin
fi

PRESTO_HOME=${MYHOME}/workspace/dockerfile/presto

cd ${PRESTO_HOME}

kubectl create ns trino

helm repo add trino https://trinodb.github.io/charts
helm repo update
helm search repo trino
:<<EOF
NAME            CHART VERSION   APP VERSION     DESCRIPTION                                       
trino/trino     0.19.0          432             Fast distributed SQL query engine for big data ...
EOF
while ! helm install trino trino/trino \
    --namespace trino \
    --create-namespace \
    --set persistence.storageClass=juicefs-sc; do sleep 2 ; done ; echo succeed
:<<EOF
NAME: trino
LAST DEPLOYED: Thu Apr 11 23:14:07 2024
NAMESPACE: trino
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace trino -l "app=trino,release=trino,component=coordinator" -o jsonpath="{.items[0].metadata.name}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl port-forward $POD_NAME 8080:8080
succeed
EOF

while ! helm pull trino/trino; do sleep 2 ; done ; echo succeed
tar xzvf trino-0.19.0.tgz
file=values-trino-test.yaml
cp trino/values.yaml ${file}
file=values-trino-test.yaml
cp ${file} ${file}.bk
$SED -i "s/additionalCatalogs: {}/additionalCatalogs:/g" ${file}
cat << EOF > catalogs
  mysql: |-
    connector.name=mysql
    connection-url=jdbc:mysql://mmubu:3306?useSSL=false
    connection-user=root
    connection-password=root
  postgresql: |-
    connector.name=postgresql
    connection-url=jdbc:postgresql://mmubu:2000/postgres
    connection-user=postgres
    connection-password=postgres
EOF
$SED -i "/additionalCatalogs:/r catalogs" ${file}
cd trino
\cp ../values-trino-test.yaml values.yaml
helm install trino ./ \
    --namespace trino \
    --set persistence.storageClass=juicefs-sc
helm uninstall trino -n trino
kubectl get all -n trino
kubectl port-forward -n trino $POD_NAME 8080:8080
kubectl get secret sh.helm.release.v1.trino.v1 --namespace trino -o jsonpath='{.data.password}' | base64 --decode
kubectl get pod -n trino |grep -v Running |awk '{print $1}'| xargs kubectl delete pod "$1" -n trino --force --grace-period=0

# 登录
kubectl exec -it `kubectl get pods -n trino|grep coordinator|awk '{print $1}'` -n trino -- /usr/bin/trino --server http://trino:8080 --catalog=mysql
  # 查看数据源
  show catalogs;
  SELECT * FROM system.runtime.nodes
  SHOW SCHEMAS FROM mysql;
  SELECT * FROM mysql.airbyte.cars;
  SHOW SCHEMAS FROM postgresql;
  USE postgresql.public;
  SHOW TABLES;
  SELECT * FROM postgresql.public.table_two;
  SELECT * FROM mysql.airbyte.cars cars INNER JOIN postgresql.public.table_two table_two ON cars.id = table_two.id;


