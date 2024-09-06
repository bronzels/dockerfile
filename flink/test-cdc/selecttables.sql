  SET sql-client.execution.result-mode=TABLEAU;
  -- SELECT * FROM hive.flink_mydb.products_cdc_source;
  -- SELECT流表会一直读，要ctrl + c才能退出，又变成交互的了
  SELECT * FROM hudi_catalog.hudi_mydb.products_hudi_sink;
