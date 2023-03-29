#!/usr/bin/env bash
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

WORK_HOME=${MYHOME}/workspace
PRJ_HOME=${WORK_HOME}/dockerfile

PRJ_FLINK_HOME=${PRJ_HOME}/flink

MYSQL_VERSION_2BUILD=5.7.28
#MYSQL_VERSION_2BUILD=8.0.28

#安装
kubectl create ns mysql

:<<EOF
kubectl create cm init-config -n mysql --from-file=docker-entrypoint-initdb.d
kubectl delete cm init-config -n mysql
EOF

echo -n 123456 | base64
kubectl apply -f yaml/mysql-pvc.yaml -n mysql
kubectl apply -f yaml/mysql-config.yaml -n mysql
kubectl apply -f yaml/mysql-deploy.yaml -n mysql

kubectl get all -n mysql
watch kubectl get pod -n mysql
kubectl get pod -n mysql

kubectl get pvc -n mysql
kubectl get pv | grep local-path | grep mysql

kubectl describe pod -n mysql `kubectl get pod -n mysql |grep mysql |awk '{print $1}'`

kubectl logs -n mysql `kubectl get pod -n mysql |grep mysql |awk '{print $1}'`
kubectl logs -n mysql `kubectl get pod -n mysql |grep mysql |grep Running |awk '{print $1}'`

kubectl logs -f -n mysql `kubectl get pod -n mysql |grep mysql |grep Running |awk '{print $1}'`

#卸载
kubectl delete -f yaml/mysql-deploy.yaml -n mysql
kubectl delete -f yaml/mysql-config.yaml -n mysql
kubectl delete -f yaml/mysql-pvc.yaml -n mysql

kubectl get pod -n mysql |grep -v Running |awk '{print $1}'| xargs kubectl delete pod "$1" -n mysql --force --grace-period=0

kubectl exec -it -n mysql `kubectl get pod -n mysql | grep Running | awk '{print $1}'` -- bash
  echo ${MYSQL_ROOT_PASSWORD}
  mysql -h127.0.0.1 -uroot -p123456 -e"SHOW DATABASES"
