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

#kubectl cp hive-testbench -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-serv | awk '{print $1}'`:/app/hdfs/hive/hive-testbench
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-serv | awk '{print $1}'` -- bash
  cd hive-testbench
  #for SCALE in 10 50 100; do
  for SCALE in 5 10 20; do
    echo "SCALE:${SCALE}"
    #SCALE=20
    start=$(date +"%s.%9N")
    ./tpcds-setup.sh ${SCALE} /tmp/tpcds-gen
    end=$(date +"%s.%9N")
    echo timediff:`echo "scale=9;$end - $start" | bc`
    hadoop fs -du -h /tmp/tpcds-gen/${SCALE}
    hadoop fs -count -q /tmp/tpcds-gen/${SCALE}
    echo "----------------------------------------------------------------------------------------------------------------------------------------"
    echo "use tpcds_bin_partitioned_orc_${SCALE};" > dbuse.sql
    MAX_REDUCERS=2500 # maximum number of useful reducers for any scale
    REDUCERS=$((test ${SCALE} -gt ${MAX_REDUCERS} && echo ${MAX_REDUCERS}) || echo ${SCALE})
    echo "REDUCERS:${REDUCERS}"
    for num in {1..99}
    do
      queryfile="sample-queries-tpcds/query${num}.sql"
      echo "queryfile:${queryfile}"
      start=$(date +"%s.%9N")
      #hive --hivevar REDUCERS=${REDUCERS} -i dbuse.sql -i settings/load-partitioned.sql -f ${queryfile}
      hive --hivevar REDUCERS=${REDUCERS} -i dbuse.sql -f ${queryfile}
      end=$(date +"%s.%9N")
      echo timediff:`echo "scale=9;$end - $start" | bc`
      echo "----------------------------------------------------------------------------------------------------------------------------------------"
    done

    hive -e "DROP DATABASE IF EXISTS tpcds_bin_partitioned_orc_${SCALE} CASCADE"
    hive -e "DROP DATABASE IF EXISTS tpcds_text_${SCALE} CASCADE"
    #hive -e "use tpcds_bin_partitioned_orc_10;show tables" | xargs -I '{}' hive -e 'drop table {}'
    hadoop fs -rm -r -f /tmp/tpcds-gen/${SCALE}
  done
    start=$(date +"%s.%9N")
    ./tpch-setup.sh ${SCALE} /tmp/tpch-gen
    end=$(date +"%s.%9N")
    echo timediff:`echo "scale=9;$end - $start" | bc`
    hadoop fs -du -h /tmp/tpch-gen/${SCALE}
    hadoop fs -count -q /tmp/tpch-gen/${SCALE}
    echo "----------------------------------------------------------------------------------------------------------------------------------------"
    echo "use tpch_bin_partitioned_orc_${SCALE};" > dbuse.sql
    MAX_REDUCERS=2500 # maximum number of useful reducers for any scale
    REDUCERS=$((test ${SCALE} -gt ${MAX_REDUCERS} && echo ${MAX_REDUCERS}) || echo ${SCALE})
    echo "REDUCERS:${REDUCERS}"
    for num in {1..99}
    do
      queryfile="sample-queries-tpcds/query${num}.sql"
      echo "queryfile:${queryfile}"
      start=$(date +"%s.%9N")
      #hive --hivevar REDUCERS=${REDUCERS} -i dbuse.sql -i settings/load-partitioned.sql -f ${queryfile}
      hive --hivevar REDUCERS=${REDUCERS} -i dbuse.sql -f ${queryfile}
      end=$(date +"%s.%9N")
      echo timediff:`echo "scale=9;$end - $start" | bc`
      echo "----------------------------------------------------------------------------------------------------------------------------------------"
    done

    hive -e "DROP DATABASE IF EXISTS tpch_bin_partitioned_orc_${SCALE} CASCADE"
    hive -e "DROP DATABASE IF EXISTS tpch_text_${SCALE} CASCADE"
    #hive -e "use tpch_bin_partitioned_orc_10;show tables" | xargs -I '{}' hive -e 'drop table {}'
    hadoop fs -rm -r -f /tmp/tpch-gen/${SCALE}
