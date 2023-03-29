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

NS=$1
NAME=$2
FILE_HOME=$3
fullpath=$4
torun=`basename ${fullpath}`
NONAME=$5

set -e
if [[ -f ${torun} && -d ${torun} ]]; then
  echo "neither file nor folder"
  exit 1
fi

if [[ -z ${NONAME} ]]; then
  if [[ -f ${fullpath} ]]; then
    kubectl exec -it -n ${NS} `kubectl get pod -n ${NS} | grep ${NAME} | awk '{print $1}'` -- rm -f ${FILE_HOME}/${torun}
    kubectl cp ${fullpath} -n ${NS} `kubectl get pod -n ${NS} | grep ${NAME} | awk '{print $1}'`:${FILE_HOME}/${torun}
    kubectl exec -it -n ${NS} `kubectl get pod -n ${NS} | grep ${NAME} | awk '{print $1}'` -- cat ${FILE_HOME}/${torun}
  else
    kubectl exec -it -n ${NS} `kubectl get pod -n ${NS} | grep ${NAME} | awk '{print $1}'` -- rm -rf ${FILE_HOME}/${torun}
    kubectl cp ${torun} -n ${NS} `kubectl get pod -n ${NS} | grep ${NAME} | awk '{print $1}'`:${FILE_HOME}/${torun}
    kubectl exec -it -n ${NS} `kubectl get pod -n ${NS} | grep ${NAME} | awk '{print $1}'` -- ls -l ${FILE_HOME}/${torun}
  fi
else
  if [[ -f ${fullpath} ]]; then
    kubectl exec -it -n ${NS} `kubectl get pod -n ${NS} | grep ${NAME} | grep -v ${NONAME} | awk '{print $1}'` -- rm -f ${FILE_HOME}/${torun}
    kubectl cp ${fullpath} -n ${NS} `kubectl get pod -n ${NS} | grep ${NAME} | grep -v ${NONAME} | awk '{print $1}'`:${FILE_HOME}/${torun}
    kubectl exec -it -n ${NS} `kubectl get pod -n ${NS} | grep ${NAME} | grep -v ${NONAME} | awk '{print $1}'` -- cat ${FILE_HOME}/${torun}
  else
    kubectl exec -it -n ${NS} `kubectl get pod -n ${NS} | grep ${NAME} | grep -v ${NONAME} | awk '{print $1}'` -- rm -rf ${FILE_HOME}/${torun}
    kubectl cp ${torun} -n ${NS} `kubectl get pod -n ${NS} | grep ${NAME} | grep -v ${NONAME} | awk '{print $1}'`:${FILE_HOME}/${torun}
    kubectl exec -it -n ${NS} `kubectl get pod -n ${NS} | grep ${NAME} | grep -v ${NONAME} | awk '{print $1}'` -- ls -l ${FILE_HOME}/${torun}
  fi
fi