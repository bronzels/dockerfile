  CREATE TABLE hive.flink_mydb.products_cdc_source (
      id INT,
      name STRING,
      description STRING,
      dt VARCHAR(10),
      PRIMARY KEY (id) NOT ENFORCED
    ) WITH (
    'connector' = 'postgres-cdc',
    'hostname' = '192.168.3.9',
    'port' = '5432',
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
    'compaction.async.enabled' = 'true',
    'compaction.tasks' = '2',
    'compaction.trigger.strategy' = 'num_commits',
    'compaction.delta_commits' = '4',
    'hive_sync.conf.dir' = '/opt/flink/hiveconf'
  );

  INSERT INTO hudi_catalog.hudi_mydb.products_hudi_sink SELECT * FROM hive.flink_mydb.products_cdc_source;
