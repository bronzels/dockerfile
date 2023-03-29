#!/bin/bash
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

WORK_HOME=${MYHOME}/workspace
PRJ_HOME=${WORK_HOME}/dockerfile

:<<EOF
engine=doris
svc=fe
EOF
engine=starrocks
svc=starrockscluster-fe-service

ts=ds
scale=10
#db=hive_tpcds_orc_10_manual_imported_few
db=test_db

#date_dim
#arr=(store_returns)
#store customer web_sales catalog_sales store_sales reason
#arr=(date_dim store_returns store customer web_sales catalog_sales store_sales reason)
arr=(call_center catalog_page catalog_returns catalog_sales customer customer_address customer_demographics date_dim household_demographics income_band inventory item promotion reason ship_mode store store_returns store_sales time_dim warehouse web_page web_returns web_sales web_site)
arr=(call_center)

torun=mpp-${engine}-ingestion-${db}
echo "DEBUG >>>>>> torun:${torun}"
csvfile=${torun}.csv
logfile=${torun}.log
echo -e "query,time" > ${csvfile}

SQL_FILE_HOME=/app/hdfs/hive
HDFS_SQL_FILE_HOME=/tmp

${PRJ_HOME}/hdfs-mkdir.sh ${SQL_FILE_HOME} ${HDFS_SQL_FILE_HOME} ${torun}

declare -A map_tbl2cols=()
map_tbl2cols["call_center"]="*"
map_tbl2cols["catalog_page"]="*"
map_tbl2cols["catalog_returns"]="cr_returned_date_sk,cr_returned_time_sk,cr_item_sk,cr_refunded_customer_sk,cr_refunded_cdemo_sk,cr_refunded_hdemo_sk,cr_refunded_addr_sk,cr_returning_customer_sk,cr_returning_cdemo_sk,cr_returning_hdemo_sk,cr_returning_addr_sk,cr_call_center_sk,cr_catalog_page_sk,cr_ship_mode_sk,cr_warehouse_sk,cr_reason_sk,cr_order_number,cr_return_quantity,cr_return_amount,cr_return_tax,cr_return_amt_inc_tax,cr_fee,cr_return_ship_cost,cr_refunded_cash,cr_reversed_charge,cr_store_credit,cr_net_loss"
#COALESCE(\`cs_sold_date_sk\`, 0),
#map_tbl2cols["catalog_sales"]="\`cs_sold_time_sk\`,\`cs_ship_date_sk\`,\`cs_bill_customer_sk\`,\`cs_bill_cdemo_sk\`,\`cs_bill_hdemo_sk\`,\`cs_bill_addr_sk\`,\`cs_ship_customer_sk\`,\`cs_ship_cdemo_sk\`,\`cs_ship_hdemo_sk\`,\`cs_ship_addr_sk\`,\`cs_call_center_sk\`,\`cs_catalog_page_sk\`,\`cs_ship_mode_sk\`,\`cs_warehouse_sk\`,\`cs_item_sk\`,\`cs_promo_sk\`,\`cs_order_number\`,\`cs_quantity\`,\`cs_wholesale_cost\`,\`cs_list_price\`,\`cs_sales_price\`,\`cs_ext_discount_amt\`,\`cs_ext_sales_price\`,\`cs_ext_wholesale_cost\`,\`cs_ext_list_price\`,\`cs_ext_tax\`,\`cs_coupon_amt\`,\`cs_ext_ship_cost\`,\`cs_net_paid\`,\`cs_net_paid_inc_tax\`,\`cs_net_paid_inc_ship\`,\`cs_net_paid_inc_ship_tax\`,\`cs_net_profit\`"
map_tbl2cols["catalog_sales"]="\`cs_sold_date_sk\`,\`cs_sold_time_sk\`,\`cs_ship_date_sk\`,\`cs_bill_customer_sk\`,\`cs_bill_cdemo_sk\`,\`cs_bill_hdemo_sk\`,\`cs_bill_addr_sk\`,\`cs_ship_customer_sk\`,\`cs_ship_cdemo_sk\`,\`cs_ship_hdemo_sk\`,\`cs_ship_addr_sk\`,\`cs_call_center_sk\`,\`cs_catalog_page_sk\`,\`cs_ship_mode_sk\`,\`cs_warehouse_sk\`,\`cs_item_sk\`,\`cs_promo_sk\`,\`cs_order_number\`,\`cs_quantity\`,\`cs_wholesale_cost\`,\`cs_list_price\`,\`cs_sales_price\`,\`cs_ext_discount_amt\`,\`cs_ext_sales_price\`,\`cs_ext_wholesale_cost\`,\`cs_ext_list_price\`,\`cs_ext_tax\`,\`cs_coupon_amt\`,\`cs_ext_ship_cost\`,\`cs_net_paid\`,\`cs_net_paid_inc_tax\`,\`cs_net_paid_inc_ship\`,\`cs_net_paid_inc_ship_tax\`,\`cs_net_profit\`"
map_tbl2cols["customer"]="*"
map_tbl2cols["customer_address"]="*"
map_tbl2cols["customer_demographics"]="*"
map_tbl2cols["date_dim"]="*"
map_tbl2cols["household_demographics"]="*"
map_tbl2cols["income_band"]="*"
map_tbl2cols["inventory"]="*"
map_tbl2cols["item"]="*"
map_tbl2cols["promotion"]="*"
map_tbl2cols["reason"]="*"
map_tbl2cols["ship_mode"]="*"
map_tbl2cols["store"]="*"
#COALESCE(\`sr_returned_date_sk\`, 0),
#map_tbl2cols["store_returns"]="\`sr_return_time_sk\`,\`sr_item_sk\`,\`sr_customer_sk\`,\`sr_cdemo_sk\`,\`sr_hdemo_sk\`,\`sr_addr_sk\`,\`sr_store_sk\`,\`sr_reason_sk\`,\`sr_ticket_number\`,\`sr_return_quantity\`,\`sr_return_amt\`,\`sr_return_tax\`,\`sr_return_amt_inc_tax\`,\`sr_fee\`,\`sr_return_ship_cost\`,\`sr_refunded_cash\`,\`sr_reversed_charge\`,\`sr_store_credit\`,\`sr_net_loss\`"
map_tbl2cols["store_returns"]="\`sr_returned_date_sk\`,\`sr_return_time_sk\`,\`sr_item_sk\`,\`sr_customer_sk\`,\`sr_cdemo_sk\`,\`sr_hdemo_sk\`,\`sr_addr_sk\`,\`sr_store_sk\`,\`sr_reason_sk\`,\`sr_ticket_number\`,\`sr_return_quantity\`,\`sr_return_amt\`,\`sr_return_tax\`,\`sr_return_amt_inc_tax\`,\`sr_fee\`,\`sr_return_ship_cost\`,\`sr_refunded_cash\`,\`sr_reversed_charge\`,\`sr_store_credit\`,\`sr_net_loss\`"
#COALESCE(\`ss_sold_date_sk\`, 0),
#map_tbl2cols["store_sales"]="\`ss_sold_time_sk\`,\`ss_item_sk\`,\`ss_customer_sk\`,\`ss_cdemo_sk\`,\`ss_hdemo_sk\`,\`ss_addr_sk\`,\`ss_store_sk\`,\`ss_promo_sk\`,\`ss_ticket_number\`,\`ss_quantity\`,\`ss_wholesale_cost\`,\`ss_list_price\`,\`ss_sales_price\`,\`ss_ext_discount_amt\`,\`ss_ext_sales_price\`,\`ss_ext_wholesale_cost\`,\`ss_ext_list_price\`,\`ss_ext_tax\`,\`ss_coupon_amt\`,\`ss_net_paid\`,\`ss_net_paid_inc_tax\`,\`ss_net_profit\`"
map_tbl2cols["store_sales"]="\`ss_sold_date_sk\`,\`ss_sold_time_sk\`,\`ss_item_sk\`,\`ss_customer_sk\`,\`ss_cdemo_sk\`,\`ss_hdemo_sk\`,\`ss_addr_sk\`,\`ss_store_sk\`,\`ss_promo_sk\`,\`ss_ticket_number\`,\`ss_quantity\`,\`ss_wholesale_cost\`,\`ss_list_price\`,\`ss_sales_price\`,\`ss_ext_discount_amt\`,\`ss_ext_sales_price\`,\`ss_ext_wholesale_cost\`,\`ss_ext_list_price\`,\`ss_ext_tax\`,\`ss_coupon_amt\`,\`ss_net_paid\`,\`ss_net_paid_inc_tax\`,\`ss_net_profit\`"
map_tbl2cols["time_dim"]="*"
map_tbl2cols["warehouse"]="*"
map_tbl2cols["web_page"]="*"
#COALESCE(\`ws_sold_date_sk\`, 0),
#map_tbl2cols["web_sales"]="\`ws_sold_time_sk\`,\`ws_ship_date_sk\`,\`ws_item_sk\`,\`ws_bill_customer_sk\`,\`ws_bill_cdemo_sk\`,\`ws_bill_hdemo_sk\`,\`ws_bill_addr_sk\`,\`ws_ship_customer_sk\`,\`ws_ship_cdemo_sk\`,\`ws_ship_hdemo_sk\`,\`ws_ship_addr_sk\`,\`ws_web_page_sk\`,\`ws_web_site_sk\`,\`ws_ship_mode_sk\`,\`ws_warehouse_sk\`,\`ws_promo_sk\`,\`ws_order_number\`,\`ws_quantity\`,\`ws_wholesale_cost\`,\`ws_list_price\`,\`ws_sales_price\`,\`ws_ext_discount_amt\`,\`ws_ext_sales_price\`,\`ws_ext_wholesale_cost\`,\`ws_ext_list_price\`,\`ws_ext_tax\`,\`ws_coupon_amt\`,\`ws_ext_ship_cost\`,\`ws_net_paid\`,\`ws_net_paid_inc_tax\`,\`ws_net_paid_inc_ship\`,\`ws_net_paid_inc_ship_tax\`,\`ws_net_profit\`"
map_tbl2cols["web_returns"]="wr_returned_date_sk,wr_returned_time_sk,wr_item_sk,wr_refunded_customer_sk,wr_refunded_cdemo_sk,wr_refunded_hdemo_sk,wr_refunded_addr_sk,wr_returning_customer_sk,wr_returning_cdemo_sk,wr_returning_hdemo_sk,wr_returning_addr_sk,wr_web_page_sk,wr_reason_sk,wr_order_number,wr_return_quantity,wr_return_amt,wr_return_tax,wr_return_amt_inc_tax,wr_fee,wr_return_ship_cost,wr_refunded_cash,wr_reversed_charge,wr_account_credit,wr_net_loss"
map_tbl2cols["web_sales"]="\`ws_sold_date_sk\`,\`ws_sold_time_sk\`,\`ws_ship_date_sk\`,\`ws_item_sk\`,\`ws_bill_customer_sk\`,\`ws_bill_cdemo_sk\`,\`ws_bill_hdemo_sk\`,\`ws_bill_addr_sk\`,\`ws_ship_customer_sk\`,\`ws_ship_cdemo_sk\`,\`ws_ship_hdemo_sk\`,\`ws_ship_addr_sk\`,\`ws_web_page_sk\`,\`ws_web_site_sk\`,\`ws_ship_mode_sk\`,\`ws_warehouse_sk\`,\`ws_promo_sk\`,\`ws_order_number\`,\`ws_quantity\`,\`ws_wholesale_cost\`,\`ws_list_price\`,\`ws_sales_price\`,\`ws_ext_discount_amt\`,\`ws_ext_sales_price\`,\`ws_ext_wholesale_cost\`,\`ws_ext_list_price\`,\`ws_ext_tax\`,\`ws_coupon_amt\`,\`ws_ext_ship_cost\`,\`ws_net_paid\`,\`ws_net_paid_inc_tax\`,\`ws_net_paid_inc_ship\`,\`ws_net_paid_inc_ship_tax\`,\`ws_net_profit\`"
map_tbl2cols["web_site"]="*"
echo "${map_tbl2cols[@]}"
echo "${!map_tbl2cols[@]}"

:<<EOF
declare -A map_tbl2pt=()
map_tbl2pt["date_dim"]=""
map_tbl2pt["store_returns"]="sr_returned_date_sk"
map_tbl2pt["store"]=""
map_tbl2pt["customer"]=""
map_tbl2pt["web_sales"]="ws_sold_date_sk"
map_tbl2pt["catalog_sales"]="cs_sold_date_sk"
map_tbl2pt["store_sales"]="ss_sold_date_sk"
map_tbl2pt["reason"]=""
echo "${map_tbl2pt[@]}"
echo "${!map_tbl2pt[@]}"
EOF

shfile=spark-sql-delta.sh
SPARK_JOB_HOME=/app/hdfs/spark/work-dir

kubectl exec -it -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep spark-client | awk '{print $1}'` -- \
  curl http://be-domain-search.doris.svc.cluster.local:8040

kubectl exec -it -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep spark-client | awk '{print $1}'` -- \
  curl http://starrockscluster-fe-service.doris.svc.cluster.local:8030

kubectl exec -it -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep spark-client | awk '{print $1}'` -- rm -f *.delta
${PRJ_HOME}/client-upload.sh spark-operator spark-client ${SPARK_JOB_HOME} ${shfile}


for tbl in ${arr[*]}
do
  sqlfile=${tbl}.sql
  echo "use tpc${ts}_bin_partitioned_orc_${scale};" > ${sqlfile}
  doris_view=${engine}_${db}_${tbl}
  echo "DEBUG >>>>>> doris_view:${doris_view}"

  cols=${map_tbl2cols["${tbl}"]}
  echo "DEBUG >>>>>> cols:${cols}"
  pt=${map_tbl2pt["${tbl}"]}
  echo "DEBUG >>>>>> pt:${pt}"
cat << EOF >> ${sqlfile}
CREATE TEMPORARY VIEW ${doris_view}
USING ${engine}
OPTIONS(
"table.identifier"="${db}.${tbl}",
EOF
  if [[ ${engine} == "starrocks" ]]; then
cat << EOF >> ${sqlfile}
"benodes"="be-domain-search.doris.svc.cluster.local:8040",
EOF
  fi
cat << EOF >> ${sqlfile}
"fenodes"="${svc}.doris.svc.cluster.local:8030",
"user"="root",
"password"=""
)
;
-- TRUNCATE TABLE ${doris_view};
-- SET spark.sql.hive.convertMetastoreOrc=false;
-- SELECT * FROM ${doris_view};
INSERT INTO ${doris_view}
EOF
:<<EOF
  if [[ -z "${pt}" ]]; then
      selectstr="SELECT ${cols} FROM ${tbl};"
  else
      selectstr="SELECT \`${pt}\`,${cols} FROM ${tbl} WHERE \`${pt}\` IS NOT NULL UNION SELECT 631152000000,${cols} FROM ${tbl} WHERE \`${pt}\` IS  NULL;"
  fi
EOF
  selectstr="SELECT ${cols} FROM ${tbl};"
  echo "${selectstr}" >> ${sqlfile}

  #cat ${sqlfile}
  kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- rm -f ${SQL_FILE_HOME}/${torun}/${sqlfile}
  kubectl cp ${sqlfile} -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'`:${SQL_FILE_HOME}/${torun}/${sqlfile}
  rm -f ${sqlfile}

  kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- \
    hadoop fs -rm -f ${SQL_FILE_HOME}/${torun}/${sqlfile} ${HDFS_SQL_FILE_HOME}/${torun}/${sqlfile}
  kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- \
    hadoop fs -put ${SQL_FILE_HOME}/${torun}/${sqlfile} ${HDFS_SQL_FILE_HOME}/${torun}/${sqlfile}
  sqlfile_path=${HDFS_SQL_FILE_HOME}/${torun}/${sqlfile}
  kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- \
    hadoop fs -cat ${sqlfile_path}

  echo "DEBUG >>>>>> sqlfile_path:${sqlfile_path}"
  name=`echo ${sqlfile_path}|$SED 's/\\//\-/g'|$SED 's/\./\-/g'|$SED '1,/\-/s/\-//'`
  echo "DEBUG >>>>>> name:${name}"

  kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep doris-fe-0 | awk '{print $1}'` -- \
    mysql --default-character-set=utf8 -h fe -P 9030 -u'root' -e "USE ${db};TRUNCATE TABLE ${tbl};"
  kubectl exec -it -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep spark-client | awk '{print $1}'` -- ${SPARK_JOB_HOME}/${shfile} ${sqlfile_path}
  # > submit-${tbl}-${logfile}  2>&1
  kubectl cp -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep spark-client | awk '{print $1}'`:${SPARK_JOB_HOME}/${name}.delta ./${name}.delta
  cat ${name}.delta >> ${csvfile}
  rm -f ${name}.delta

done


for tbl in ${arr[*]}
do
  sqlfile=${tbl}.sql

  sqlfile_path=${HDFS_SQL_FILE_HOME}/${torun}/${sqlfile}

  name=`echo ${sqlfile_path}|$SED 's/\\//\-/g'|$SED 's/\./\-/g'|$SED '1,/\-/s/\-//'`
  echo "DEBUG >>>>>> name:${name}"
  jobname=`echo ${name}|$SED 's/_/\-/g'`
  echo "DEBUG >>>>>> jobname:${jobname}"

  kubectl logs -n spark-operator `kubectl get pod -n spark-operator | grep ${jobname} | awk '{print $1}'`
  kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep fe-0 | awk '{print $1}'` -- \
    mysql --default-character-set=utf8 -h ${svc} -P 9030 -u'root' -e "USE ${db};SELECT COUNT(1) FROM ${tbl};"
done

kubectl logs -n spark-operator `kubectl get pod -n spark-operator|grep tmp-mpp-${engine}-ingestion |grep 'Error' |awk '{print $1}'`

kubectl get pod -n spark-operator|grep tmp-mpp-${engine}-ingestion
kubectl get pod -n spark-operator|grep tmp-mpp-${engine}-ingestion |grep 'Error' |awk '{print $1}'| xargs kubectl delete pod "$1" -n spark-operator --force --grace-period=0
kubectl get pod -n spark-operator|grep tmp-mpp-${engine}-ingestion |grep -v 'Running' |awk '{print $1}'| xargs kubectl delete pod "$1" -n spark-operator --force --grace-period=0
kubectl get pod -n spark-operator|grep tmp-mpp-${engine}-ingestion |grep -v 'Running\|ContainerCreating\Pending' |awk '{print $1}'| xargs kubectl delete pod "$1" -n spark-operator --force --grace-period=0

kubectl exec -it -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep spark-client | awk '{print $1}'` -- tail -f submit-${tbl}-${logfile}
kubectl exec -it -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep spark-client | awk '{print $1}'` -- tail -f driver-${tbl}-${logfile}

kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- \
  hadoop fs -ls ${HDFS_SQL_FILE_HOME}/${torun}
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- \
  hadoop fs -cat ${HDFS_SQL_FILE_HOME}/${torun}/${sqlfile}

kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep fe-0 | awk '{print $1}'` --   mysql --default-character-set=utf8 -h ${svc} -P 9030 -u'root' -e "USE ${db};SHOW CREATE TABLE call_center;"
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` --   hive -e"USE tpc${ts}_bin_partitioned_orc_${scale};SHOW CREATE TABLE call_center;"
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` --   hive -e"USE tpc${ts}_bin_partitioned_orc_${scale};SELECT * FROM call_center LIMIT 1;"
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep fe-0 | awk '{print $1}'` --  \
  mysql --default-character-set=utf8 -h ${svc} -P 9030 -u'root' \
    -e 'USE test_db;INSERT INTO call_center VALUES (1,  "AAAAAAAABAAAAAAA",     "1998-01-01",   NULL,   NULL,   2450952,        "NY Metro",     "large",        135,    76815,  "8AM-4PM",              "Bob Belcher",  6,      "More than other authori",                              "Shared others could not count fully dollars. New members ca",  "Julius Tran",  3,      "pri",  6,      "cally",                                                730,            "Ash Hill",     "Boulevard",            "Suite 0",      "Pleasant Hill",        "Williamson County",    "TN",   33604,          "United States",        -5.00,  0.11);'
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep fe-0 | awk '{print $1}'` --  \
  mysql --default-character-set=utf8 -h ${svc} -P 9030 -u'root' -e "USE ${db};SELECT * FROM call_center;"
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep fe-0 | awk '{print $1}'` --  \
  mysql --default-character-set=utf8 -h ${svc} -P 9030 -u'root' \
    -e 'USE test_db;TRUNCATE TABLE call_center;'
