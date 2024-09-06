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

export PATH=$PATH:${PRJ_HOME}:${PRJ_FLINK_HOME}

NONAME=taskmanager
SESSION=cdc-hudi-test-basic

FLINK_VERSION=1.15.4
TARGET_BUILT=hadoop3hive3

cat << EOF > db-env.sh
MYSQL_CONTAINER=mysql-binlog2
MYSQL_PORT=3306
MYSQL_USR=root
MYSQL_PWD=123456
MYSQL_PRIV="SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT"
EOF
cat << EOF > db-env.sh
MYSQL_CONTAINER=ploardbx-binlog2
MYSQL_PORT=8527
MYSQL_USR=polardbx_root
MYSQL_PWD=123456
MYSQL_PRIV="SELECT, REPLICATION SLAVE, REPLICATION CLIENT"
EOF
. ./db-env.sh 

#mysql
docker exec -it ${MYSQL_CONTAINER} mysql -h127.0.0.1 -u${MYSQL_USR} -p${MYSQL_PWD} -P${MYSQL_PORT} mydb
  SELECT * FROM products;
  INSERT INTO products VALUES (default,"socks","Man, woman and child socks","20230314");
  INSERT INTO products VALUES (default,"bike","Dirt mud bike",'BigBiker',"20230214");
  INSERT INTO products VALUES ('football','2022 Worldcup','Big daddy','20230314');
  INSERT INTO products VALUES ('basketball','Signed by Yaoming','Big daddy','20230414');
  INSERT INTO products VALUES ('sail','Sail toll used in pool','Big daddy','20230414');
  INSERT INTO products VALUES ('tennis','Tennis ball','Big daddy','20230414');
  UPDATE products SET description='Large 2-wheel scooter' WHERE id=101;
  UPDATE products SET description='Huge 2-wheel scooter' WHERE id=101;
  DELETE FROM products WHERE id=111;

#postgresql
docker exec -it ${DB_CONTAINER} psql -h 127.0.0.1 -p ${DB_PORT} -U ${DB_USR} -d mydb
  SELECT * FROM products;
  INSERT INTO products(name,description,dt) VALUES ('socks','Man, woman and child socks','20230314');
  INSERT INTO products(name,description,dt) VALUES ('bike','Dirt mud bike','20230214');
  INSERT INTO products(name,description,dt) VALUES ('football','2022 Worldcup','20230314');
  INSERT INTO products(name,description,dt) VALUES ('basketball','Signed by Yaoming','20230414');
  INSERT INTO products(name,description,dt) VALUES ('sail','Sail toll used in pool','20230414');
  INSERT INTO products(name,description,dt) VALUES ('tennis','Tennis ball','20230414');
  INSERT INTO products(name,description,dt) VALUES ('boxing glove','Red boxing glove','20230414');
  INSERT INTO products(name,description,dt) VALUES ('basketball8888','Signed by Yaoming','20230414');
  INSERT INTO products(name,description,dt) VALUES ('sail8888','Sail toll used in pool','20230414');
  INSERT INTO products(name,description,dt) VALUES ('tennis8888','Tennis ball','20230414');
  INSERT INTO products(name,description,dt) VALUES ('boxing glove8888','Red boxing glove','20230414');
  INSERT INTO products(name,description,dt) VALUES ('socks88888','Man, woman and child socks','20230314');
  INSERT INTO products(name,description,dt) VALUES ('bike8888','Dirt mud bike','20230214');
  INSERT INTO products(name,description,dt) VALUES ('football8888','2022 Worldcup','20230314');
  UPDATE products SET description='Small 2-wheel scooter' WHERE id=1;
  UPDATE products SET description='Large 2-wheel scooter' WHERE id=1;
  UPDATE products SET description='Huge 2-wheel scooter' WHERE id=1;
  DELETE FROM products WHERE id=17;
  DELETE FROM products WHERE id=3;
  DELETE FROM products WHERE id=9;


#mysql
docker exec -it ${MYSQL_CONTAINER} mysql -h127.0.0.1 -u${MYSQL_USR} -p${MYSQL_PWD} -P${MYSQL_PORT} mydb
  ALTER TABLE products ADD COLUMN supplier varchar(15) AFTER description;
  UPDATE products SET supplier='BigScooter' WHERE id=101;


#spark
kubectl exec -it -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep spark-client | awk '{print $1}'` -- bash
  beeline -u jdbc:hive2://kyuubisrv-thrift-binary.spark-operator.svc.cluster.local:10009 -n hdfs
    USE hudi_mydb;
    SELECT * FROM products_hudi_sink;
        有数据
    SELECT * FROM products_hudi_sink_ro;
        无数据
    SELECT * FROM products_hudi_sink_rt;
        有数据
    -- 和mysql内的修改能保持一致
      插入
      修改，多次修改同一条记录，只有最后1条U记录
      删除，1条D记录
    -- 前2张表在compact之前没有数据，compact之后还未测试
    3张表都不能插入
    删除数据？
    INSERT INTO products_hudi_sink VALUES (200,'snicker','Nike black runner','20230314'),(201,'tin toy','Tin frog, mouse, bunny','20230314');
  Caused by: org.apache.spark.sql.AnalysisException: org.apache.hudi.MergeOnReadSnapshotRelation@ce55dc6 does not allow insertion.;
  'InsertIntoStatement Relation hudi_mydb.products_hudi_sink_rt[_hoodie_commit_time#12,_hoodie_commit_seqno#13,_hoodie_record_key#14,_hoodie_partition_path#15,_hoodie_file_name#16,_hoodie_operation#17,id#18L,name#19,description#20,dt#21] org.apache.hudi.MergeOnReadSnapshotRelation@ce55dc6, false, false
  +- LocalRelation [col1#61, col2#62, col3#63, col4#64]


#presto
kubectl exec -it -n presto `kubectl get pod -n presto | grep Running | grep coordinator | awk '{print $1}'` -- bash
    presto-server/bin/presto-cli --server my-presto-kube:8080 --catalog hive --schema hudi_mydb
    SELECT * FROM products_hudi_sink;
        无数据
    SELECT * FROM products_hudi_sink_ro;
        无数据
    SELECT * FROM products_hudi_sink_rt;
        有数据
    未测试INSERT
    删除数据仍然可见，OP标记D


#flink
SESSION=cdc-hudi-test-basic
../flink-sql-interact.sh ${SESSION}
    USE hudi_catalog.hudi_mydb;
    SELECT * FROM products_hudi_sink;
        有数据
    SELECT * FROM products_hudi_sink_ro;
        无数据
    SELECT * FROM products_hudi_sink_rt;
        有数据
    集群重启前，测试和和spark一致
    集群重启以后，重新启动INSERT作业以后，products_hudi_sink表可以查到记录，另外2个表没法查询，SHOW CREATE TABLE显示没有   'primaryKey'='id',的配置
    停作业，删除hdfs数据，drop掉库/表，重新创建库表提交INSERT作业后，还是一样
    把CDC mysql重新初始化以后才恢复正常
    删除数据不可见
Flink SQL> SELECT * FROM products_hudi_sink_ro;
[ERROR] Could not execute SQL statement. Reason:
org.apache.hudi.exception.HoodieValidationException: Primary key definition is required, use either PRIMARY KEY syntax or option 'hoodie.datasource.write.recordkey.field' to specify.
Flink SQL> SELECT * FROM products_hudi_sink_rt;
[ERROR] Could not execute SQL statement. Reason:
org.apache.hudi.exception.HoodieValidationException: Primary key definition is required, use either PRIMARY KEY syntax or option 'hoodie.datasource.write.recordkey.field' to specify.
    USE hudi_catalog.hudi_mydb;
    INSERT INTO products_hudi_sink VALUES (200,'snicker','Nike black runner','20230314'),(201,'tin toy','Tin frog, mouse, bunny','20230314');
    SET sql-client.execution.result-mode=TABLEAU;
    SELECT * FROM products_hudi_sink;


#flink日志
第一次测试taskmanager有打印，后来测试数据正确，但是没有打印了
kubectl logs -f -n flink cdc-hudi-test-basic-taskmanager-1-1
  :<<EOF
  sed: couldn't open temporary file /opt/flink/conf/sedRGos5X: Read-only file system
  sed: couldn't open temporary file /opt/flink/conf/sedX03KC7: Read-only file system
  /docker-entrypoint.sh: line 73: /opt/flink/conf/flink-conf.yaml: Read-only file system
  /docker-entrypoint.sh: line 89: /opt/flink/conf/flink-conf.yaml.tmp: Read-only file system
  Starting kubernetes-taskmanager as a console application on host cdc-hudi-test-basic-taskmanager-1-1.
  SLF4J: Class path contains multiple SLF4J bindings.
  SLF4J: Found binding in [jar:file:/opt/flink/lib/log4j-slf4j-impl-2.17.1.jar!/org/slf4j/impl/StaticLoggerBinder.class]
  SLF4J: Found binding in [jar:file:/opt/hadoop/share/hadoop/common/lib/slf4j-reload4j-1.7.36.jar!/org/slf4j/impl/StaticLoggerBinder.class]
  SLF4J: See http://www.slf4j.org/codes.html#multiple_bindings for an explanation.
  SLF4J: Actual binding is of type [org.apache.logging.slf4j.Log4jLoggerFactory]
  WARNING: An illegal reflective access operation has occurred
  WARNING: Illegal reflective access by org.jboss.netty.util.internal.ByteBufferUtil (file:/tmp/flink-rpc-akka_5b8c59a0-78f2-4f73-8453-ebedafd8a0cc.jar) to method java.nio.DirectByteBuffer.cleaner()
  WARNING: Please consider reporting this to the maintainers of org.jboss.netty.util.internal.ByteBufferUtil
  WARNING: Use --illegal-access=warn to enable warnings of further illegal reflective access operations
  WARNING: All illegal access operations will be denied in a future release
  +I[101, scooter, Small 2-wheel scooter]
  +I[102, car battery, 12V car battery]
  +I[103, 12-pack drill bits, 12-pack of drill bits with sizes ranging from #40 to #3]
  +I[104, hammer, 12oz carpenter's hammer]
  +I[105, hammer, 14oz carpenter's hammer]
  +I[106, hammer, 16oz carpenter's hammer]
  +I[107, rocks, box of assorted rocks]
  +I[108, jacket, water resistent black wind breaker]
  +I[109, spare tire, 24 inch spare tire]
  Mar 17, 2023 5:01:57 PM com.github.shyiko.mysql.binlog.BinaryLogClient connect
  INFO: Connected to 192.168.3.9:3306 at mysql-bin.000003/163634855 (sid:5665, cid:60)
  +I[110, bike, Dirt mud bike]
  -U[101, scooter, Small 2-wheel scooter]
  +U[101, scooter, Large 2-wheel scooter]
  -D[110, bike, Dirt mud bike]
  EOF


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

-Djobmanager.memory.process.size=2048m
-Dkubernetes.jobmanager.cpu=1
-Dtaskmanager.memory.process.size=2048m
-Dkubernetes.taskmanager.cpu=1
-Dtaskmanager.numberOfTaskSlots=2

upload-sql-files.sh

#../client-upload.sh flink ${SESSION} /opt/flink/usrlib create_databases.sql ${NONAME}
flink-sql-exec.sh ${SESSION} create_databases.sql
#kubectl exec -it -n flink `kubectl get pod -n flink | grep flink-client | awk '{print $1}'` -- sql-client.sh embedded -i usrlib/setting.sql -e "SHOW CATALOGS"
#不支持-e

kubectl exec -it -n flink `kubectl get pod -n flink | grep cdc-hudi-test-basic | awk '{print $1}'` -- bash
  #source-sin
  flink cancel --target kubernetes-application -Dkubernetes.cluster-id=cdc-hudi-test-basic -Dkubernetes.namespace=flink 63a17a87e2031895a3fe3f0f86ff0c2d
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
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- hive -e "USE hudi_mydb;SHOW TABLES"

#mysql
DB_PORT=3306
DB_CONNECTOR=mysql-cdc
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
      PARTITIONED BY (\`dt\`)
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
    'hostname' = '192.168.3.9',
    'port' = '${DB_PORT}',
    'username' = 'flink',
    'password' = 'flinkpw',
    'database-name' = 'mydb',
    'table-name' = 'products',
    'schema-name' = 'public',
    'decoding.plugin.name' = 'pgoutput',
    'debezium.slot.name' = 'mydb',
    'changelog-mode' = 'upsert'
    );
  -- 'debezium.snapshot.mode' = 'never',

  CREATE TABLE hudi_catalog.hudi_mydb.products_hudi_sink(
      id BIGINT NOT NULL,
      name STRING,
      description STRING,
      dt VARCHAR(10),
      PRIMARY KEY (id) NOT ENFORCED
    )
      PARTITIONED BY (\`dt\`)
      WITH (
    'connector' = 'hudi',
    'path' = 'jfs://miniofs/flinkhudi/mydb/products',
    'table.type' = 'MERGE_ON_READ',
    'changelog.enabled' = 'true',
    'hoodie.datasource.write.recordkey.field' = 'id',
    'write.precombine.field' = 'name',
    'hoodie.datasource.write.keygenerator.class' = 'org.apache.hudi.keygen.ComplexAvroKeyGenerator',
    'hoodie.datasource.write.hive_style_partitioning' = 'true',
    'compaction.async.enabled' = 'true',
    'compaction.tasks' = '2',
    'compaction.trigger.strategy' = 'num_commits',
    'compaction.delta_commits' = '4',
    'hive_sync.conf.dir' = '/opt/flink/hiveconf'
  );

  INSERT INTO hudi_catalog.hudi_mydb.products_hudi_sink SELECT * FROM hive.flink_mydb.products_cdc_source;
EOF
:<<EOF
Flink SQL> [ERROR] Could not execute SQL statement. Reason:
org.apache.flink.table.api.ValidationException: Unsupported options found for 'postgres-cdc'.

Unsupported options:

scan.incremental.snapshot.enabled
server-time-zone

Supported options:

changelog-mode
connector
database-name
debezium.slot.name
decoding.plugin.name
hostname
password
port
property-version
schema-name
slot.name
table-name
username
EOF

../client-upload.sh flink ${SESSION} /opt/flink/usrlib cdc-hudi-test-basic.sql ${NONAME}
flink-sql-exec.sh ${SESSION} cdc-hudi-test-basic.sql
  #mysql
  不加上'changelog.enabled' = 'true',sink表就变成一个批表，INSERT作业也是处于FINISH状态，后续对mysql的修改不会被同步过来
  加上'read.streaming.enabled'= 'true'就变成和cdc source，kafka一样的流表了
    在sql-client里查询会卡主一直在等待新数据。
    先启动source到sink作业，查询是source数据，再INSERT单条记录会启动新的作业，查询是INSERT单条的记录，不会同时把所有记录都显示出来
  加上'changelog.enabled' = 'true'，不加read.streaming.enabled'= 'true'，作业是流的，表是动态的，
    只有SOURCE->SINK作业写表时，mysql更新，SELECT会立刻显示hive更新
    INSERT作业加入后，两个作业的数据SELECT都会显示，但是SOURCE-SINK数据不刷新
    CANCEL作业id时，两个作业都是活动的

  #postgresql
  历史数据可以立刻查到，实时数据flink和spark都
    update数据一直查不到
    INSERT数据要要等很久才能查到
  加上changelog-mode=upsert以后，
    历史数据flink/presto能查询到，实时数据, UPDATE/INSERT/DELETE数据都立刻能查到，但是要每次有更新数据以后重新连接beeline才能读到新数据，加上async.compact也没用
    spark查询出错
  Caused by: org.apache.hudi.exception.HoodieIOException: IOException when reading log file 
	at org.apache.hudi.common.table.log.AbstractHoodieLogRecordReader.scanInternal(AbstractHoodieLogRecordReader.java:349)
	at org.apache.hudi.common.table.log.AbstractHoodieLogRecordReader.scan(AbstractHoodieLogRecordReader.java:192)
	at org.apache.hudi.common.table.log.HoodieMergedLogRecordScanner.performScan(HoodieMergedLogRecordScanner.java:109)
	at org.apache.hudi.common.table.log.HoodieMergedLogRecordScanner.<init>(HoodieMergedLogRecordScanner.java:102)
	at org.apache.hudi.common.table.log.HoodieMergedLogRecordScanner$Builder.build(HoodieMergedLogRecordScanner.java:323)
	at org.apache.hudi.HoodieMergeOnReadRDD$.scanLog(HoodieMergeOnReadRDD.scala:402)
	at org.apache.hudi.HoodieMergeOnReadRDD$LogFileIterator.<init>(HoodieMergeOnReadRDD.scala:197)
	at org.apache.hudi.HoodieMergeOnReadRDD.compute(HoodieMergeOnReadRDD.scala:124)
	at org.apache.spark.rdd.RDD.computeOrReadCheckpoint(RDD.scala:365)
	at org.apache.spark.rdd.RDD.iterator(RDD.scala:329)
	at org.apache.spark.rdd.MapPartitionsRDD.compute(MapPartitionsRDD.scala:52)
	at org.apache.spark.rdd.RDD.computeOrReadCheckpoint(RDD.scala:365)
	at org.apache.spark.rdd.RDD.iterator(RDD.scala:329)
	at org.apache.spark.rdd.MapPartitionsRDD.compute(MapPartitionsRDD.scala:52)
	at org.apache.spark.rdd.RDD.computeOrReadCheckpoint(RDD.scala:365)
	at org.apache.spark.rdd.RDD.iterator(RDD.scala:329)
	at org.apache.spark.scheduler.ResultTask.runTask(ResultTask.scala:90)
	at org.apache.spark.scheduler.Task.run(Task.scala:136)
	at org.apache.spark.executor.Executor$TaskRunner.$anonfun$run$3(Executor.scala:548)
	at org.apache.spark.util.Utils$.tryWithSafeFinally(Utils.scala:1504)
	at org.apache.spark.executor.Executor$TaskRunner.run(Executor.scala:551)
	... 3 more
Caused by: java.io.FileNotFoundException: jfs://miniofs/flinkhudi/mydb/products/dt=20211214/.ef9e4c18-fe72-4733-b7e8-db2ae9fdb9bf_20230329190608549.log.1_0-1-0: not found
	at io.juicefs.JuiceFileSystemImpl.error(JuiceFileSystemImpl.java:196)
	at io.juicefs.JuiceFileSystemImpl.open(JuiceFileSystemImpl.java:974)
	at org.apache.hadoop.fs.FilterFileSystem.open(FilterFileSystem.java:164)
	at org.apache.hudi.common.table.log.HoodieLogFileReader.getFSDataInputStream(HoodieLogFileReader.java:475)
	at org.apache.hudi.common.table.log.HoodieLogFileReader.<init>(HoodieLogFileReader.java:114)
	at org.apache.hudi.common.table.log.HoodieLogFormatReader.<init>(HoodieLogFormatReader.java:70)
	at org.apache.hudi.common.table.log.AbstractHoodieLogRecordReader.scanInternal(AbstractHoodieLogRecordReader.java:219)
	... 23 more

	at org.apache.kyuubi.KyuubiSQLException$.apply(KyuubiSQLException.scala:69)
	at org.apache.kyuubi.operation.ExecuteStatement.waitStatementComplete(ExecuteStatement.scala:129)
	at org.apache.kyuubi.operation.ExecuteStatement.$anonfun$runInternal$1(ExecuteStatement.scala:161)
	at java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:511)
	at java.util.concurrent.FutureTask.run(FutureTask.java:266)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
	at java.lang.Thread.run(Thread.java:750) (state=,code=0)
  hudi spark换成用flink命令编译加上spark版本和profile，products_hudi_sink可以读到历史记录，

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

kubectl logs -n flink `kubectl get pod -n flink | grep ${session} | grep -v taskmanager | awk '{print $1}'`
