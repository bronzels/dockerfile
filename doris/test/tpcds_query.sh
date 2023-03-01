if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Mac detected."
    #mac
    os=darwin
    MYHOME=/Volumes/data
    SED=gsed
    bin=/Users/apple/bin
else
    echo "Assuming linux by default."
    #linux
    os=linux
    MYHOME=~
    SED=sed
    bin=/usr/local/bin
fi

WORK_HOME=${MYHOME}/workspace
PRJ_HOME=${WORK_HOME}/dockerfile

DORIS_HOME=${PRJ_HOME}/doris
#DORIS_REV=1.2.1
DORIS_REV=1.2.2

STARROCKS_REV=2.5.2
STARROCKS_OP_REV=1.3

JUICEFS_VERSION=1.0.2


kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep doris-fe-0 | awk '{print $1}'` -- \
  bash

ddlfile=hive_tpcds_orc_10_manual_imported_few-ddl.sql
db=hive_tpcds_orc_10_manual_imported_few
ddlfile=tpcds-ddl.sql
db=test_db
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep doris-fe-0 | awk '{print $1}'` -- rm -f /${ddlfile}
kubectl cp ${ddlfile} -n doris `kubectl get pod -n doris | grep Running | grep doris-fe-0 | awk '{print $1}'`:/${ddlfile}
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep doris-fe-0 | awk '{print $1}'` -- \
  mysql --default-character-set=utf8 -h fe -P 9030 -u'root' -e "source /${ddlfile}"
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep doris-fe-0 | awk '{print $1}'` -- \
  mysql --default-character-set=utf8 -h fe -P 9030 -u'root' -e "USE ${db};SHOW TABLES;"

cp -r ${PRJ_HOME}/spark/test/spark-tpcds-10 doris-tpcds-10
$SED -i "s/(cast('1999-02-22' AS DATE) + INTERVAL 30 days)/DATE_ADD(CAST('1999-02-22' AS DATE), INTERVAL 30 DAY)/g" doris-tpcds-10/q98.sql
$SED -i "s/(cast('1999-02-22' AS DATE) + INTERVAL 30 days)/DATE_ADD(CAST('1999-02-22' AS DATE), INTERVAL 30 DAY)/g" doris-tpcds-10/q12.sql
$SED -i "s/(CAST('2002-02-01' AS DATE) + INTERVAL 60 days)/DATE_ADD(CAST('2002-02-01' AS DATE), INTERVAL 60 DAY)/g" doris-tpcds-10/q16.sql
$SED -i "s/(cast('1999-02-22' AS DATE) + INTERVAL 30 days)/DATE_ADD(CAST('1999-02-22' AS DATE), INTERVAL 30 DAY)/g" doris-tpcds-10/q20.sql
$SED -i "s/(cast('2000-03-11' AS DATE) - INTERVAL 30 days)/DATE_SUB(CAST('2000-03-11' AS DATE), INTERVAL 30 DAY)/g" doris-tpcds-10/q21.sql
$SED -i "s/(cast('2000-03-11' AS DATE) + INTERVAL 30 days)/DATE_ADD(CAST('2000-03-11' AS DATE), INTERVAL 30 DAY)/g" doris-tpcds-10/q21.sql
$SED -i "s/(cast('2000-01-27' AS DATE) + interval 90 days)/DATE_ADD(CAST('2000-01-27' AS DATE), INTERVAL 90 DAY)/g" doris-tpcds-10/q32.sql
$SED -i "s/(cast('2000-02-01' AS DATE) + INTERVAL 60 days)/DATE_ADD(CAST('2000-02-01' AS DATE), INTERVAL 60 DAY)/g" doris-tpcds-10/q37.sql
$SED -i "s/(cast('2000-03-11' AS DATE) - INTERVAL 30 days)/DATE_SUB(CAST('2000-03-11' AS DATE), INTERVAL 30 DAY)/g" doris-tpcds-10/q40.sql
$SED -i "s/(cast('2000-03-11' AS DATE) + INTERVAL 30 days)/DATE_ADD(CAST('2000-03-11' AS DATE), INTERVAL 30 DAY)/g" doris-tpcds-10/q40.sql
$SED -i "s/((cast('2000-08-23' AS DATE) + INTERVAL 14 days))/DATE_ADD(CAST('2000-08-23' AS DATE), INTERVAL 14 DAY)/g" doris-tpcds-10/q5.sql
$SED -i "s/(cast(d1.d_date AS DATE) + interval 5 days)/DATE_ADD(CAST(d1.d_date AS DATE), INTERVAL 5 DAY)/g" doris-tpcds-10/q72.sql
$SED -i "s/(cast('2000-08-03' AS DATE) + INTERVAL 30 days)/DATE_ADD(CAST('2000-08-03' AS DATE), INTERVAL 30 DAY)/g" doris-tpcds-10/q77.sql
$SED -i "s/(cast('2000-08-23' AS DATE) + INTERVAL 30 days)/DATE_ADD(CAST('2000-08-23' AS DATE), INTERVAL 30 DAY)/g" doris-tpcds-10/q80.sql
$SED -i "s/(cast('2000-05-25' AS DATE) + INTERVAL 60 days)/DATE_ADD(CAST('2000-05-25' AS DATE), INTERVAL 60 DAY)/g" doris-tpcds-10/q82.sql
$SED -i "s/(cast('2000-01-27' AS DATE) + INTERVAL 90 days)/DATE_ADD(CAST('2000-01-27' AS DATE), INTERVAL 90 DAY)/g" doris-tpcds-10/q92.sql
$SED -i "s/(CAST('1999-02-01' AS DATE) + INTERVAL 60 days)/DATE_ADD(CAST('1999-02-01' AS DATE), INTERVAL 60 DAY)/g" doris-tpcds-10/q94.sql
$SED -i "s/(CAST('1999-02-01' AS DATE) + INTERVAL 60 DAY)/DATE_ADD(CAST('1999-02-01' AS DATE), INTERVAL 60 DAY)/g" doris-tpcds-10/q95.sql
$SED -i "s/2000-01-27]/2000-01-27/g" doris-tpcds-10/q32.sql

kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep doris-fe-0 | awk '{print $1}'` -- rm -r -f /doris-tpcds-10
kubectl cp doris-tpcds-10 -n doris `kubectl get pod -n doris | grep Running | grep doris-fe-0 | awk '{print $1}'`:/doris-tpcds-10

engine=doris
#csvfile=tpcds-${engine}-few-query.csv
csvfile=tpcds-${engine}-query.csv

kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep doris-fe-0 | awk '{print $1}'` -- bash
  mysql --default-character-set=utf8 -h fe -P 9030 -u'root' -e "SET exec_mem_limit=14G"
  engine=doris
  #csvfile=tpcds-${engine}-few-query.csv
  csvfile=tpcds-${engine}-query.csv
  echo -e "query,time" > ${csvfile}
  #arr=(1 2)
  #for num in ${arr[*]}
  for num in {1..99}
  do
    start=$(date +"%s.%9N")
    file=/q${num}.sql
    cp /doris-tpcds-10/q${num}.sql ${file}
    #sed -i 's/tpcds_bin_partitioned_orc_10/hive_tpcds_orc_10_manual_imported_few/g' ${file}
    sed -i 's/tpcds_bin_partitioned_orc_10/test_db/g' ${file}
    #cat ${file}
    mysql --default-character-set=utf8 -h fe -P 9030 -u'root' -e "source ${file}" > q${num}.log  2>&1
    end=$(date +"%s.%9N")
    delta=`echo "scale=9;$end - $start" | bc`
    echo q${num},${delta}
    echo -e "q$num,${delta}" >> ${csvfile}
  done
  cat ${csvfile}
  for num in {1..99}
  do
    echo q${num}
    cat q${num}.log | grep ERROR
  done

kubectl cp -n doris `kubectl get pod -n doris | grep Running | grep doris-fe-0 | awk '{print $1}'`:/${csvfile} ${csvfile}

:<<EOF
1，全局sql配置SET exec_mem_limit=14G
2，增加BE memory limit到18G
(exec_mem_limit12，增加BE16还是失败)
q95
ERROR 1105 (HY000) at line 3 in file: '/q95.sql': errCode = 2, detailMessage = PreCatch std::bad_alloc, Memory limit exceeded:<consuming tracker:<Query#Id=9a4208068ceb44bb-970786c08f2c47f5>, process memory used 2.22 GB exceed limit 5.96 GB or sys mem available 49.00 GB less than low water mark 762.94 MB, failed alloc size 8.00 GB>, executing msg:<execute:<>>. backend 192.168.3.14 process memory used 2.22 GB, limit 5.96 GB. If query tracker exceed, `set exec_mem_limit=8G` to change limit, details see be.INFO.

1，删除spark-sql语法INTERVAL
2，spark-sql查询脚本字段q30，customer字段应该是c_last_review_date_sk
3，增加BE memory limit到8G
q30
ERROR 1054 (42S22) at line 3 in file: '/q30.sql': errCode = 2, detailMessage = Unknown column 'c_last_review_date' in 'table list'
q78
ERROR 1105 (HY000) at line 3 in file: '/q78.sql': errCode = 2, detailMessage = Process has no memory available, cancel top memory usage query: query memory tracker <Query#Id=48499295bc704154-96b86bbaafdc1b94> consumption 2.52 GB, backend 192.168.3.103 process memory used 4.68 GB exceed limit 4.47 GB or sys mem available 17.53 GB less than low water mark 563.42 MB. Execute again after enough memory, details see be.INFO.
q92
ERROR 1105 (HY000) at line 3 in file: '/q92.sql': errCode = 2, detailMessage = Invalid time unit 'days' in timestamp arithmetic expression '(CAST('2000-01-27' AS DATE) + INTERVAL 90 days)'.
q95
ERROR 1105 (HY000) at line 3 in file: '/q95.sql': errCode = 2, detailMessage = PreCatch std::bad_alloc, Memory limit exceeded:<consuming tracker:<Query#Id=7b077474bc174b08-9d3e6b2ca1344232>, process memory used 2.69 GB exceed limit 4.47 GB or sys mem available 48.75 GB less than low water mark 563.42 MB, failed alloc size 8.00 GB>, executing msg:<execute:<>>. backend 192.168.3.14 process memory used 2.69 GB, limit 4.47 GB. If query tracker exceed, `set exec_mem_limit=8G` to change limit, details see be.INFO.
EOF