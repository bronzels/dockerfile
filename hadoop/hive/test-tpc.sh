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

kubectl cp employee.txt -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'`:/app/hdfs/hive/hive-testbench/employee.txt
kubectl cp -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'`:/app/hdfs/hive/hive-testbench/tpcds-setup.sh ./tpcds-setup.sh
kubectl cp ./tpcds-setup.sh -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'`:/app/hdfs/hive/hive-testbench/tpcds-setup.sh
#kubectl cp hive-testbench -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-serv | awk '{print $1}'`:/app/hdfs/hive/hive-testbench
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- bash
  cd hive-testbench
  for ts in ds h; do
    for SCALE in 10 50 100; do
    #for SCALE in 2 5; do
      #ts=ds
      #SCALE=10
      echo "ts:${ts}"
      echo "SCALE:${SCALE}"
      csvfile=test-tpc${ts}-result-cluster-3c16g-3-data-${SCALE}g.csv
      echo "csvfile:${csvfile}"
      start=$(date +"%s.%9N")
      ./tpc${ts}-setup.sh ${SCALE} /tmp/tpc${ts}-gen
      end=$(date +"%s.%9N")
      echo timediff:`echo "scale=9;$end - $start" | bc`
      hadoop fs -du -h /tmp/tpc${ts}-gen/${SCALE}
      hadoop fs -count -q /tmp/tpc${ts}-gen/${SCALE}
      echo "----------------------------------------------------------------------------------------------------------------------------------------"
      echo "use tpc${ts}_bin_partitioned_orc_${SCALE};" > dbuse.sql
      MAX_REDUCERS=2500 # maximum number of useful reducers for any scale
      REDUCERS=$((test ${SCALE} -gt ${MAX_REDUCERS} && echo ${MAX_REDUCERS}) || echo ${SCALE})
      echo "REDUCERS:${REDUCERS}"
      if [[ "${ts}" =~ "ds" ]]; then
        nummax=100
      else
        nummax=23
      fi
      echo "nummax:${nummax}"
      num=1
      #for num in {1..${nummax}}
      #echo -e "query\ttime" > $csvfile
      echo -e "query,time" > $csvfile
      while [ $num -lt $nummax ]
      do
        if [[ "${ts}" =~ "ds" ]]; then
          queryfile="sample-queries-tpc${ts}/query${num}.sql"
        else
          queryfile="sample-queries-tpc${ts}/tpch_query${num}.sql"
        fi
        echo "queryfile:${queryfile}"
        start=$(date +"%s.%9N")
        #hive --hivevar REDUCERS=${REDUCERS} -i dbuse.sql -i settings/load-partitioned.sql -f ${queryfile}
        date
        end=$(date +"%s.%9N")
        delta=`echo "scale=9;$end - $start" | bc`
        echo timediff:${delta}
        echo "----------------------------------------------------------------------------------------------------------------------------------------"
        #echo -e "$num\t${delta}" >> $csvfile
        echo -e "$num,${delta}" >> $csvfile
        num=$[$num+1]
      done
      #cat test-tpcds-result-cluster-3c16g-3-data-10g.txt | grep timediff: | sed 's/timediff://g'
      hive -e "DROP DATABASE IF EXISTS tpc${ts}_bin_partitioned_orc_${SCALE} CASCADE"
      hive -e "DROP DATABASE IF EXISTS tpc${ts}_text_${SCALE} CASCADE"
      #hive -e "use tpcds_bin_partitioned_orc_10;show tables" | xargs -I '{}' hive -e 'drop table {}'
      hadoop fs -rm -r -f /tmp/tpc${ts}-gen/${SCALE}
    done
  done
