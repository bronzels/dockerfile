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

SQL_FILE_HOME=$1
HDFS_SQL_FILE_HOME=$2
torun=$3

kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- \
  hadoop fs -rm -r -f ${HDFS_SQL_FILE_HOME}/${torun}
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- \
  hadoop fs -mkdir ${HDFS_SQL_FILE_HOME}/${torun}
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- \
  rm -rf ${SQL_FILE_HOME}/${torun}
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- \
  mkdir ${SQL_FILE_HOME}/${torun}
