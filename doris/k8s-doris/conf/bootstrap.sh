#!/bin/bash
let srvs=$1
echo "srvs:${srvs}"
be_heartbeat_port=$2
echo "be_heartbeat_port:${be_heartbeat_port}"
FE_MYSQL_PORT=$3
echo "FE_MYSQL_PORT:${FE_MYSQL_PORT}"
EDIT_LOG_PORT=$4
echo "EDIT_LOG_PORT:${EDIT_LOG_PORT}"
let srvmaxno=${srvs}-1
echo "srvmaxno:${srvmaxno}"

echo "MY_POD_NAME:${MY_POD_NAME}"
if [[ "${MY_POD_NAME}" =~ "doris-be-" ]]; then
  prj="be"
  BE_ADDR=${BE_IPADDRESS}:${be_heartbeat_port}
  echo "BE_ADDR:${BE_ADDR}"
else
  prj="fe"
  FE_ID=`echo ${MY_POD_NAME} | sed 's/doris-fe-//g'`
  echo "FE_ID:${FE_ID}"
fi
echo "prj:${prj}"

FE_SERVERS=""
iparr=()
for num in `seq 0 ${srvmaxno}`
do
  iparr[num]=0
  echo "num:$num"
  if [[ $num -eq 0 ]]; then
    prefix=""
  else
    prefix=","
  fi
  numstr="doris-fe-${num}.fe-service:${EDIT_LOG_PORT}"
  FE_SERVERS=${FE_SERVERS}${prefix}${numstr}
done
echo "FE_SERVERS:${FE_SERVERS}"

declare -A map_ip2num=()
let pinged=0
echo ping all fe to get ip/num map
until [[ pinged -eq srvs ]]
do
  sleep 1
  for num in `seq 0 ${srvmaxno}`
  do
    if [[ ${iparr[num]} == 1 ]]; then
      continue
    fi
    lookup_rst=(`nslookup -sil doris-fe-${num}.fe-service 2>/dev/null | grep Address: | sed '1d' | sed 's/Address://g'`)
    if [[ $? -ne 0 || -z ${lookup_rst} ]]; then
      continue
    fi
    echo "lookup_rst:${lookup_rst}"
    ips=($lookup_rst)
    ip=${ips[0]}
    iparr[num]=1
    let pinged+=1
    echo "pinged:${pinged};num:${num};ip:${ip};iparr:${iparr[*]}"
    map_ip2num[${ip}]="${num}"
  done
done
echo "map_ip2num:"
echo ${map_ip2num[@]}
echo ${!map_ip2num[@]}

FE_MASTER_ID=""
trimmed=`mysql -u'root' -P ${FE_MYSQL_PORT} -h fe-service -e"SHOW PROC '/frontends'" | sed 's/|//g' | grep -E "FOLLOWER[[:space:]]true" | grep -E "true[[:space:]]true"`
ismaster=$?
echo "trimmed:\n${trimmed}"
if [[ "${ismaster}" == 0 ]]; then
  arr=($trimmed)
  echo "arr:${arr[*]}"
  ip=${arr[1]}
  echo "ip:${ip}"
  FE_MASTER_ID=${map_ip2num[${ip}]}
  echo "DEBUG >>>>>> follower lead found"
else
  echo "DEBUG >>>>>> no follower lead found"
fi
echo "FE_MASTER_ID:${FE_MASTER_ID}"
let _DEFAULT_FE_MASTER_ID=0
FE_MASTER_ID=""
if [[ -z ${FE_MASTER_ID} ]]; then
    let _COALESCED_FE_MASTER_ID=${_DEFAULT_FE_MASTER_ID}
else
    let _COALESCED_FE_MASTER_ID=${FE_MASTER_ID}
fi


conf=/opt/apache-doris/${prj}/conf/${prj}.conf
cat /tmp/preconf/common.conf >> ${conf}
cat /tmp/preconf/${prj}.conf >> ${conf}
if [[ "${prj}" == "be" ]]; then
  pvcmnt="/opt/apache-doris/be/storage"
else
  pvcmnt="/opt/apache-doris/fe/doris-meta"
fi
proof_file=${pvcmnt}/common.conf
cat ${proof_file}
if [[ -f ${proof_file} ]]; then
  echo "not the 1st time bootup"
  if [[ "${prj}" == "fe" ]]; then
    meta_recovery="metadata_failure_recovery=true"
    cat ${conf} | grep "${meta_recovery}"
    if [[ "$?" != 0 ]]; then
      echo "${meta_recovery}" >> ${conf}
    fi
  fi
else
  echo "1st time bootup, conf setup"
  cp /tmp/preconf/common.conf ${pvcmnt}/
fi

if [[ "${prj}" == "be" ]]; then
  /tmp/preconf/init_be.sh --fe_master_id ${_COALESCED_FE_MASTER_ID} --fe_mysql_port ${FE_MYSQL_PORT} --fe_servers ${FE_SERVERS} --be_addr ${BE_ADDR}
else
  /tmp/preconf/init_fe.sh --edit_log_port ${EDIT_LOG_PORT} --fe_master_id ${_COALESCED_FE_MASTER_ID} --fe_mysql_port ${FE_MYSQL_PORT} --fe_id ${FE_ID} --fe_servers ${FE_SERVERS}
fi
