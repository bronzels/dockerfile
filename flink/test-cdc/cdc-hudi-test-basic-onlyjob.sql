  SET execution.checkpointing.interval = 3s;
  INSERT INTO hudi_catalog.hudi_mydb.products_hudi_sink SELECT * FROM hive.flink_mydb.products_cdc_source;
