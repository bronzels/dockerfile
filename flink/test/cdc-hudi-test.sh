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

cat << EOF > mysql-env.sh
MYSQL_CONTAINER=mysql-binlog2
MYSQL_PORT=3306
MYSQL_USR=root
MYSQL_PWD=123456
MYSQL_PRIV="SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT"
EOF
cat << EOF > mysql-env.sh
MYSQL_CONTAINER=ploardbx-binlog2
MYSQL_PORT=8527
MYSQL_USR=polardbx_root
MYSQL_PWD=123456
MYSQL_PRIV="SELECT, REPLICATION SLAVE, REPLICATION CLIENT"
EOF
. ./mysql-env.sh 

#mysql
docker exec -it ${MYSQL_CONTAINER} mysql -h127.0.0.1 -u${MYSQL_USR} -p${MYSQL_PWD} -P${MYSQL_PORT} mydb
  INSERT INTO products VALUES (default,"socks","Man, woman and child socks","20230314");
  INSERT INTO products VALUES (default,"bike","Dirt mud bike","20230214");
  UPDATE products SET description='Large 2-wheel scooter' WHERE id=101;
  UPDATE products SET description='Huge 2-wheel scooter' WHERE id=101;
  DELETE FROM products WHERE id=112;


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
