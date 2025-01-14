#!/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

FE_MASTER_ID=""
FE_MYSQL_PORT=""
FE_SERVERS=""
BROKER_ADDR=""

ARGS=$(getopt -o -h: --long fe_master_id:,fe_mysql_port:,fe_servers:,broker_addr: -n "$0" -- "$@")

eval set -- "${ARGS}"

while [[ -n "$1" ]]; do
    case "$1" in
    --fe_master_id)
        FE_MASTER_ID=$2
        shift
        ;;
    --fe_mysql_port)
        FE_MYSQL_PORT=$2
        shift
        ;;
    --fe_servers)
        FE_SERVERS=$2
        shift
        ;;
    --broker_addr)
        BROKER_ADDR=$2
        shift
        ;;
    --) ;;

    *)
        echo "Error option $1"
        break
        ;;
    esac
    shift
done
BROKER_NAME=`echo ${MY_POD_NAME} | sed 's/-//g' | tr -d '[0-9]'`

#echo FE_SERVERS = $FE_SERVERS
echo "DEBUG >>>>>> FE_MASTER_ID=[${FE_MASTER_ID}]"
echo "DEBUG >>>>>> FE_MYSQL_PORT=[${FE_MYSQL_PORT}]"
echo "DEBUG >>>>>> BROKER_NAME=[${BROKER_NAME}]"
echo "DEBUG >>>>>> FE_SERVERS=[${FE_SERVERS}]"
echo "DEBUG >>>>>> BROKER_ADDR=[${BROKER_ADDR}]"

feIpArray=()
feEditLogPortArray=()

IFS=","
# shellcheck disable=SC2206
feServerArray=(${FE_SERVERS})

for i in "${!feServerArray[@]}"; do
    let inti=$i

    val=${feServerArray[i]}
    val=${val// /}
    #tmpFeId=$(echo "${val}" | awk -F ':' '{ sub(/fe/, ""); sub(/ /, ""); print$1}')
    tmpFeIp=$(echo "${val}" | awk -F ':' '{ sub(/ /, ""); print$1}')
    tmpFeEditLogPort=$(echo "${val}" | awk -F ':' '{ sub(/ /, ""); print$2}')

    feIpArray[inti]=${tmpFeIp}
    feEditLogPortArray[inti]=${tmpFeEditLogPort}
done

broker_name=${BROKER_NAME}
broker_ip=$(echo "${BROKER_ADDR}" | awk -F ':' '{ sub(/ /, ""); print$1}')
broker_ipc_port=$(echo "${BROKER_ADDR}" | awk -F ':' '{ sub(/ /, ""); print$2}')

echo "DEBUG >>>>>> feIpArray = ${feIpArray[*]}"
echo "DEBUG >>>>>> feEditLogPortArray = ${feEditLogPortArray[*]}"
echo "DEBUG >>>>>> masterFe = ${feIpArray[${FE_MASTER_ID}]}:${feEditLogPortArray[${FE_MASTER_ID}]}"
echo "DEBUG >>>>>> broker_addr = ${broker_ip}:${broker_ipc_port}"

checkFrontends="mysql -u'root' -P ${FE_MYSQL_PORT} -h ${feIpArray[FE_MASTER_ID]} -e \"SHOW PROC '/frontends'\""
echo "DEBUG >>>>>> checkFrontends = 【${checkFrontends}】"

registerMySQL="mysql -u'root' -P ${FE_MYSQL_PORT} -h ${feIpArray[${FE_MASTER_ID}]} -e \"ALTER SYSTEM ADD BROKER ${broker_name} '${broker_ip}:${broker_ipc_port}'\""
echo "DEBUG >>>>>> registerMySQL = ${registerMySQL}"

#registerShell="/opt/apache-doris/be/bin/start_broker.sh &"
registerShell="/opt/apache-doris/broker/bin/start_broker.sh --daemon"
echo "DEBUG >>>>>> registerShell = ${registerShell}"

checkBrokers="mysql -u'root' -P ${FE_MYSQL_PORT} -h ${feIpArray[${FE_MASTER_ID}]} -e \"SHOW PROC '/brokers'\""
echo "DEBUG >>>>>> checkBrokers = 【${checkBrokers}】"

masterLive=1
retJoined=1
retStarted=1
brokerJoined=1
until [[ "${retJoined}" == 0 && "${retStarted}" == 0 && "${brokerJoined}" == 0 ]]
do
    sleep 2

    ## STEP1: check master fe service works
    if [[ "${masterLive}" != 0 ]]; then
      echo "Run masterLive checkFrontends command, [ checkFrontends = ${checkFrontends} ]"
      eval "${checkFrontends}" | sed 's/|//g' | grep -E "FOLLOWER[[:space:]]*true" | grep -E "true[[:space:]]*true"
      masterLive=$?
      echo "The resutl of run masterLive checkFrontends command, [ res = $masterLive ]"
      if [[ "${masterLive}" != 0 ]]; then
          echo "DEBUG >>>>>> continue in STEP1: check master fe service works"
          sleep 5
          continue
      fi
    fi

    ## STEP3: call start_broker.sh
    if [[ "${retStarted}" != 0 ]]; then
      echo "Run registerShell command, [ registerShell = ${registerShell} ]"
      eval "${registerShell}"
      retStarted=$?
      echo "The resutl of run registerShell command, [ res = $retStarted ]"
      if [[ "${retStarted}" != 0 ]]; then
          echo "DEBUG >>>>>> continue in STEP3: call start_be.sh"
          continue
      fi
      sleep 2
    fi

    ## STEP2: registe broker from mysql client
    if [[ "${retJoined}" != 0 ]]; then
      echo "Run registerMySQL command, [ registerMySQL = ${registerMySQL} ]"
      eval "${registerMySQL}" 2> step2_errfile
      retJoined=$?
      echo "The resutl of run registerMySQL command, [ res retJoined = $retJoined ]"
      cat step2_errfile | grep "errCode = 2, detailMessage = already exists"
      #Same broker already exists, not tested
      alreadyExists=$?
      echo "The resutl of run registerMySQL command, [ res alreadyExists = $alreadyExists ]"
      if [[ "${retJoined}" != 0 ]]; then
        if [[ "${alreadyExists}" != 0 ]]; then
          echo "DEBUG >>>>>> continue in STEP2: register backend to fe leader by mysql client"
          continue
        else
          retJoined=0
        fi
      fi
      sleep 2
    fi

    ## STEP4: check this be joined status
    echo "Run be joined checkBrokers command, [ checkBrokers = ${checkBrokers} ]"
    eval "${checkBrokers}" | sed 's/|//g' | grep "[[:space:]]${broker_ip}[[:space:]]" | grep "[[:space:]]${broker_ipc_port}[[:space:]]true[[:space:]]"
    brokerJoined=$?
    echo "The resutl of run checkBrokers command, [ res = $brokerJoined ]"
done
echo "DEBUG >>>>>> BROKER "${MY_POD_NAME}" is registered and started to FE master successfully and checked status OK"
