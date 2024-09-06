#1,MySQL同步到StarRocks
docker-compose up -d
docker exec -it flink-MySQL-1 mysql -h127.0.0.1 -uroot -p123456
  -- 创建数据库
  CREATE DATABASE app_db;

  USE app_db;

  -- 创建 orders 表
  CREATE TABLE `orders` (
  `id` INT NOT NULL,
  `price` DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (`id`)
  );

  -- 插入数据
  INSERT INTO `orders` (`id`, `price`) VALUES (1, 4.00);
  INSERT INTO `orders` (`id`, `price`) VALUES (2, 100.00);

  -- 创建 shipments 表
  CREATE TABLE `shipments` (
  `id` INT NOT NULL,
  `city` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`)
  );

  -- 插入数据
  INSERT INTO `shipments` (`id`, `city`) VALUES (1, 'beijing');
  INSERT INTO `shipments` (`id`, `city`) VALUES (2, 'xian');

  -- 创建 products 表
  CREATE TABLE `products` (
  `id` INT NOT NULL,
  `product` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`)
  );

  -- 插入数据
  INSERT INTO `products` (`id`, `product`) VALUES (1, 'Beer');
  INSERT INTO `products` (`id`, `product`) VALUES (2, 'Cap');
  INSERT INTO `products` (`id`, `product`) VALUES (3, 'Peanut');


flink-cdc/bin/flink-cdc.sh mysql-to-starrocks.yaml
:<<EOF
Loading class `com.mysql.jdbc.Driver'. This is deprecated. The new driver class is `com.mysql.cj.jdbc.Driver'. The driver is automatically registered via the SPI and manual loading of the driver class is generally unnecessary.
Pipeline has been submitted to cluster.
Job ID: ebca4a151ed1e70c2f8dd8ae7fd077a2
Job Description: Sync MySQL Database to StarRocks
EOF


docker exec -it flink-StarRocks-1 mysql -h127.0.0.1 -P 9030 -uroot
  SHOW DATABASES;
  USE app_db;
  SHOW TABLES;
  SELECT * FROM orders;
  SELECT * FROM shipments;
  SELECT * FROM products;

docker exec -it flink-MySQL-1 mysql -h127.0.0.1 -uroot -proot
  USE app_db;
  INSERT INTO app_db.orders (id, price) VALUES (3, 100.00);

docker exec -it flink-StarRocks-1 mysql -h127.0.0.1 -P 9030 -uroot
  USE app_db;
  SELECT * FROM orders;

docker exec -it flink-MySQL-1 mysql -h127.0.0.1 -uroot -proot
  USE app_db;
  ALTER TABLE app_db.orders ADD amount varchar(100) NULL;

docker exec -it flink-StarRocks-1 mysql -h127.0.0.1 -P 9030 -uroot
  USE app_db;
  SELECT * FROM orders;

docker exec -it flink-MySQL-1 mysql -h127.0.0.1 -uroot -proot
  USE app_db;
  UPDATE app_db.orders SET price=100.00, amount=100.00 WHERE id=1;

docker exec -it flink-StarRocks-1 mysql -h127.0.0.1 -P 9030 -uroot
  USE app_db;
  SELECT * FROM orders;

docker exec -it flink-MySQL-1 mysql -h127.0.0.1 -uroot -proot
  USE app_db;
  DELETE FROM app_db.orders WHERE id=2;

docker exec -it flink-StarRocks-1 mysql -h127.0.0.1 -P 9030 -uroot
  USE app_db;
  SELECT * FROM orders;
