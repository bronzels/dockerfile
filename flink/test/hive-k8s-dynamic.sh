#!/bin/bash
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

FLINK_HOME=${PRJ_HOME}/flink

FLINK_VERSION=1.15.3
FLINK_SHORT_VERSION=1.15
FLINKOP_VERSION=1.3.1



kubectl get pod -n flink
watch kubectl get pod -n flink

kubectl apply -f flink-test.yaml -n flink
kubectl delete -f flink-test.yaml -n flink
kubectl delete pod flink-test -n flink --force --grace-period=0


ansible all -m shell -a"crictl images|grep spark-juicefs|awk '{print \$3}'|xargs crictl rmi"

kubectl exec -it -n flink `kubectl get pod -n flink | grep flink-test | awk '{print $1}'` -- bash

