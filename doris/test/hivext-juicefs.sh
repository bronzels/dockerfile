#!/bin/bash


SQL_FILE_HOME=/app/hdfs/hive
HDFS_SQL_FILE_HOME=/tmp

kubectl cp ./test.csv -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'`:${SQL_FILE_HOME}/test.csv
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- \
  hadoop fs -put ${SQL_FILE_HOME}/test.csv ${HDFS_SQL_FILE_HOME}/test.csv

  DROP DATABASE IF NOT EXISTS test;
  CREATE DATABASE IF NOT EXISTS test;
  USE test;
  DROP TABLE IF NOT EXISTS test;
  CREATE TABLE test (
  id INT,
  name VARCHAR(64)
  )
  DISTRIBUTED BY HASH(`id`) BUCKETS 1
  PROPERTIES (
  "replication_allocation" = "tag.location.default: 1");

  LOAD LABEL label_test_jfs
  (
      DATA INFILE("jfs://miniofs/tmp/test.csv")
      INTO TABLE `test`
      COLUMNS TERMINATED BY ","
      (id,name)
  )
  with BROKER dorisbroker (
      'fs.defaultFS' = 'jfs://miniofs',
      "fs.jfs.impl"="io.juicefs.JuiceFileSystem",
      "fs.AbstractFileSystem.jfs.impl"="io.juicefs.JuiceFS",
      'juicefs.meta' = 'redis://:redis@my-redis-master.redis.svc.cluster.local:6379/1',
      "juicefs.access-log"="/tmp/juicefs.access.log"

  )
  PROPERTIES
  (
      "timeout"="1200",
      "max_filter_ratio"="0.1"
  );
  SELECT * FROM test;


  DROP CATALOG hive;
  CREATE CATALOG hive PROPERTIES (
      'type'='hms',
      'hive.version' = '3.1.2',
      'hive.metastore.uris' = 'thrift://hive-service.hadoop.svc.cluster.local:9083',
      'hadoop.username' = 'hdfs',
      'fs.jfs.impl' = 'io.juicefs.JuiceFileSystem',
      'fs.AbstractFileSystem.jfs.impl' = 'io.juicefs.JuiceFS',
      'juicefs.meta' = 'redis://:redis@my-redis-master.redis.svc.cluster.local:6379/1',
      'fs.defaultFS' = 'jfs://miniofs'
  );

  SHOW CATALOGS;
+-----------+-------------+----------+-----------+
| CatalogId | CatalogName | Type     | IsCurrent |
+-----------+-------------+----------+-----------+
|     10006 | hive        | hms      |           |
|         0 | internal    | internal | yes       |
+-----------+-------------+----------+-----------+
2 rows in set (0.014 sec)

  SWITCH hive;
  SHOW DATABASES;
+------------------------------+
| Database                     |
+------------------------------+
| default                      |
| tpcds_bin_partitioned_orc_10 |
| tpcds_text_10                |
+------------------------------+
3 rows in set (0.136 sec)

  USE tpcds_bin_partitioned_orc_10;
  SHOW TABLES;
+----------------------------------------+
| Tables_in_tpcds_bin_partitioned_orc_10 |
+----------------------------------------+
| call_center                            |
| catalog_page                           |
| catalog_returns                        |
| catalog_sales                          |
| customer                               |
| customer_address                       |
| customer_demographics                  |
| date_dim                               |
| household_demographics                 |
| income_band                            |
| inventory                              |
| item                                   |
| promotion                              |
| reason                                 |
| ship_mode                              |
| store                                  |
| store_returns                          |
| store_sales                            |
| time_dim                               |
| warehouse                              |
| web_page                               |
| web_returns                            |
| web_sales                              |
| web_site                               |
+----------------------------------------+
24 rows in set (0.001 sec)

  SELECT * FROM date_dim LIMIT 5;
-- catalog未设置juicefs
ERROR 1105 (HY000): errCode = 2, detailMessage = Current catalog is not exist, please switch catalog.
-- catalog设置juicefs，启动了broker
ERROR 1105 (HY000): errCode = 2, detailMessage = failed to init reader for file jfs://miniofs/user/hive/warehouse/tpcds_bin_partitioned_orc_10.db/date_dim/000000_0, err: Open broker reader failed, broker:TNetworkAddress(
-- 先用一个label导入一个表以后，可以查询不带分区的表，有分区的hive表报错
ERROR 1105 (HY000): errCode = 2, detailMessage = get file split failed for table: web_sales, err: org.apache.doris.common.AnalysisException: errCode = 2, detailMessage = Invalid number format: __HIVE_DEFAULT_PARTITION__