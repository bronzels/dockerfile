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
PRESTO_HOME=${PRJ_HOME}/presto

cd ${PRESTO_HOME}
git clone git@github.com:yuananf/tpcds-presto.git

cat << \EOF > env.sh
#engine=trino
engine=presto
#engine=presto-velox
if [[ ${engine} == "trino" ]]; then
  CONTAINER_HOME_PATH=/usr/lib/trino
else
  CONTAINER_HOME_PATH=/home/presto
fi
maxmem=24
maxmem_pernode=8
heapmem=24
workers=3
      ts=ds
      SCALE=10
EOF

source env.sh

kubectl exec -it -n presto `kubectl get pod -n presto | grep Running | grep coordinator | awk '{print $1}'` -- rm -f ${CONTAINER_HOME_PATH}/env.sh
kubectl cp env.sh -n presto `kubectl get pod -n presto | grep Running | grep coordinator | awk '{print $1}'`:${CONTAINER_HOME_PATH}/env.sh

kubectl cp ${PRESTO_HOME}/tpcds-presto -n presto `kubectl get pod -n presto | grep Running | grep coordinator | awk '{print $1}'`:${CONTAINER_HOME_PATH}/tpcds-presto


:<<EOF
kubectl cp -n presto `kubectl get pod -n presto | grep Running | grep coordinator | awk '{print $1}'`:${CONTAINER_HOME_PATH}/test-log-trino-2023-02-23-t-00-28-24 ${PRESTO_HOME}/test-log-trino-2023-02-23-t-00-28-24
kubectl cp -n presto `kubectl get pod -n presto | grep Running | grep coordinator | awk '{print $1}'`:${CONTAINER_HOME_PATH}/test-tpcds-result-trino-worker-3-data-10g-maxmem-16-maxmem_pernode-8-2023-02-23-t-00-28-24.csv ${PRESTO_HOME}/test-tpcds-result-trino-worker-3-data-10g-maxmem-16-maxmem_pernode-8-2023-02-23-t-00-28-24.csv
EOF
kubectl cp -n presto `kubectl get pod -n presto | grep Running | grep coordinator | awk '{print $1}'`:${CONTAINER_HOME_PATH}/test-tpc${ts}-log-${engine} ${PRESTO_HOME}/test-tpc${ts}-log-${engine}
kubectl cp -n presto `kubectl get pod -n presto | grep Running | grep coordinator | awk '{print $1}'`:${CONTAINER_HOME_PATH}/test-tpc${ts}-result-${engine}-worker-3-data-10g-heapmem-24g-maxmem-24g-maxmem_pernode-8g.csv ${PRESTO_HOME}/test-tpc${ts}-result-${engine}-worker-3-data-10g-heapmem-24g-maxmem-24g-maxmem_pernode-8g.csv

kubectl exec -it -n presto `kubectl get pod -n presto | grep Running | grep coordinator | awk '{print $1}'` -- bash

  chmod a+x *.sh

  rm -f test-*

  source env.sh
  #./test.sh > test-log-trino-`date +%Y-%m-%d`-t-`date +%H-%M-%S` 2>&1 &
  ./test.sh > test-tpc${ts}-log-${engine} 2>&1 &

  tail -f test-tpc${ts}-log-${engine}

cat << \EOF > test.sh
#!/bin/bash
source ./env.sh
      echo "ts:${ts}"
      echo "SCALE:${SCALE}"
      #csvfile=test-tpc${ts}-result-${engine}-worker-${workers}-data-${SCALE}g-heapmem-${heapmem}g-maxmem-${maxmem}g-maxmem_pernode-${maxmem_pernode}g-`date +%Y-%m-%d`-t-`date +%H-%M-%S`.csv
      csvfile=test-tpc${ts}-result-${engine}-worker-${workers}-data-${SCALE}g-heapmem-${heapmem}g-maxmem-${maxmem}g-maxmem_pernode-${maxmem_pernode}g.csv
      echo "csvfile:${csvfile}"
      start=$(date +"%s.%9N")
      arr=(`ls -dl tpcds-presto/*.sql |awk '{print $NF}'`)
      echo -e "query,time" > $csvfile
      for queryfile in ${arr[@]}
      do
        ls ${queryfile}
        echo "queryfile:${queryfile}"
        num=`echo ${queryfile}|sed 's/tpcds-presto\///g'|sed 's/.sql//g'`
        echo "num:${num}"
        start=$(date +"%s.%9N")
        if [[ ${engine} == "trino" ]]; then
          trino --server my-trino:8080 --catalog hive --schema tpcds_bin_partitioned_orc_${SCALE} -f ${queryfile}
        else
          presto-server/bin/presto-cli --server my-presto-kube:8080 --catalog hive --schema tpcds_bin_partitioned_orc_${SCALE} -f ${queryfile}
        fi
        #date
        end=$(date +"%s.%9N")
        delta=`echo "scale=9;$end - $start" | bc`
        echo timediff:${delta}
        echo "----------------------------------------------------------------------------------------------------------------------------------------"
        #echo -e "$num\t${delta}" >> $csvfile
        echo -e "$num,${delta}" >> $csvfile
        num=$[$num+1]
      done
EOF

:<<EOF
#trino
tpcds-presto/q30.sql
queryfile:tpcds-presto/q30.sql
num:q30
Feb 23, 2023 12:35:54 AM org.jline.utils.Log logr
WARNING: Unable to create a system terminal, creating a dumb terminal (enable debug logging for more information)
Query 20230223_003554_00037_wfqk6 failed: line 23:3: Column 'c_last_review_date' cannot be resolved
LINE 23:   c_last_review_date,
           ^


presto@my-presto-kube-coordinator-8b7f77f77-flg6h:~$ presto-server/bin/presto-cli --server my-presto-kube:8080 --catalog hive --schema hudi_mydb
presto:hudi_mydb> SHOW TABLES;
         Table         
-----------------------
 products_hudi_sink    
 products_hudi_sink_ro 
 products_hudi_sink_rt 
(3 rows)

Query 20230323_043139_00002_wztng, FINISHED, 4 nodes
Splits: 53 total, 53 done (100.00%)
168ms [3 rows, 117B] [17 rows/s, 698B/s]

presto:hudi_mydb> SELECT * FROM products_hudi_sink;
 _hoodie_commit_time | _hoodie_partition_path | _hoodie_operation | _hoodie_record_key | _hoodie_commit_seqno | _hoodie_file_name | id | name | description | dt 
---------------------+------------------------+-------------------+--------------------+----------------------+-------------------+----+------+-------------+----
(0 rows)

Query 20230323_043148_00003_wztng, FINISHED, 1 node
Splits: 1 total, 1 done (100.00%)
170ms [0 rows, 0B] [0 rows/s, 0B/s]

presto:hudi_mydb> SELECT * FROM products_hudi_sink_rt;
 _hoodie_commit_time | _hoodie_commit_seqno  | _hoodie_record_key | _hoodie_partition_path |          _hoodie_file_name           | _hoodie_operation | id  |        name        |                       descri>
---------------------+-----------------------+--------------------+------------------------+--------------------------------------+-------------------+-----+--------------------+----------------------------->
 20230322212259089   | 20230322212259089_0_7 | id:107             | dt=20221214            | be2df080-500b-4842-b7b0-753d72396e7c | I                 | 107 | rocks              | box of assorted rocks       >
 20230322212259089   | 20230322212259089_0_9 | id:109             | dt=20221214            | be2df080-500b-4842-b7b0-753d72396e7c | I                 | 109 | spare tire         | 24 inch spare tire          >
 20230322212259089   | 20230322212259089_0_8 | id:108             | dt=20221214            | be2df080-500b-4842-b7b0-753d72396e7c | I                 | 108 | jacket             | water resistent black wind b>
 20230322212259089   | 20230322212259089_0_6 | id:106             | dt=20211214            | 632f5b20-489f-449f-bda7-ca9744b4e26a | I                 | 106 | hammer             | 16oz carpenter's hammer     >
 20230322212259089   | 20230322212259089_0_5 | id:105             | dt=20211214            | 632f5b20-489f-449f-bda7-ca9744b4e26a | I                 | 105 | hammer             | 14oz carpenter's hammer     >
 20230322212259089   | 20230322212259089_0_4 | id:104             | dt=20211214            | 632f5b20-489f-449f-bda7-ca9744b4e26a | I                 | 104 | hammer             | 12oz carpenter's hammer     >
 20230322212259089   | 20230322212259089_0_1 | id:101             | dt=20201214            | 2081fb4d-9035-4ece-a09a-c2bfa1595af8 | I                 | 101 | scooter            | Small 2-wheel scooter       >
 20230322212259089   | 20230322212259089_0_3 | id:103             | dt=20201214            | 2081fb4d-9035-4ece-a09a-c2bfa1595af8 | I                 | 103 | 12-pack drill bits | 12-pack of drill bits with s>
 20230322212259089   | 20230322212259089_0_2 | id:102             | dt=20201214            | 2081fb4d-9035-4ece-a09a-c2bfa1595af8 | I                 | 102 | car battery        | 12V car battery             >
(9 rows)



engine=presto


#engine=presto-velox


EOF
