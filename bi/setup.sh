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

WORK_HOME=${MYHOME}/workspace
PRJ_HOME=${WORK_HOME}/dockerfile

BI_PRJ_HOME=${PRJ_HOME}/bi

DATAEASE_REV=1.18.5

DATART_REV=master

export PATH=$PATH:${BI_PRJ_HOME}

cd ${BI_PRJ_HOME}

kubectl create ns integrate

# dataease start--------------------------------------------
wget -c https://github.com/dataease/dataease/archive/refs/tags/v${DATAEASE_REV}.tar.gz
tar xzvf v${DATAEASE_REV}.tar.gz
cd dataease-${DATAEASE_REV}
mvn clean install -DskipTests -Dmaven.test.skip=true -Dspotless.check.skip=true -T 1C -Dmaven.javadoc.skip=true -Dcheckstyle.skip=true -Dlicense.skip=true 
[ERROR] Failed to execute goal on project backend: Could not resolve dependencies for project io.dataease:backend:jar:1.18.5: The following artifacts could not be resolved: pentaho-kettle:kettle-core:jar:8.3.0.18-1112, pentaho-kettle:kettle-engine:jar:8.3.0.18-1112, pentaho:metastore:jar:8.3.0.18-1112, org.pentaho.di.plugins:pdi-engine-configuration-impl:jar:8.3.0.7-683: Could not find artifact pentaho-kettle:kettle-core:jar:8.3.0.18-1112 in nexus-tencentyun (http://mirrors.cloud.tencent.com/nexus/repository/maven-public/)

:<<EOF
wget -c https://cdn0-download-offline-installer.fit2cloud.com/dataease/dataease-v1.18.5-offline.tar.gz?Expires=1683251299&OSSAccessKeyId=LTAI5tLEMt8jTT4RDrZ9mXns&Signature=AC46lPoq4rwpcyA9g9JDbbNaWhk%3D
tar xzvf dataease-v1.18.5-offline.tar.gz
gunzip dataease-v1.18.5-offline/images/dataease:v1.18.5.tar.gz
EOF

echo -n 'dataease@1234' | base64
echo 'ZGF0YWVhc2VAMTIzNA=='|base64 --decode

echo -n 'DataEase@123456' | base64
echo 'RGF0YUVhc2VAMTIzNDU2'|base64 --decode
#初始化密码设置不生效

git clone git@github.com:mfanoffice/dataease-helm.git
cd dataease-helm
#删除doris/mysql/redis相关内容，复用已经安装好的组件
helm install myde -n integrate -f values.yaml \
  --set ingress.enabled=false \
  --set common.storageClass=local-path \
  --set DataEase.imageTag=v${DATAEASE_REV} \
  --set common.dataease.host=dataease \
  --set redis.host=my-redis-master.redis.svc.cluster.local \
  --set redis.password=redis \
  --set redis.database=3 \
  ./
:<<EOF
NAME: myde
LAST DEPLOYED: Thu Apr  6 08:38:31 2023
NAMESPACE: integrate
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thanks for installing the DataEase.

Default username/password for DataEase is admin/dataease
EOF
helm uninstall myde -n integrate
kubectl get pod -n integrate | grep dataease | grep -v Running |awk '{print $1}'| xargs kubectl delete pod "$1" -n integrate --force --grace-period=0
kubectl get pvc -n integrate | grep dataease | awk '{print $1}' | xargs kubectl delete pvc -n integrate
kubectl exec -it -n mysql `kubectl get pod -n mysql | grep Running | awk '{print $1}'` -- mysql -h127.0.0.1 -uroot -p123456 -e"DROP DATABASE dataease"
kubectl exec -it -n mysql `kubectl get pod -n mysql | grep Running | awk '{print $1}'` -- mysql -h127.0.0.1 -uroot -p123456 -e"DROP USER dataease"
kubectl exec -it -n mysql `kubectl get pod -n mysql | grep Running | awk '{print $1}'` -- mysql -h127.0.0.1 -uroot -p123456 -e"SHOW DATABASES"
kubectl exec -it -n mysql `kubectl get pod -n mysql | grep Running | awk '{print $1}'` -- mysql -h127.0.0.1 -uroot -p123456 -e"SELECT @@max_allowed_packet"
kubectl exec -it -n redis `kubectl get pod -n redis | grep Running | awk '{print $1}'` -- bash
  REDISCLI_AUTH=redis redis-cli -n 3 del check_ds::hide_custom_ds

kubectl get all -n integrate
watch kubectl get all -n integrate

kubectl describe pod -n integrate `kubectl get pod -n integrate |grep dataease |awk '{print $1}'`

kubectl logs -n integrate `kubectl get pod -n integrate |grep dataease |awk '{print $1}'` init-database
kubectl logs -f -n integrate `kubectl get pod -n integrate |grep dataease |awk '{print $1}'` init-database
kubectl logs -n integrate `kubectl get pod -n integrate |grep dataease |awk '{print $1}'` dataease
kubectl logs -f -n integrate `kubectl get pod -n integrate |grep dataease |awk '{print $1}'` dataease

kubectl exec -it -n flink `kubectl get pod -n integrate |grep dataease | grep Running | awk '{print $1}'` -c dataease -- bash

kubectl exec -it -n mysql `kubectl get pod -n mysql | grep Running | awk '{print $1}'` -- mysql -h127.0.0.1 -udataease -pdataease@1234 -e"SHOW DATABASES"
kubectl exec -it -n mysql `kubectl get pod -n mysql | grep Running | awk '{print $1}'` -- mysql -h127.0.0.1 -udataease -pdataease@1234 -e"USE dataease;SHOW TABLES"
kubectl exec -it -n mysql `kubectl get pod -n mysql | grep Running | awk '{print $1}'` -- mysql -h127.0.0.1 -udataease -pdataease@1234 -e"USE dataease;SELECT * FROM QRTZ_LOCKS"

# dataease end--------------------------------------------


# datart start--------------------------------------------


# datart end--------------------------------------------

