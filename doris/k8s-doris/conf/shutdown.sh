#!/bin/bash
let srvs=$1
echo "srvs:${srvs}"
FE_MYSQL_PORT=$2
echo "FE_MYSQL_PORT:${FE_MYSQL_PORT}"
FE_PVC_DIR=$3
echo "FE_PVC_DIR:${FE_PVC_DIR}"
let srvmaxno=${srvs}-1
echo "srvmaxno:${srvmaxno}"

echo "MY_POD_NAME:${MY_POD_NAME}"
if [[ "${MY_POD_NAME}" =~ "doris-be-" ]]; then
  prj="be"
  echo "DEBUG >>>>>> BE"
  eval "/opt/apache-doris/be/bin/stop_be.sh"
else
  prj="fe"
  FE_ID=`echo ${MY_POD_NAME} | sed 's/doris-fe-//g'`
  echo "FE_ID:${FE_ID}"
  cat ${FE_PVC_DIR}/common.conf

  trimmed=`mysql -u'root' -P ${FE_MYSQL_PORT} -h 127.0.0.1 -e"SHOW PROC '/frontends'" | sed 's/|//g' | grep -E "FOLLOWER[[:space:]]true" | grep -E "true[[:space:]]true"`
  ismaster=$?
  echo "trimmed:\n${trimmed}"
  gracestr=""
  rm -f ${FE_PVC_DIR}/last_time_master
  if [[ "${ismaster}" == 0 ]]; then
    arr=($trimmed)
    echo "arr:${arr[*]}"
    ip=${arr[1]}
    echo "ip:${ip}"
    echo "DEBUG >>>>>> FE leader found"
    echo "FE_IPADDRESS:${FE_IPADDRESS}"
    if [[ ${FE_IPADDRESS} == "${ip}" ]]; then
      ls -l ${FE_PVC_DIR}/
      touch ${FE_PVC_DIR}/last_time_master
      ls -l ${FE_PVC_DIR}/
      echo "DEBUG >>>>>> is FE leader, stop it and ignore others to prevent metadata corruption for later doris cluster to reboot with data kept in PVCs restored successfully"
      eval "/opt/apache-doris/fe/bin/stop_fe.sh --grace"
      #gracestr=" --grace"
    else
      echo "DEBUG >>>>>> is not FE leader"
    fi
  else
    echo "DEBUG >>>>>> FE leader not found, maybe cluster is unhealthy, risk no stop at all"
  fi
  #eval "/opt/apache-doris/fe/bin/stop_fe.sh${gracestr}"
fi

