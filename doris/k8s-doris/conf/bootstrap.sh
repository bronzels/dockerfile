#!/bin/bash
let srvs=$1
echo "srvs:${srvs}"
be_heartbeat_port=$2
echo "be_heartbeat_port:${be_heartbeat_port}"
FE_MYSQL_PORT=$3
echo "FE_MYSQL_PORT:${FE_MYSQL_PORT}"
EDIT_LOG_PORT=$4
echo "EDIT_LOG_PORT:${EDIT_LOG_PORT}"
FE_PVC_DIR=$5
echo "FE_PVC_DIR:${FE_PVC_DIR}"
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
declare -A map_num2ip=()
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
    map_num2ip[${num}]="${ip}"
  done
done
echo "map_ip2num:"
echo ${map_ip2num[@]}
echo ${!map_ip2num[@]}
echo "map_num2ip:"
echo ${map_num2ip[@]}
echo ${!map_num2ip[@]}

FE_MASTER_ID=""
for num in `seq 0 ${srvmaxno}`
do
  trimmed=`mysql -u'root' -P ${FE_MYSQL_PORT} -h ${map_num2ip["${num}"]} -e "SHOW PROC '/frontends'" | sed 's/|//g' | grep -E "FOLLOWER[[:space:]]true" | grep -E "true[[:space:]]true"`
  masterLive=$?
  echo "The resutl of run masterLive checkFrontendsByNum command, [ res = $masterLive ]"
  if [[ "${masterLive}" != 0 ]]; then
      echo "DEBUG >>>>>> continue in check master fe works and which fe num it is"
      continue
  else
    arr=($trimmed)
    echo "arr:${arr[*]}"
    master_ip=${arr[1]}
    echo "master_ip:${master_ip}"
    FE_MASTER_ID=${map_ip2num["${master_ip}"]}
    break
  fi
done
echo "FE_MASTER_ID:${FE_MASTER_ID}"


let _DEFAULT_FE_MASTER_ID=0
if [[ -z ${FE_MASTER_ID} ]]; then
    let _COALESCED_FE_MASTER_ID=${_DEFAULT_FE_MASTER_ID}
else
    let _COALESCED_FE_MASTER_ID=${FE_MASTER_ID}
fi
echo "_COALESCED_FE_MASTER_ID:${_COALESCED_FE_MASTER_ID}"


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
  if [[ "${prj}" == "be" ]]; then
    echo "DEBUG >>>>>> start be"
    registerShell="/opt/apache-doris/be/bin/start_be.sh --daemon"
    echo "DEBUG >>>>>> registerShell = ${registerShell}"
    eval "${registerShell}"
  else
    echo "DEBUG >>>>>> fe to start"
    #整个集群在已经有数据情况下重启
    ls -l ${FE_PVC_DIR}/
    if [[ -z ${FE_MASTER_ID} && -f ${FE_PVC_DIR}/last_time_master ]]; then
      echo "DEBUG >>>>>> add to fe.conf"
      meta_recovery="metadata_failure_recovery=true"
      echo "${meta_recovery}" >> ${conf}
      cat ${conf}
      echo "DEBUG >>>>>> start fe leader as last it was"
      startShell="/opt/apache-doris/fe/bin/start_fe.sh --daemon"
      echo "DEBUG >>>>>> startShell = ${startShell}"
      eval "${startShell}"
      echo "DEBUG >>>>>> remove fe followers after leader status is OK"
      echo "DEBUG >>>>>> fe master sleeps to wait itself started"
      sleep 30
      checkFrontends="mysql -u'root' -P ${FE_MYSQL_PORT} -h ${map_num2ip[${FE_ID}]} -e \"SHOW PROC '/frontends'\""
      echo "DEBUG >>>>>> checkFrontends = 【${checkFrontends}】"
      masterLive=1
      until [[ "${masterLive}" == 0 ]]
      do
          sleep 2
          eval "${checkFrontends}" | sed 's/|//g' | grep -E "FOLLOWER[[:space:]]true" | grep -E "true[[:space:]]true"
          masterLive=$?
      done
      for num in `seq 0 ${srvmaxno}`
      do
        echo "DEBUG >>>>>> num:${num}, FE_ID:${FE_ID}"
        if [[ ${FE_ID} == "${num}" ]]; then
          continue
        fi
        ip_port=${map_num2ip["${num}"]}:${EDIT_LOG_PORT}
        echo "DEBUG >>>>>> ip_port:${ip_port}"
        dropMySQL="mysql -u'root' -P ${FE_MYSQL_PORT} -h ${map_num2ip[${FE_ID}]} -e \"ALTER SYSTEM DROP FOLLOWER '${ip_port}'\""
        echo "DEBUG >>>>>> dropMySQL = 【${dropMySQL}】"
        eval "${dropMySQL}"
        echo "The resutl of run dropMySQL command, [ res = $? ]"
      done
    else
      if [[ -z ${FE_MASTER_ID} ]]; then
        echo "DEBUG >>>>>> fe not master, also no master found, sleeps to wait master fe started"
        sleep 60
        echo "DEBUG >>>>>> fe not master is out of sleep to wait master fe started"

        masterLive=1
        until [[ "${masterLive}" == 0 ]]
        do
          sleep 5
          for num in `seq 0 ${srvmaxno}`
          do
            trimmed=`mysql -u'root' -P ${FE_MYSQL_PORT} -h ${map_num2ip["${num}"]} -e "SHOW PROC '/frontends'" | sed 's/|//g' | grep -E "FOLLOWER[[:space:]]true" | grep -E "true[[:space:]]true"`
            masterLive=$?
            echo "The resutl of run masterLive checkFrontendsByNum command, [ res = $masterLive ]"
            if [[ "${masterLive}" != 0 ]]; then
                echo "DEBUG >>>>>> continue in check master fe works and which fe num it is"
                continue
            else
              arr=($trimmed)
              echo "arr:${arr[*]}"
              master_ip=${arr[1]}
              echo "master_ip:${master_ip}"
              FE_MASTER_ID=${map_ip2num["${master_ip}"]}
              break 2
            fi
          done
        done
        echo "FE_MASTER_ID:${FE_MASTER_ID}"
      fi

      #rm -rf ${FE_PVC_DIR}/*
      #不能删除common.conf用来标识是否是初次安装启动
      ls -d ${FE_PVC_DIR}/* | grep -v common.conf | xargs rm -rf
      cat ${FE_PVC_DIR}/common.conf
      fe_master_optionstr="--fe_master_id ${FE_MASTER_ID}"
      echo "fe_master_optionstr:${fe_master_optionstr}"
      /tmp/preconf/init_fe.sh --edit_log_port ${EDIT_LOG_PORT} ${fe_master_optionstr} --fe_mysql_port ${FE_MYSQL_PORT} --fe_id ${FE_ID} --fe_servers ${FE_SERVERS}
    fi
  fi
else
  echo "1st time bootup, conf setup"
  cp /tmp/preconf/common.conf ${pvcmnt}/
  fe_master_optionstr="--fe_master_id ${_COALESCED_FE_MASTER_ID}"
  echo "fe_master_optionstr:${fe_master_optionstr}"
  if [[ "${prj}" == "be" ]]; then
    /tmp/preconf/init_be.sh ${fe_master_optionstr} --fe_mysql_port ${FE_MYSQL_PORT} --fe_servers ${FE_SERVERS} --be_addr ${BE_ADDR}
  else
    /tmp/preconf/init_fe.sh --edit_log_port ${EDIT_LOG_PORT} ${fe_master_optionstr} --fe_mysql_port ${FE_MYSQL_PORT} --fe_id ${FE_ID} --fe_servers ${FE_SERVERS}
  fi
fi
