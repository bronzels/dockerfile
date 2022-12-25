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
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- bash
  cd hive-testbench
  #for SCALE in 10 50 100; do
  for ts in ds h; do
    for SCALE in 5 10 20; do
      echo "ts:${ts}"
      echo "SCALE:${SCALE}"
      #SCALE=20
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
      echo "REDUCERS:${REDUCERS}"queries
      if [[ "${ts}" =~ "ds" ]]; then
        nummax=99
      else
        nummax=22
      fi
      echo "nummax:${nummax}"
      for num in {1..${nummax}}
      do
        if [[ "${ts}" =~ "ds" ]]; then
          queryfile="sample-queries-tpc${ts}/query${num}.sql"
        else
          queryfile="sample-queries-tpc${ts}/tpch_query${num}.sql"
        fi
        echo "queryfile:${queryfile}"
        start=$(date +"%s.%9N")
        #hive --hivevar REDUCERS=${REDUCERS} -i dbuse.sql -i settings/load-partitioned.sql -f ${queryfile}
        hive --hivevar REDUCERS=${REDUCERS} -i dbuse.sql -f ${queryfile}
        end=$(date +"%s.%9N")
        echo timediff:`echo "scale=9;$end - $start" | bc`
        echo "----------------------------------------------------------------------------------------------------------------------------------------"
      done

      hive -e "DROP DATABASE IF EXISTS tpc${ts}_bin_partitioned_orc_${SCALE} CASCADE"
      hive -e "DROP DATABASE IF EXISTS tpc${ts}_text_${SCALE} CASCADE"
      #hive -e "use tpcds_bin_partitioned_orc_10;show tables" | xargs -I '{}' hive -e 'drop table {}'
      hadoop fs -rm -r -f /tmp/tpc${ts}-gen/${SCALE}
    done
  done
