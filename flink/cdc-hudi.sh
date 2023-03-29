#!/usr/bin/env bash
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

PRJ_FLINK_HOME=${PRJ_HOME}/flink

FLINK_VERSION=1.15.4
FLINK_SHORT_VERSION=1.15

:<<EOF
FLINK_VERSION=1.16.1
FLINK_SHORT_VERSION=1.16


FLINK_VERSION=1.15.3
FLINK_SHORT_VERSION=1.15

FLINK_VERSION=1.14.0
FLINK_VERSION=1.14.6
FLINK_SHORT_VERSION=1.14

EOF

#HUDI_VERSION=0.12.2
#1.16.1 only support hudi 0.13.0
HUDI_VERSION=0.13.0

CDC_VERSION=2.3.0

cd ${PRJ_FLINK_HOME}



kubectl apply -f flink-client.yaml -n flink

kubectl delete -f flink-client.yaml -n flink
kubectl delete deployments.apps -n flink cdc-hudi-test-basic
kubectl get pod -n flink |grep -v Running |awk '{print $1}'| xargs kubectl delete pod "$1" -n flink --force --grace-period=0

kubectl get pod -n flink
watch kubectl get pod -n flink

NONAME=taskmanager
SESSION=cdc-hudi-test-basic

FLINK_VERSION=1.15.4
TARGET_BUILT=hadoop3hive3
kubectl exec -it -n flink `kubectl get pod -n flink | grep flink-client | awk '{print $1}'` -- \
 kubernetes-session.sh \
    -Dexecution.attached=true \
    -Dkubernetes.namespace=flink \
    -Dkubernetes.cluster-id=${SESSION} \
    -Dkubernetes.container.image=harbor.my.org:1080/flink/flink-juicefs-${TARGET_BUILT}:${FLINK_VERSION} \
    -Djobmanager.memory.process.size=2048m \
    -Dkubernetes.jobmanager.cpu=1 \
    -Dtaskmanager.memory.process.size=2048m \
    -Dkubernetes.taskmanager.cpu=1 \
    -Dtaskmanager.numberOfTaskSlots=2

kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- hive -e"CREATE DATABASE hudi_mydb"
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- hadoop fs -mkdir -p /flinkhudi/mydb/products
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- hadoop fs -mkdir -p /flinkhudi/mydb/orders

flink cancel --target kubernetes-application -Dkubernetes.cluster-id=cdc-hudi-test-basic -Dkubernetes.namespace=flink e39da90de4ee874f2d946644ca261172
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- hadoop fs -rm -r -f /flinkhudi/mydb/products

kubectl exec -it -n flink `kubectl get pod -n flink | grep cdc-hudi-test-basic | awk '{print $1}'` -- sql-client.sh embedded
  SET execution.checkpointing.interval = 3s;
  -- SET table.local-time-zone=Asia/Shanghai;
  CREATE CATALOG hive WITH (
      'type' = 'hive',
      'default-database' = 'default',
      'hive-conf-dir' = '/opt/flink/hiveconf',
      'hadoop-conf-dir'='/opt/hadoop/conf'
  );

  -- set the HiveCatalog as the current catalog of the session
  USE CATALOG hive;
  CREATE DATABASE flink_mydb;
  USE flink_mydb;

  CREATE TABLE products_cdc_source (
      id INT,
      name STRING,
      description STRING,
      dt VARCHAR(10),
      PRIMARY KEY (id) NOT ENFORCED
    ) WITH (
    'connector' = 'mysql-cdc',
    'server-time-zone' = 'Asia/Shanghai',
    'scan.incremental.snapshot.enabled'='true',
    'hostname' = '192.168.3.9',
    'port' = '3306',
    'username' = 'flink',
    'password' = 'flinkpw',
    'database-name' = 'mydb',
    'table-name' = 'products'
    );

  CREATE TABLE printer (
      id INT,
      name STRING,
      description STRING
    ) WITH (
      'connector' = 'print'
    );
  INSERT INTO printer SELECT * FROM products;


  CREATE TABLE products_hudi_sink(
      id BIGINT NOT NULL PRIMARY KEY NOT ENFORCED,
      name STRING,
      description STRING,
      dt VARCHAR(10)
    )
      PARTITIONED BY (`dt`)
      WITH (
    'connector' = 'hudi',
    'path' = 'jfs://miniofs/flinkhudi/mydb/products',
    'table.type' = 'MERGE_ON_READ',
    'changelog.enabled' = 'true',
    'hoodie.datasource.write.recordkey.field' = 'id',
    'write.precombine.field' = 'name',
    'compaction.async.enabled' = 'false'
  );
  INSERT INTO products_hudi_sinker SELECT * FROM products;
:<<EOF
1，无hive sync
[INFO] Submitting SQL update statement to the cluster...
[INFO] SQL update statement has been successfully submitted to the cluster:
Job ID: d3df5839a2607d3ddd739050f16acca8
  SELECT * FROM products_hudi_sinker;
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- hadoop fs -ls /flinkhudi/mydb/products
:<<EOF
2023-03-17 10:48:22,742 INFO fs.TrashPolicyDefault: The configured checkpoint interval is 0 minutes. Using an interval of 0 minutes that is used for deletion instead
2023-03-17 10:48:22,742 INFO fs.TrashPolicyDefault: Namenode trash configuration: Deletion interval = 0 minutes, Emptier interval = 0 minutes.
Found 3 items
-rw-r--r--   1 hdfs supergroup       2109 2023-03-17 10:47 /flinkhudi/mydb/products/.303f8506-876f-403f-bfcf-5dfd161fd29a_20230317184716641.log.1_0-1-0
drwxr-xr-x   - hdfs supergroup       4096 2023-03-17 10:47 /flinkhudi/mydb/products/.hoodie
-rw-r--r--   1 hdfs supergroup        102 2023-03-17 10:47 /flinkhudi/mydb/products/.hoodie_partition_metadata
EOF

  USE CATALOG hive;
  USE flink_mydb;
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- hive -e "CREATE DATABASE hudi_mydb"
  CREATE TABLE products_hudi_sink(
      id BIGINT NOT NULL PRIMARY KEY NOT ENFORCED,
      name STRING,
      description STRING,
      dt VARCHAR(10)
    )
      PARTITIONED BY (`dt`)
      WITH (
    'connector' = 'hudi',
    'path' = 'jfs://miniofs/flinkhudi/mydb/products',
    'table.type' = 'MERGE_ON_READ',
    'changelog.enabled' = 'true',
    'hoodie.datasource.write.recordkey.field' = 'id',
    'write.precombine.field' = 'name',
    'hoodie.datasource.write.keygenerator.class' = 'org.apache.hudi.keygen.ComplexAvroKeyGenerator',
    'hoodie.datasource.write.hive_style_partitioning' = 'true',
    'compaction.async.enabled' = 'false',
    'hive_sync.enable' = 'true',
    'hive_sync.mode' = 'hms',
    'hive_sync.db' = 'hudi_mydb',
    'hive_sync.table' = 'products',
    'hive_sync.partition_fields' = 'dt',
    'hive_sync.partition_extractor_class' = 'org.apache.hudi.hive.HiveStylePartitionValueExtractor'
  );
  INSERT INTO hive.flink_mydb.products_hudi_sink SELECT * FROM hive.flink_mydb.products_cdc_source;
  SELECT * FROM hive.flink_mydb.products_hudi_sink;
:<<EOF
WARNING: An illegal reflective access operation has occurred
WARNING: Illegal reflective access by org.apache.hudi.org.apache.hadoop.hbase.util.UnsafeAvailChecker (file:/opt/flink/lib/hudi-flink1.15-bundle-0.12.2.jar) to method java.nio.Bits.unaligned()
WARNING: Please consider reporting this to the maintainers of org.apache.hudi.org.apache.hadoop.hbase.util.UnsafeAvailChecker
WARNING: Use --illegal-access=warn to enable warnings of further illegal reflective access operations
WARNING: All illegal access operations will be denied in a future release
[INFO] Result retrieval cancelled.
  SELECT * FROM products_hudi_sinker;
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- hadoop fs -ls /flinkhudi/mydb/products
2023-03-18 03:34:45,297 INFO fs.TrashPolicyDefault: The configured checkpoint interval is 0 minutes. Using an interval of 0 minutes that is used for deletion instead
2023-03-18 03:34:45,297 INFO fs.TrashPolicyDefault: Namenode trash configuration: Deletion interval = 0 minutes, Emptier interval = 0 minutes.
Found 4 items
drwxr-xr-x   - hdfs supergroup       4096 2023-03-18 03:25 /flinkhudi/mydb/products/.hoodie
drwxr-xr-x   - hdfs supergroup       4096 2023-03-18 03:25 /flinkhudi/mydb/products/dt=20201214
drwxr-xr-x   - hdfs supergroup       4096 2023-03-18 03:25 /flinkhudi/mydb/products/dt=20211214
drwxr-xr-x   - hdfs supergroup       4096 2023-03-18 03:25 /flinkhudi/mydb/products/dt=20221214
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- hive -e "USE hudi_mydb;SHOW TABLES;"
Hive Session ID = a625f412-92e2-48b9-bac0-4073298e4f7b
OK
Time taken: 0.76 seconds
OK
Time taken: 0.077 seconds

jobmanager日志
11:25:03.597 [pool-17-thread-1] ERROR org.apache.hudi.sink.StreamWriteOperatorCoordinator - Executor executes action [sync hive metadata for instant 20230318112503504] error
java.lang.NoClassDefFoundError: org/apache/calcite/plan/RelOptRule
	at org.apache.hudi.hive.ddl.HMSDDLExecutor.<init>(HMSDDLExecutor.java:81) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.hive.HoodieHiveSyncClient.<init>(HoodieHiveSyncClient.java:85) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.hive.HiveSyncTool.initSyncClient(HiveSyncTool.java:102) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.hive.HiveSyncTool.<init>(HiveSyncTool.java:96) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.sink.utils.HiveSyncContext.hiveSyncTool(HiveSyncContext.java:80) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.sink.StreamWriteOperatorCoordinator.doSyncHive(StreamWriteOperatorCoordinator.java:336) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.sink.utils.NonThrownExecutor.lambda$wrapAction$0(NonThrownExecutor.java:130) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at java.util.concurrent.ThreadPoolExecutor.runWorker(Unknown Source) [?:?]
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(Unknown Source) [?:?]
	at java.lang.Thread.run(Unknown Source) [?:?]
Caused by: java.lang.ClassNotFoundException: org.apache.calcite.plan.RelOptRule
	at jdk.internal.loader.BuiltinClassLoader.loadClass(Unknown Source) ~[?:?]
	at jdk.internal.loader.ClassLoaders$AppClassLoader.loadClass(Unknown Source) ~[?:?]
	at java.lang.ClassLoader.loadClass(Unknown Source) ~[?:?]
	... 10 more

taskmanager日志
11:38:05.826 [pool-6-thread-1] ERROR org.apache.hudi.sink.CleanFunction - Executor executes action [wait for cleaning finish] error
org.apache.hudi.exception.HoodieException: Error waiting for async clean service to finish
	at org.apache.hudi.async.AsyncCleanerService.waitForCompletion(AsyncCleanerService.java:77) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.client.HoodieFlinkWriteClient.waitForCleaningFinish(HoodieFlinkWriteClient.java:332) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.sink.CleanFunction.lambda$notifyCheckpointComplete$1(CleanFunction.java:75) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.sink.utils.NonThrownExecutor.lambda$wrapAction$0(NonThrownExecutor.java:130) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at java.util.concurrent.ThreadPoolExecutor.runWorker(Unknown Source) [?:?]
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(Unknown Source) [?:?]
	at java.lang.Thread.run(Unknown Source) [?:?]
Caused by: java.util.concurrent.ExecutionException: java.lang.NoSuchMethodError: 'void org.apache.hudi.org.apache.avro.specific.SpecificRecordBuilderBase.<init>(org.apache.hudi.org.apache.avro.Schema, org.apache.hudi.org.apache.avro.specific.SpecificData)'
	at java.util.concurrent.CompletableFuture.reportGet(Unknown Source) ~[?:?]
	at java.util.concurrent.CompletableFuture.get(Unknown Source) ~[?:?]
	at org.apache.hudi.async.HoodieAsyncService.waitForShutdown(HoodieAsyncService.java:103) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.async.AsyncCleanerService.waitForCompletion(AsyncCleanerService.java:75) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	... 6 more
Caused by: java.lang.NoSuchMethodError: 'void org.apache.hudi.org.apache.avro.specific.SpecificRecordBuilderBase.<init>(org.apache.hudi.org.apache.avro.Schema, org.apache.hudi.org.apache.avro.specific.SpecificData)'
	at org.apache.hudi.avro.model.HoodieCleanerPlan$Builder.<init>(HoodieCleanerPlan.java:325) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.avro.model.HoodieCleanerPlan$Builder.<init>(HoodieCleanerPlan.java:309) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.avro.model.HoodieCleanerPlan.newBuilder(HoodieCleanerPlan.java:276) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.table.action.clean.CleanPlanActionExecutor.requestClean(CleanPlanActionExecutor.java:110) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.table.action.clean.CleanPlanActionExecutor.requestClean(CleanPlanActionExecutor.java:148) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.table.action.clean.CleanPlanActionExecutor.execute(CleanPlanActionExecutor.java:173) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.table.HoodieFlinkCopyOnWriteTable.scheduleCleaning(HoodieFlinkCopyOnWriteTable.java:311) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.client.BaseHoodieWriteClient.scheduleTableServiceInternal(BaseHoodieWriteClient.java:1367) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.client.BaseHoodieWriteClient.clean(BaseHoodieWriteClient.java:878) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.client.BaseHoodieWriteClient.clean(BaseHoodieWriteClient.java:840) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.async.AsyncCleanerService.lambda$startService$0(AsyncCleanerService.java:55) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at java.util.concurrent.CompletableFuture$AsyncSupply.run(Unknown Source) ~[?:?]
	... 3 more
EOF
    'hive_sync.conf.dir'='/opt/flink/hiveconf', 
    -- 加了也没用
#自己编译的hadoop3/hive3
#jobmanager
21:40:09.408 [pool-9-thread-1] ERROR org.apache.hudi.sink.StreamWriteOperatorCoordinator - Executor executes action [sync hive metadata for instant 20230320214008431] error
java.lang.NoSuchMethodError: org.apache.parquet.schema.Types$PrimitiveBuilder.as(Lorg/apache/parquet/schema/LogicalTypeAnnotation;)Lorg/apache/parquet/schema/Types$Builder;
	at org.apache.parquet.avro.AvroSchemaConverter.convertField(AvroSchemaConverter.java:177) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.parquet.avro.AvroSchemaConverter.convertUnion(AvroSchemaConverter.java:242) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.parquet.avro.AvroSchemaConverter.convertField(AvroSchemaConverter.java:199) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.parquet.avro.AvroSchemaConverter.convertField(AvroSchemaConverter.java:152) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.parquet.avro.AvroSchemaConverter.convertField(AvroSchemaConverter.java:260) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.parquet.avro.AvroSchemaConverter.convertFields(AvroSchemaConverter.java:146) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.parquet.avro.AvroSchemaConverter.convert(AvroSchemaConverter.java:137) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.common.table.TableSchemaResolver.readSchemaFromLogFile(TableSchemaResolver.java:500) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.common.table.TableSchemaResolver.readSchemaFromLogFile(TableSchemaResolver.java:483) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.common.table.TableSchemaResolver.fetchSchemaFromFiles(TableSchemaResolver.java:631) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.common.table.TableSchemaResolver.getTableParquetSchemaFromDataFile(TableSchemaResolver.java:266) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.common.table.TableSchemaResolver.getTableAvroSchemaFromDataFile(TableSchemaResolver.java:119) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.common.table.TableSchemaResolver.hasOperationField(TableSchemaResolver.java:564) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.util.Lazy.get(Lazy.java:53) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.common.table.TableSchemaResolver.getTableSchemaFromLatestCommitMetadata(TableSchemaResolver.java:223) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.common.table.TableSchemaResolver.getTableAvroSchemaInternal(TableSchemaResolver.java:191) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.common.table.TableSchemaResolver.getTableAvroSchema(TableSchemaResolver.java:140) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.common.table.TableSchemaResolver.getTableParquetSchema(TableSchemaResolver.java:171) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.sync.common.HoodieSyncClient.getStorageSchema(HoodieSyncClient.java:101) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.hive.HiveSyncTool.syncHoodieTable(HiveSyncTool.java:204) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.hive.HiveSyncTool.doSync(HiveSyncTool.java:158) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.hive.HiveSyncTool.syncHoodieTable(HiveSyncTool.java:142) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.sink.StreamWriteOperatorCoordinator.doSyncHive(StreamWriteOperatorCoordinator.java:336) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.sink.utils.NonThrownExecutor.lambda$wrapAction$0(NonThrownExecutor.java:130) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149) [?:1.8.0_362]
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624) [?:1.8.0_362]
	at java.lang.Thread.run(Thread.java:750) [?:1.8.0_362]
#taskmanager
21:40:08.873 [pool-6-thread-1] ERROR org.apache.hudi.sink.CleanFunction - Executor executes action [wait for cleaning finish] error
org.apache.hudi.exception.HoodieException: Error waiting for async clean service to finish
	at org.apache.hudi.async.AsyncCleanerService.waitForCompletion(AsyncCleanerService.java:77) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.client.HoodieFlinkWriteClient.waitForCleaningFinish(HoodieFlinkWriteClient.java:332) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.sink.CleanFunction.lambda$notifyCheckpointComplete$1(CleanFunction.java:75) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.sink.utils.NonThrownExecutor.lambda$wrapAction$0(NonThrownExecutor.java:130) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149) [?:1.8.0_362]
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624) [?:1.8.0_362]
	at java.lang.Thread.run(Thread.java:750) [?:1.8.0_362]
Caused by: java.util.concurrent.ExecutionException: java.lang.NoSuchMethodError: org.apache.hudi.org.apache.avro.specific.SpecificRecordBuilderBase.<init>(Lorg/apache/hudi/org/apache/avro/Schema;Lorg/apache/hudi/org/apache/avro/specific/SpecificData;)V
	at java.util.concurrent.CompletableFuture.reportGet(CompletableFuture.java:357) ~[?:1.8.0_362]
	at java.util.concurrent.CompletableFuture.get(CompletableFuture.java:1908) ~[?:1.8.0_362]
	at org.apache.hudi.async.HoodieAsyncService.waitForShutdown(HoodieAsyncService.java:103) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.async.AsyncCleanerService.waitForCompletion(AsyncCleanerService.java:75) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	... 6 more
Caused by: java.lang.NoSuchMethodError: org.apache.hudi.org.apache.avro.specific.SpecificRecordBuilderBase.<init>(Lorg/apache/hudi/org/apache/avro/Schema;Lorg/apache/hudi/org/apache/avro/specific/SpecificData;)V
	at org.apache.hudi.avro.model.HoodieCleanerPlan$Builder.<init>(HoodieCleanerPlan.java:325) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.avro.model.HoodieCleanerPlan$Builder.<init>(HoodieCleanerPlan.java:309) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.avro.model.HoodieCleanerPlan.newBuilder(HoodieCleanerPlan.java:276) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.table.action.clean.CleanPlanActionExecutor.requestClean(CleanPlanActionExecutor.java:110) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.table.action.clean.CleanPlanActionExecutor.requestClean(CleanPlanActionExecutor.java:148) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]


  CREATE CATALOG hudi_catalog WITH (
      'type' = 'hudi',
      'mode' = 'hms',
      'default-database' = 'default',
      'hive.conf.dir' = '/opt/flink/hiveconf',
      'table.external' = 'true'
  );
  CREATE DATABASE IF NOT EXISTS hudi_catalog.hudi_mydb;
  ## 切换到数据库test_flink
  USE hudi_catalog.hudi_mydb;
  CREATE TABLE products_hudi_sink(
      id BIGINT NOT NULL PRIMARY KEY NOT ENFORCED,
      name STRING,
      description STRING,
      dt VARCHAR(10)
    )
      PARTITIONED BY (`dt`)
      WITH (
    'connector' = 'hudi',
    'path' = 'jfs://miniofs/flinkhudi/mydb/products',
    'table.type' = 'MERGE_ON_READ',
    'changelog.enabled' = 'true',
    'hoodie.datasource.write.recordkey.field' = 'id',
    'write.precombine.field' = 'name',
    'hoodie.datasource.write.keygenerator.class' = 'org.apache.hudi.keygen.ComplexAvroKeyGenerator',
    'hoodie.datasource.write.hive_style_partitioning' = 'true',
    'compaction.async.enabled' = 'false',
    'hive_sync.conf.dir' = '/opt/flink/hiveconf'
  );
,
    'hive_sync.partition_fields' = 'dt',
    'hive_sync.partition_extractor_class' = 'org.apache.hudi.hive.HiveStylePartitionValueExtractor'

    SET table.sql-dialect=hive;
[ERROR] Could not execute SQL statement. Reason:
org.apache.flink.table.api.ValidationException: Could not find any factory for identifier 'hive' that implements 'org.apache.flink.table.planner.delegation.ParserFactory' in the classpath.

Available factory identifiers are:



kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- hive -e "USE hudi_mydb;SHOW TABLES;"
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- hive -e "DROP DATABASE hudi_mydb CASCADE"
#自己编译的hadoop3/hive3
#sql-client
[ERROR] Could not execute SQL statement. Reason:
java.lang.NoSuchMethodError: org.apache.parquet.schema.Types$PrimitiveBuilder.as(Lorg/apache/parquet/schema/LogicalTypeAnnotation;)Lorg/apache/parquet/schema/Types$Builder;
#copy hive-exec以后
#自己编译的hadoop2/hive2
#sql-client
[ERROR] Could not execute SQL statement. Reason:
java.lang.NoSuchMethodError: org.apache.parquet.schema.Types$PrimitiveBuilder.as(Lorg/apache/parquet/schema/LogicalTypeAnnotation;)Lorg/apache/parquet/schema/Types$Builder;

  SHOW CREATE TABLE products_hudi_sink;
  INSERT INTO hudi_catalog.hudi_mydb.products_hudi_sink SELECT * FROM hive.flink_mydb.products_cdc_source;
  SELECT * FROM hudi_catalog.hudi_mydb.products_hudi_sink;
#自己编译的hadoop2/hive2
#job-manager
11:52:55.889 [pool-7-thread-1] ERROR org.apache.hudi.sink.CleanFunction - Executor executes action [wait for cleaning finish] error
org.apache.hudi.exception.HoodieException: Error waiting for async clean service to finish
	at org.apache.hudi.async.AsyncCleanerService.waitForCompletion(AsyncCleanerService.java:77) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.client.HoodieFlinkWriteClient.waitForCleaningFinish(HoodieFlinkWriteClient.java:332) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.sink.CleanFunction.lambda$notifyCheckpointComplete$1(CleanFunction.java:75) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.sink.utils.NonThrownExecutor.lambda$wrapAction$0(NonThrownExecutor.java:130) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149) [?:1.8.0_362]
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624) [?:1.8.0_362]
	at java.lang.Thread.run(Thread.java:750) [?:1.8.0_362]
Caused by: java.util.concurrent.ExecutionException: java.lang.NoSuchMethodError: org.apache.hudi.org.apache.avro.specific.SpecificRecordBuilderBase.<init>(Lorg/apache/hudi/org/apache/avro/Schema;Lorg/apache/hudi/org/apache/avro/specific/SpecificData;)V
	at java.util.concurrent.CompletableFuture.reportGet(CompletableFuture.java:357) ~[?:1.8.0_362]
	at java.util.concurrent.CompletableFuture.get(CompletableFuture.java:1908) ~[?:1.8.0_362]
	at org.apache.hudi.async.HoodieAsyncService.waitForShutdown(HoodieAsyncService.java:103) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.async.AsyncCleanerService.waitForCompletion(AsyncCleanerService.java:75) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	... 6 more
Caused by: java.lang.NoSuchMethodError: org.apache.hudi.org.apache.avro.specific.SpecificRecordBuilderBase.<init>(Lorg/apache/hudi/org/apache/avro/Schema;Lorg/apache/hudi/org/apache/avro/specific/SpecificData;)V
	at org.apache.hudi.avro.model.HoodieCleanerPlan$Builder.<init>(HoodieCleanerPlan.java:325) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.avro.model.HoodieCleanerPlan$Builder.<init>(HoodieCleanerPlan.java:309) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.avro.model.HoodieCleanerPlan.newBuilder(HoodieCleanerPlan.java:276) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.table.action.clean.CleanPlanActionExecutor.requestClean(CleanPlanActionExecutor.java:110) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.table.action.clean.CleanPlanActionExecutor.requestClean(CleanPlanActionExecutor.java:148) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.table.action.clean.CleanPlanActionExecutor.execute(CleanPlanActionExecutor.java:173) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.table.HoodieFlinkCopyOnWriteTable.scheduleCleaning(HoodieFlinkCopyOnWriteTable.java:311) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.client.BaseHoodieWriteClient.scheduleTableServiceInternal(BaseHoodieWriteClient.java:1367) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.client.BaseHoodieWriteClient.clean(BaseHoodieWriteClient.java:878) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.client.BaseHoodieWriteClient.clean(BaseHoodieWriteClient.java:840) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at org.apache.hudi.async.AsyncCleanerService.lambda$startService$0(AsyncCleanerService.java:55) ~[hudi-flink1.15-bundle-0.12.2.jar:0.12.2]
	at java.util.concurrent.CompletableFuture$AsyncSupply.run(CompletableFuture.java:1604) ~[?:1.8.0_362]
	... 3 more




  SELECT * FROM products_hudi_sinker;


    'compaction.schedule.enabled' = 'true',
    'compaction.async.enabled' = 'false',
    'compaction.schedule.enabled' = 'true'




kubectl exec -it -n flink `kubectl get pod -n flink | grep ${SESSION} | awk '{print $1}'` -- cat /tmp/juicefs.access.log

SQL_FILE_HOME=/app/hdfs/hive
#HDFS_SQL_FILE_HOME=/flink/scripts
HDFS_SQL_FILE_HOME=/tmp

:<<EOF
#../hdfs_upload_file.sh ${SQL_FILE_HOME} ${HDFS_SQL_FILE_HOME} cdc-hudi-test-basic.sql
../hdfs-upload.sh ${SQL_FILE_HOME} ${HDFS_SQL_FILE_HOME} testfile
../hdfs-upload.sh ${SQL_FILE_HOME} ${HDFS_SQL_FILE_HOME} $PWD/testfolder
../hdfs-upload.sh ${SQL_FILE_HOME} ${HDFS_SQL_FILE_HOME} noexits
../client-upload.sh flink ${SESSION} /opt/flink/usrlib $PWD/testfolder ${NONAME}
EOF

#kubectl exec -it -n flink `kubectl get pod -n flink | grep flink-client | awk '{print $1}'` -- sql-client.sh embedded -i usrlib/setting.sql -f jfs://miniofs/flink/scripts/create_databases.sql
#SQL Client only supports to load files in local.

flink-sql-interact.sh ${SESSION}
  USE hive.test1;
  SELECT * FROM employee;

cat << EOF > upload-sql-files.sh
#!/usr/bin/env bash

${PRJ_HOME}/client-upload.sh flink ${SESSION} /opt/flink/usrlib showcatalogs.sql ${NONAME}
${PRJ_HOME}/client-upload.sh flink ${SESSION} /opt/flink/usrlib create_databases.sql ${NONAME}
${PRJ_HOME}/client-upload.sh flink ${SESSION} /opt/flink/usrlib showdatabases.sql ${NONAME}
${PRJ_HOME}/client-upload.sh flink ${SESSION} /opt/flink/usrlib showtables.sql ${NONAME}
${PRJ_HOME}/client-upload.sh flink ${SESSION} /opt/flink/usrlib dropdatabases.sql ${NONAME}
${PRJ_HOME}/client-upload.sh flink ${SESSION} /opt/flink/usrlib droptables.sql ${NONAME}
${PRJ_HOME}/client-upload.sh flink ${SESSION} /opt/flink/usrlib cdc-hudi-test-basic.sql ${NONAME}
${PRJ_HOME}/client-upload.sh flink ${SESSION} /opt/flink/usrlib cdc-hudi-test-basic-onlyjob.sql ${NONAME}
EOF
cat upload-sql-files.sh
chmod a+x upload-sql-files.sh

#FLINK_VERSION=1.15.4
FLINK_VERSION=1.17.0
TARGET_BUILT=hadoop3hive3
kubectl exec -it -n flink `kubectl get pod -n flink | grep flink-client | awk '{print $1}'` -- \
 kubernetes-session.sh \
    -Dexecution.attached=true \
    -Dkubernetes.namespace=flink \
    -Dkubernetes.cluster-id=${SESSION} \
    -Dkubernetes.container.image=harbor.my.org:1080/flink/flink-juicefs-${TARGET_BUILT}:${FLINK_VERSION} \
    -Djobmanager.memory.process.size=2048m \
    -Dkubernetes.jobmanager.cpu=1 \
    -Dtaskmanager.memory.process.size=2048m \
    -Dkubernetes.taskmanager.cpu=1 \
    -Dtaskmanager.numberOfTaskSlots=2

upload-sql-files.sh

#../client-upload.sh flink ${SESSION} /opt/flink/usrlib create_databases.sql ${NONAME}
flink-sql-exec.sh ${SESSION} create_databases.sql
#kubectl exec -it -n flink `kubectl get pod -n flink | grep flink-client | awk '{print $1}'` -- sql-client.sh embedded -i usrlib/setting.sql -e "SHOW CATALOGS"
#不支持-e

kubectl exec -it -n flink `kubectl get pod -n flink | grep cdc-hudi-test-basic | awk '{print $1}'` -- bash
  #source-sin
  flink cancel --target kubernetes-application -Dkubernetes.cluster-id=cdc-hudi-test-basic -Dkubernetes.namespace=flink 97e7d4cd82e26055147bf4b4a7a34143
  #手工insert
  flink cancel --target kubernetes-application -Dkubernetes.cluster-id=cdc-hudi-test-basic -Dkubernetes.namespace=flink 
  exit

flink-sql-exec.sh ${SESSION} dropdatabases.sql
kubectl delete deployments.apps -n flink cdc-hudi-test-basic 
kubectl get pod -n flink |grep -v Running |awk '{print $1}'| xargs kubectl delete pod "$1" -n flink --force --grace-period=0

kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- hadoop fs -rm -r -f /flink/checkpoints
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- hadoop fs -mkdir /flink/checkpoints
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- hadoop fs -ls /flink/checkpoints

kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- hadoop fs -rm -r -f /flinkhudi/mydb/products
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- hadoop fs -mkdir /flinkhudi/mydb/products
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- hadoop fs -ls /flinkhudi/mydb/products


cat << \EOF > showcatalogs.sql
  SHOW CATALOGS;
EOF
../client-upload.sh flink ${SESSION} /opt/flink/usrlib showcatalogs.sql ${NONAME}
flink-sql-exec.sh ${SESSION} showcatalogs.sql

cat << \EOF > showdatabases.sql
  USE CATALOG hive;
  SHOW DATABASES;
  USE CATALOG hudi_catalog;
  SHOW DATABASES;
EOF
../client-upload.sh flink ${SESSION} /opt/flink/usrlib showdatabases.sql ${NONAME}
flink-sql-exec.sh ${SESSION} showdatabases.sql


cat << \EOF > showtables.sql
  USE hive.flink_mydb;
  SHOW TABLES;
  USE hudi_catalog.hudi_mydb;
  SHOW TABLES;
EOF
../client-upload.sh flink ${SESSION} /opt/flink/usrlib showtables.sql ${NONAME}
flink-sql-exec.sh ${SESSION} showtables.sql

cat << \EOF > dropdatabases.sql
  USE CATALOG hive;
  DROP DATABASE IF EXISTS flink_mydb CASCADE;
  USE CATALOG hudi_catalog;
  DROP DATABASE IF EXISTS hudi_mydb CASCADE;
EOF
../client-upload.sh flink ${SESSION} /opt/flink/usrlib dropdatabases.sql ${NONAME}
flink-sql-exec.sh ${SESSION} dropdatabases.sql

cat << \EOF > droptables.sql
  USE hive.flink_mydb;
  DROP TABLE IF EXISTS products_cdc_source;
  USE hudi_catalog.hudi_mydb;
  DROP TABLE IF EXISTS products_hudi_sink;
EOF
../client-upload.sh flink ${SESSION} /opt/flink/usrlib droptables.sql ${NONAME}
flink-sql-exec.sh ${SESSION} droptables.sql

kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` --\
 hive -e "USE hudi_mydb;\
  DROP TABLE IF EXISTS products_hudi_sink_ro;\
  DROP TABLE IF EXISTS products_hudi_sink_rt;\
"

#mysql
DB_PORT=3306
DB_CONNECTOR=mysql-cdc
#postgresql
DB_PORT=5432
DB_CONNECTOR=postgres-cdc
cat << EOF > cdc-hudi-test-basic.sql
  CREATE TABLE hive.flink_mydb.products_cdc_source (
      id INT,
      name STRING,
      description STRING,
      dt VARCHAR(10),
      PRIMARY KEY (id) NOT ENFORCED
    ) WITH (
    'connector' = '${DB_CONNECTOR}',
    'server-time-zone' = 'Asia/Shanghai',
    'scan.incremental.snapshot.enabled'='true',
    'hostname' = '192.168.3.9',
    'port' = '${DB_PORT}',
    'username' = 'flink',
    'password' = 'flinkpw',
    'database-name' = 'mydb',
    'table-name' = 'products'
    );

  CREATE TABLE hudi_catalog.hudi_mydb.products_hudi_sink(
      id BIGINT NOT NULL,
      name STRING,
      description STRING,
      dt VARCHAR(10),
      PRIMARY KEY (id) NOT ENFORCED
    )
      PARTITIONED BY (`dt`)
      WITH (
    'connector' = 'hudi',
    'path' = 'jfs://miniofs/flinkhudi/mydb/products',
    'table.type' = 'MERGE_ON_READ',
    'changelog.enabled' = 'true',
    'hoodie.datasource.write.recordkey.field' = 'id',
    'write.precombine.field' = 'name',
    'hoodie.datasource.write.keygenerator.class' = 'org.apache.hudi.keygen.ComplexAvroKeyGenerator',
    'hoodie.datasource.write.hive_style_partitioning' = 'true',
    'compaction.async.enabled' = 'false',
    'hive_sync.conf.dir' = '/opt/flink/hiveconf'
  );

  INSERT INTO hudi_catalog.hudi_mydb.products_hudi_sink SELECT * FROM hive.flink_mydb.products_cdc_source;
EOF
../client-upload.sh flink ${SESSION} /opt/flink/usrlib cdc-hudi-test-basic.sql ${NONAME}
flink-sql-exec.sh ${SESSION} cdc-hudi-test-basic.sql
  不加上'changelog.enabled' = 'true',sink表就变成一个批表，INSERT作业也是处于FINISH状态，后续对mysql的修改不会被同步过来
  加上'read.streaming.enabled'= 'true'就变成和cdc source，kafka一样的流表了
    在sql-client里查询会卡主一直在等待新数据。
    先启动source到sink作业，查询是source数据，再INSERT单条记录会启动新的作业，查询是INSERT单条的记录，不会同时把所有记录都显示出来
  加上'changelog.enabled' = 'true'，不加read.streaming.enabled'= 'true'，作业是流的，表是动态的，
    只有SOURCE->SINK作业写表时，mysql更新，SELECT会立刻显示hive更新
    INSERT作业加入后，两个作业的数据SELECT都会显示，但是SOURCE-SINK数据不刷新
    CANCEL作业id时，两个作业都是活动的


cat << \EOF > selecttables.sql
  SET sql-client.execution.result-mode=TABLEAU;
  -- SELECT * FROM hive.flink_mydb.products_cdc_source;
  -- SELECT流表会一直读，要ctrl + c才能退出，又变成交互的了
  SELECT * FROM hudi_catalog.hudi_mydb.products_hudi_sink;
EOF
../client-upload.sh flink ${SESSION} /opt/flink/usrlib selecttables.sql taskmanager ${NONAME}
flink-sql-exec.sh ${SESSION} selecttables.sql

cat << \EOF > cdc-hudi-test-basic-onlyjob.sql
  SET execution.checkpointing.interval = 3s;
  INSERT INTO hudi_catalog.hudi_mydb.products_hudi_sink SELECT * FROM hive.flink_mydb.products_cdc_source;
EOF
../client-upload.sh flink ${SESSION} /opt/flink/usrlib cdc-hudi-test-basic-onlyjob.sql taskmanager ${NONAME}
flink-sql-exec.sh ${SESSION} cdc-hudi-test-basic-onlyjob.sql


flink-sql-interact.sh ${SESSION}
