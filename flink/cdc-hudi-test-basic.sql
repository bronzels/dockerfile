  CREATE TABLE hive.flink_mydb.products_cdc_source (
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

  CREATE TABLE hudi_catalog.hudi_mydb.products_hudi_sink(
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

  INSERT INTO hudi_catalog.hudi_mydb.products_hudi_sink SELECT * FROM hive.flink_mydb.products_cdc_source;

