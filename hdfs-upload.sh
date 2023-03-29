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
fullpath=$1
torun=`basename ${fullpath}`

set -e
if [[ -f ${torun} && -d ${torun} ]]; then
  echo "neither file nor folder"
  exit 1
fi

if [[ -f ${fullpath} ]]; then
  kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- \
    rm -f ${SQL_FILE_HOME}/${torun}
  kubectl cp ${fullpath} -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'`:${SQL_FILE_HOME}/${torun}
  kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- \
    hadoop fs -rm -f ${HDFS_SQL_FILE_HOME}/${torun}
  kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- \
    hadoop fs -put ${torun} ${HDFS_SQL_FILE_HOME}/${torun}
  kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- \
    hadoop fs -cat ${HDFS_SQL_FILE_HOME}/${torun}
else
  kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- \
    rm -rf ${SQL_FILE_HOME}/${torun}
  kubectl cp ${fullpath} -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'`:${SQL_FILE_HOME}/${torun}
  kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- \
    hadoop fs -rm -r -f ${HDFS_SQL_FILE_HOME}/${torun}
  kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- \
    hadoop fs -put ${torun} ${HDFS_SQL_FILE_HOME}/${torun}
  kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- \
    hadoop fs -ls ${HDFS_SQL_FILE_HOME}/${torun}
fi

