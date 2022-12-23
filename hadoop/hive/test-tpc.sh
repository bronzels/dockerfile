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

kubectl cp hive-testbench -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-serv | awk '{print $1}'`:/app/hdfs/hive/hive-testbench
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-serv | awk '{print $1}'` -- bash
  cd hive-testbench
  #./tpcds-build.sh
  start=$(date +"%s.%9N")
  for SCALE in 10 50 100; do
    SCALE=10
    ./tpcds-setup.sh ${SCALE} /tmp/tpds-gen
    end=$(date +"%s.%9N")
    echo timediff:`echo "scale=9;$end - $start" | bc`
    hadoop fs -du -h /tmp/tpds-gen/10
    hadoop fs -count -q /tmp/tpds-gen/10
    echo "----------------------------------------------------------------------------------------------------------------------------------------"
    echo "use tpcds_bin_partitioned_orc_${SCALE};" > dbuse.sql
    MAX_REDUCERS=2500 # maximum number of useful reducers for any scale
    REDUCERS=$((test ${SCALE} -gt ${MAX_REDUCERS} && echo ${MAX_REDUCERS}) || echo ${SCALE})
    echo "REDUCERS:${REDUCERS}"
    start=$(date +"%s.%9N")
    for num in {1..99}
    do
      queryfile="sample-queries-tpcds/query${num}.sql"
      echo "queryfile:${queryfile}"
      hive -i dbuse.sql -i settings/load-partitioned.sql -f ${queryfile}
    done
    end=$(date +"%s.%9N")
    echo timediff:`echo "scale=9;$end - $start" | bc`

    hive -e "drop database tpcds_bin_partitioned_orc_10"
    hive -e "drop database tpcds_text_10"
    hadoop fs -rm -r -f /tmp/tpds-gen
  done
