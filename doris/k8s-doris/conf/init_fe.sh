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

EDIT_LOG_PORT=""
FE_MASTER_ID=""
FE_MYSQL_PORT=""
FE_ID=0
FE_SERVERS=""

ARGS=$(getopt -o -h: --long edit_log_port:,fe_master_id:,fe_mysql_port:,fe_id:,fe_servers: -n "$0" -- "$@")

eval set -- "${ARGS}"

while [[ -n "$1" ]]; do
    case "$1" in
    --edit_log_port)
        EDIT_LOG_PORT=$2
        shift
        ;;
    --fe_master_id)
        FE_MASTER_ID=$2
        shift
        ;;
    --fe_mysql_port)
        FE_MYSQL_PORT=$2
        shift
        ;;
    --fe_id)
        FE_ID=$2
        shift
        ;;
    --fe_servers)
        FE_SERVERS=$2
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

echo "DEBUG >>>>>> EDIT_LOG_PORT = [${EDIT_LOG_PORT}]"
echo "DEBUG >>>>>> FE_MASTER_ID = [${FE_MASTER_ID}]"
echo "DEBUG >>>>>> FE_MYSQL_PORT = [${FE_MYSQL_PORT}]"
echo "DEBUG >>>>>> FE_ID = [${FE_ID}]"
echo "DEBUG >>>>>> FE_SERVERS = [${FE_SERVERS}]"

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
    #echo "DEBUG >>>>>> tmpFeId = [${tmpFeId}]"
    echo "DEBUG >>>>>> tmpFeIp = [${tmpFeIp}]"
    echo "DEBUG >>>>>> tmpFeEditLogPort = [${tmpFeEditLogPort}]"

    feIpArray[inti]=${tmpFeIp}
    feEditLogPortArray[inti]=${tmpFeEditLogPort}

done

echo "DEBUG >>>>>> feIpArray = ${feIpArray[*]}"
echo "DEBUG >>>>>> feEditLogPortArray = ${feEditLogPortArray[*]}"
echo "DEBUG >>>>>> masterFe = ${feIpArray[FE_MASTER_ID]}:${feEditLogPortArray[FE_MASTER_ID]}"
echo "DEBUG >>>>>> currentFe = ${feIpArray[FE_ID]}:${feEditLogPortArray[FE_ID]}"

#priority_networks=$(echo "${feIpArray[FE_ID]}" | awk -F '.' '{print$1"."$2"."$3".0/24"}')
#echo "DEBUG >>>>>> Append the configuration [priority_networks = ${priority_networks}] to /opt/doris-fe/conf/fe.conf"
#echo "priority_networks = ${priority_networks}" >>/opt/apache-doris/fe/conf/fe.conf


:<<EOF
checkFrontends="mysql -u'root' -P 9030 -h doris-fe-0.fe-service -e \"SHOW PROC '/frontends'\""
registerMySQL="mysql -u'root' -P 9030 -h doris-fe-0.fe-service -e \"alter system add follower 'doris-fe-1.fe-service:9010'\""
registerShell="/opt/apache-doris/fe/bin/start_fe.sh --helper 'doris-fe-0.fe-service:9010'"
EOF

checkFrontends="mysql -u'root' -P ${FE_MYSQL_PORT} -h ${feIpArray[FE_MASTER_ID]} -e \"SHOW PROC '/frontends'\""
registerMySQL="mysql -u'root' -P ${FE_MYSQL_PORT} -h ${feIpArray[FE_MASTER_ID]} -e \"ALTER SYSTEM ADD FOLLOWER '${feIpArray[FE_ID]}:${feEditLogPortArray[FE_ID]}'\""
registerShell="/opt/apache-doris/fe/bin/start_fe.sh --daemon --helper '${feIpArray[FE_MASTER_ID]}:${feEditLogPortArray[FE_MASTER_ID]}'"

echo "DEBUG >>>>>> checkFrontends = 【${checkFrontends}】"
echo "DEBUG >>>>>> registerMySQL = 【${registerMySQL}】"
echo "DEBUG >>>>>> registerShell = 【${registerShell}】"

masterLive=1
if [[ "${FE_ID}" != "${FE_MASTER_ID}" ]]; then
    ## if current node is not master
    ## STEP1: check master fe service works
    ## STEP2: registe follower from mysql client
    ## STEP3: call start_fe.sh using --help optional
    ## STEP4: check this follower status
    echo "DEBUG >>>>>> FE is follower, fe_id = ${FE_ID}"

    retJoined=1
    retStarted=1
    followerJoined=1
    until [[ "${retStarted}" == 0 && "${retJoined}" == 0 && "${followerJoined}" == 0 ]]
    do
        sleep 2

        ## STEP1: check master fe service works
        if [[ "${masterLive}" != 0 ]]; then
          echo "Run masterLive checkFrontends command, [ checkFrontends = ${checkFrontends} ]"
          eval "${checkFrontends}" | sed 's/|//g' | grep -E "FOLLOWER[[:space:]]true" | grep -E "true[[:space:]]true"
          masterLive=$?
          echo "The resutl of run masterLive checkFrontends command, [ res = $masterLive ]"
          if [[ "${masterLive}" != 0 ]]; then
              echo "DEBUG >>>>>> continue in STEP1: check master fe service works"
              sleep 5
              continue
          fi
        fi

        ## STEP3: call start_fe.sh using --help optional
        if [[ "${retStarted}" != 0 ]]; then
          echo "Run registerShell command, [ registerShell = ${registerShell} ]"
          eval "${registerShell}"
          retStarted=$?
          echo "The resutl of run registerShell command, [ res = $retStarted ]"
          if [[ "${retStarted}" != 0 ]]; then
              echo "DEBUG >>>>>> continue in STEP3: call start_fe.sh using --help optional"
              continue
          fi
          sleep 15
        fi

        ## STEP2: register follower from mysql client
        if [[ "${retJoined}" != 0 ]]; then
          echo "Run registerMySQL command, [ registerMySQL = ${registerMySQL} ]"
          eval "${registerMySQL}" 2> step2_errfile
          retJoined=$?
          echo "The resutl of run registerMySQL command, [ res retJoined = $retJoined ]"
          cat step2_errfile | grep "errCode = 2, detailMessage = frontend already exists"
          alreadyExists=$?
          echo "The resutl of run registerMySQL command, [ res alreadyExists = $alreadyExists ]"
          if [[ "${retJoined}" != 0 ]]; then
            if [[ "${alreadyExists}" != 0 ]]; then
              echo "DEBUG >>>>>> continue in STEP2: register fe follower to fe leader by mysql client"
              continue
            else
              retJoined=0
            fi
          fi
          sleep 2
        fi

        ## STEP4: check this follower status
        echo "Run followerJoined checkFrontends command, [ checkFrontends = ${checkFrontends} ]"
        eval "${checkFrontends}" | sed 's/|//g' | grep "${FE_IPADDRESS}_${EDIT_LOG_PORT}" | grep -E "FOLLOWER[[:space:]]false" | grep -E "true[[:space:]]true"
        followerJoined=$?
        echo "The resutl of run followerJoined checkFrontends command, [ res = $followerJoined ]"
    done
    echo "DEBUG >>>>>> FE "${MY_POD_NAME}" is registered and started to FE master successfully and checked status OK"
else
    registerShell="/opt/apache-doris/fe/bin/start_fe.sh --daemon"
    echo "DEBUG >>>>>> FE is master, fe_id = ${FE_ID}"
    echo "DEBUG >>>>>> registerShell = ${registerShell}"
    eval "${registerShell}"
    sleep 15
    until [[ "${masterLive}" == 0 ]]
    do
        sleep 2
        eval "${checkFrontends}" | sed 's/|//g' | grep -E "FOLLOWER[[:space:]]true" | grep -E "true[[:space:]]true"
        masterLive=$?
    done
    echo "DEBUG >>>>>> FE "${MY_POD_NAME}" is started as FE master successfully and checked status OK"
fi
