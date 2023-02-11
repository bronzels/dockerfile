#!/bin/bash
let srvs=$1
echo "srvs:${srvs}"
FE_MYSQL_PORT=$2
echo "FE_MYSQL_PORT:${FE_MYSQL_PORT}"
let srvmaxno=${srvs}-1
echo "srvmaxno:${srvmaxno}"

echo "MY_POD_NAME:${MY_POD_NAME}"
if [[ "${MY_POD_NAME}" =~ "doris-be-" ]]; then
  prj="be"
  echo "DEBUG >>>>>> BE, do nothing"
else
  prj="fe"
  FE_ID=`echo ${MY_POD_NAME} | sed 's/doris-fe-//g'`
  echo "FE_ID:${FE_ID}"

  iparr=()
  for num in `seq 0 ${srvmaxno}`
  do
    iparr[num]=0
  done
  echo "iparr:${iparr[*]}"

  trimmed=`mysql -u'root' -P ${FE_MYSQL_PORT} -h fe-service -e"SHOW PROC '/frontends'" | sed 's/|//g' | grep -E "FOLLOWER[[:space:]]true" | grep -E "true[[:space:]]true"`
  ismaster=$?
  echo "trimmed:\n${trimmed}"
  if [[ "${ismaster}" == 0 ]]; then
    arr=($trimmed)
    echo "arr:${arr[*]}"
    ip=${arr[1]}
    echo "ip:${ip}"
    if [[ -n $ip ]]; then
      echo "DEBUG >>>>>> FE leader found, FE_MASTER_ID:${FE_MASTER_ID}"
      echo "FE_IPADDRESS:${FE_IPADDRESS}"
      if [[ ${FE_IPADDRESS} == "${ip}" ]]; then
        echo "DEBUG >>>>>> is FE leader, stop it and ignore others to prevent metadata corruption for later doris cluster to reboot with data kept in PVCs restored successfully"
        date +"%s.%9N"
        /opt/apache-doris/fe/bin/stop_fe.sh --grace
        date +"%s.%9N"
      else
        echo "DEBUG >>>>>> is not FE leader, do nothing"
      fi
    else
      echo "DEBUG >>>>>> FE leader not found, unknow script internal error, risk no stop at all"
    fi
  else
    echo "DEBUG >>>>>> FE leader not found, maybe cluster is unhealthy, risk no stop at all"
  fi
fi

