SHOW SCHEMAS FROM mysql;
SELECT * FROM mysql.airbyte.cars;
SHOW SCHEMAS FROM postgresql;

USE postgresql.public;
SHOW TABLES;
SELECT * FROM postgresql.public.table_two;

SELECT * FROM mysql.airbyte.cars cars INNER JOIN postgresql.public.table_two table_two ON cars.id = table_two.id;

-- 创建一个外部表来引用通过HTTP公开的CSV文件
CREATE TABLE csv_over_http (
    sepal_length REAL,
    sepal_width REAL,
    petal_length REAL,
    petal_width REAL,
    label TINYINT
) WITH (
    format = 'CSV',
    field_delimiter = ',',
    record_delimiter = '\n',
    external_location = 'http://mmubu:2080/iris_training.csv'
);
 
-- 查询外部表中的数据
SELECT * FROM csv_over_http;

