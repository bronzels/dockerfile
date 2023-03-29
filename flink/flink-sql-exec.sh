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

FLINK_FILE_HOME=/opt/flink/usrlib
session=$1
torun=$2

set -e
kubectl exec -it -n flink `kubectl get pod -n flink | grep ${session} | grep -v taskmanager | awk '{print $1}'` -- cat usrlib/${torun}

kubectl exec -it -n flink `kubectl get pod -n flink | grep ${session} | grep -v taskmanager | awk '{print $1}'` -- sql-client.sh embedded -i usrlib/setting.sql -f usrlib/${torun}

