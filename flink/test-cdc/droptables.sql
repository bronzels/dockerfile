  USE hive.flink_mydb;
  DROP TABLE IF EXISTS products_cdc_source;
  USE hudi_catalog.hudi_mydb;
  DROP TABLE IF EXISTS products_hudi_sink;
  DROP TABLE IF EXISTS products_hudi_sink_ro;
  DROP TABLE IF EXISTS products_hudi_sink_rt;
