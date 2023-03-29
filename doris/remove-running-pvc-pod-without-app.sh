#!/bin/bash

podstr=`kubectl get pod -n kube-system | grep juicefs | grep pvc | awk '{print $1}'`
OLD_IFS="$IFS"
IFS=" "
podarr=($podstr)
IFS="$OLD_IFS"
for podname in ${podarr[*]}
do
  echo "---Debug, pvc podname:$podname"
  appname=`./csi-doctor.sh get-app $podname`
  if [[ -z ${appname} ]]; then
    echo "---Debug, no app for this running pvc pod, removed"
    #kubectl get pod -n kube-system | grep $podname | awk '{print $1}' | xargs kubectl delete pod -n kube-system --force --grace-period=0
    kubectl get pod -n kube-system | grep $podname | awk '{print $1}' | xargs kubectl patch pod $1 -n kube-system -p '{"metadata":{"finalizers":null}}'
  else
    echo "---Debug, app for this running pvc pod:"
    echo ${appname}
  fi
  echo "---Debug, -----------------------------"
done  
