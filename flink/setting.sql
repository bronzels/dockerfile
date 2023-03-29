SET execution.checkpointing.interval = 3s;
  
-- SET table.local-time-zone=Asia/Shanghai;
  
CREATE CATALOG hive WITH (
    'type' = 'hive',
    'default-database' = 'default',
    'hive-conf-dir' = '/opt/flink/hiveconf',
    'hadoop-conf-dir'='/opt/hadoop/conf'
);

CREATE CATALOG hudi_catalog WITH (
    'type' = 'hudi',
    'mode' = 'hms',
    'default-database' = 'default',
    'hive.conf.dir' = '/opt/flink/hiveconf',
    'table.external' = 'true'
);
