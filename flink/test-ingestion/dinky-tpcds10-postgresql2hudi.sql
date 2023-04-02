-- dinky整库同步还不支持postgresql
[dlink] 2023-03-31 12:29:24 UTC ERROR com.dlink.trans.ddl.CreateCDCSourceOperation 203 build - 未匹配到对应 CDC Source 类型的【postgres-cdc】。 com.dlink.exception.FlinkClientException: 未匹配到对应 CDC Source 类型的【postgres-cdc】。
	at com.dlink.cdc.CDCBuilderFactory.lambda$buildCDCBuilder$0(CDCBuilderFactory.java:52) ~[dlink-client-1.15-0.7.2.jar:?]
	at com.dlink.cdc.CDCBuilderFactory.buildCDCBuilder(CDCBuilderFactory.java:53) ~[dlink-client-1.15-0.7.2.jar:?]
	at com.dlink.trans.ddl.CreateCDCSourceOperation.build(CreateCDCSourceOperation.java:87) ~[dlink-executor-0.7.2.jar:?]
	at com.dlink.interceptor.FlinkInterceptor.build(FlinkInterceptor.java:55) ~[dlink-executor-0.7.2.jar:?]
	at com.dlink.executor.Executor.pretreatExecute(Executor.java:230) ~[dlink-executor-0.7.2.jar:?]
	at com.dlink.executor.Executor.explainSqlRecord(Executor.java:343) ~[dlink-executor-0.7.2.jar:?]
	at com.dlink.explainer.Explainer.explainSql(Explainer.java:308) ~[dlink-core-0.7.2.jar:?]
	at com.dlink.job.JobManager.explainSql(JobManager.java:695) ~[dlink-core-0.7.2.jar:?]
	at com.dlink.service.impl.StudioServiceImpl.explainFlinkSql(StudioServiceImpl.java:288) ~[dlink-admin-0.7.2.jar:?]
	at com.dlink.service.impl.StudioServiceImpl.explainSql(StudioServiceImpl.java:273) ~[dlink-admin-0.7.2.jar:?]
	at com.dlink.service.impl.StudioServiceImpl$$FastClassBySpringCGLIB$$e3eb787.invoke(<generated>) ~[dlink-admin-0.7.2.jar:?]
    
EXECUTE CDCSOURCE cdc_postgresql_2_hudi WITH (
    'connector' = 'postgres-cdc',
    'hostname' = '192.168.3.9',
    'port' = '5432',
    'username' = 'flink',
    'password' = 'flinkpw',
    'checkpoint' = '3000',
    'parallelism' = '1',
    'table-name' = 'tpcds\..*',
    'schema-name' = 'public',
    'decoding.plugin.name' = 'pgoutput',
    'changelog-mode' = 'upsert'

    'sink.connector'='hudi',
    'sink.path'='jfs://miniofs/flinkhudi/tpcds/${tableName}',

    'sink.hoodie.datasource.write.recordkey.field'='${pkList}',
    'sink.hoodie.parquet.max.file.size'='268435456',

    'sink.write.tasks'='1',
    'sink.write.bucket_assign.tasks'='2',
    'sink.write.task.max.size'='1024',
    'sink.write.rate.limit'='3000',
    'sink.write.operation'='upsert',

    'sink.table.type'='MERGE_ON_READ',
    
    'sink.compaction.async.enabled'='true',    
    'sink.compaction.tasks'='1',
    'sink.compaction.delta_seconds'='20',
    'sink.compaction.delta_commits'='20',
    'sink.compaction.trigger.strategy'='num_or_time',
    'sink.compaction.max_memory'='500',

    'sink.changelog.enabled'='true',
    'sink.read.streaming.enabled'='true',
    'sink.read.streaming.check.interval'='3',
    'sink.read.streaming.skip_compaction'='true',

    'sink.table.prefix.schema'='false'

    'sink.hive_sync.enable'='true',
    'sink.hive_sync.mode'='hms',
    'sink.hive_sync.db'='hudi_tpcds',
    'sink.hive_sync.table'='${tableName}',
    'sink.table.prefix.schema'='true',
    'sink.hive_sync.metastore.uris'='thrift://hive-service.hadoop.svc.cluster.local:9083',
    'sink.hive_sync.username'='hdfs'

)


