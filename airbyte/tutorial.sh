1, Explore Airbyte’s incremental data synchronization
#https://airbyte.com/tutorials/incremental-data-synchronization
#setup source and destination postgresql instance
docker run --restart=always --name airbyte-source -e POSTGRES_PASSWORD=postgres -p 2000:5432 -d debezium/postgres:13
docker run --restart=always --name airbyte-destination -e POSTGRES_PASSWORD=postgres -p 3000:5432 -d debezium/postgres:13
#append only mode
##source, create table with updated_at timestamp DEFAULT NOW() NOT NULL
##source, setup the trigger to update timestamp field for incremental sync
##source, insert the data, check all data/timestamp correct
##source, update the data, check updated data/timestamp correct
docker exec -it airbyte-source psql --username=postgres
  CREATE TABLE table_one(
    id integer PRIMARY KEY,
    name VARCHAR(200),
    updated_at timestamp DEFAULT NOW() NOT NULL
  );
  CREATE OR REPLACE FUNCTION trigger_set_timestamp()
  RETURNS TRIGGER AS '
  BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
  END;
  '
  LANGUAGE plpgsql;
  CREATE TRIGGER set_timestamp_on_table_one
  BEFORE UPDATE ON table_one
  FOR EACH ROW
  EXECUTE PROCEDURE trigger_set_timestamp();  
  INSERT INTO table_one(id, name) VALUES(1, 'Eg1 IncApp');
  INSERT INTO table_one(id, name) VALUES(2, 'Eg2 IncApp');
  SELECT * FROM table_one;
  UPDATE table_one SET name='Eg2a IncAp' WHERE id=2;
  SELECT * FROM table_one;
##setup source/destination/connection on webui
##check where cursors persisted
kubectl exec -it  `kubectl get pod -n airbyte |grep Running |grep airbyte-db-0 |awk '{print $1}'` -n airbyte -- psql -U airbyte -d db-airbyte
  SELECT * FROM state;
##wait untill a new sync is compledte, or start a manual sync
#destination, check the inserted/updated data with the timestamp updated other than inserted
docker exec -it airbyte-destination psql --username=postgres
  \dt;
  SELECT * FROM table_one;
##source, update the data, check updated data/timestamp correct
docker exec -it airbyte-source psql --username=postgres
  UPDATE table_one SET name='Eg2b IncAp' WHERE id=2;
  SELECT * FROM table_one;
#wait untill a new sync is compledte, or start a manual sync
#destination, check updated data/timestamp are correctly inserted into a new appended record
docker exec -it airbyte-destination psql --username=postgres
  \dt;
  SELECT * FROM table_one;
##source, insert new data, check inserted data/timestamp correct
docker exec -it airbyte-source psql --username=postgres
  INSERT INTO table_one(id, name) VALUES(3, 'Eg3 IncApp');
  SELECT * FROM table_one;;
#wait untill a new sync is compledte, or start a manual sync
#destination, check inserted data/timestamp are correctly inserted into a new appended record
docker exec -it airbyte-destination psql --username=postgres
  \dt;
  SELECT * FROM table_one;
#deduped
##source, create table with timestamp and also primary key added
##source, setup the trigger to update timestamp field for incremental sync
##source, insert the data, check all data/timestamp correct
##source, update the data, check updated data/timestamp correct
docker exec -it airbyte-source psql --username=postgres
  CREATE TABLE table_two(
    id integer PRIMARY KEY,
    name VARCHAR(200),
    updated_at timestamp DEFAULT NOW() NOT NULL
  );
  CREATE TRIGGER set_timestamp_on_table_two
  BEFORE UPDATE ON table_two
  FOR EACH ROW
  EXECUTE PROCEDURE trigger_set_timestamp();
  INSERT INTO table_two(id, name) VALUES(1, 'Eg1 DD+Hst');
  INSERT INTO table_two(id, name) VALUES(2, 'Eg2 DD+Hst');
  SELECT * FROM table_two;
  UPDATE table_two SET name='Eg2a DD+Hs' WHERE id=2;
  SELECT * FROM table_two;
##setup connection on webui
##check where cursors persisted
kubectl exec -it  `kubectl get pod -n airbyte |grep Running |grep airbyte-db-0 |awk '{print $1}'` -n airbyte -- psql -U airbyte -d db-airbyte
  SELECT * FROM state;
##wait untill a new sync is compledte, or start a manual sync
#destination, check the inserted/updated data with the timestamp updated other than inserted
docker exec -it airbyte-destination psql --username=postgres
  \dt;
  SELECT * FROM table_two;
##source, update the data, check updated data/timestamp correct
docker exec -it airbyte-source psql --username=postgres
  UPDATE table_two SET name='Eg2b DD+Hs' WHERE id=2;
  SELECT * FROM table_two;
#wait untill a new sync is compledte, or start a manual sync
#destination, check updated data/timestamp are correctly updated on existing record, no new appended record
docker exec -it airbyte-destination psql --username=postgres
  \dt;
  SELECT * FROM table_two;
##source, insert new data, check inserted data/timestamp correct
docker exec -it airbyte-source psql --username=postgres
  INSERT INTO table_two(id, name) VALUES(3, 'Eg3 DD+Hst');
  SELECT * FROM table_two;
#wait untill a new sync is compledte, or start a manual sync
#destination, check inserted data/timestamp are correctly inserted into a new appended record
docker exec -it airbyte-destination psql --username=postgres
  SELECT * FROM table_two;
##source, delete existing data, check records deleted
docker exec -it airbyte-source psql --username=postgres
  DELETE FROM table_two where id=3;
  SELECT * FROM table_two;
#wait untill a new sync is compledte, or start a manual sync
#destination, check data deleted on source side are still existing on destination side
docker exec -it airbyte-destination psql --username=postgres
  SELECT * FROM table_two;

2, CDC sync from mysql to postgresql
:<<EOF
https://airbyte.com/how-to-sync/mysql-to-postgresql-destination
https://airbyte.com/tutorials/mysql-change-data-capture-cdc
https://airbyte.com/tutorials/incremental-change-data-capture-cdc-replication
EOF
#setup source mysql instance
#in shouxieairflow project home
#docker run --name mysql8 -p 3306:3306 -v $PWD/my.cnf:/etc/mysql/my.cnf -v $PWD/airflow.sql:/airflow.sql -e MYSQL_ROOT_PASSWORD=root -d --restart=always mysql:8.0.35
docker exec -it mysql8 mysql -h127.0.0.1 -uroot -proot
  CREATE DATABASE airbyte;
  USE airbyte;
  CREATE TABLE cars(id INTEGER, name VARCHAR(200), PRIMARY KEY(id));7
  INSERT INTO cars VALUES(0, 'mazda');
  INSERT INTO cars VALUES(1, 'honda');
  CREATE USER 'airbyte'@'%' IDENTIFIED BY 'airbyte';
  GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'airbyte'@'%';
#setup destination postgresql instance
#docker run --restart=always --name airbyte-destination -e POSTGRES_PASSWORD=postgres -p 3000:5432 -d debezium/postgres:13
##setup source/destination/connection on webui
##check where cursors persisted
kubectl exec -it  `kubectl get pod -n airbyte |grep Running |grep airbyte-db-0 |awk '{print $1}'` -n airbyte -- psql -U airbyte -d db-airbyte
  SELECT * FROM state;
##wait untill a new sync is compledte, or start a manual sync
#destination, check the inserted/updated data with the timestamp updated other than inserted
docker exec -it airbyte-destination psql --username=postgres
  \dt;
  SELECT * FROM cars;
##source, update the data, check updated data/timestamp correct
docker exec -it mysql8 mysql -h127.0.0.1 -uroot -proot
  UPDATE cars SET name='toyota' WHERE id=1;
  SELECT * FROM cars;
#wait untill a new sync is compledte, or start a manual sync
#destination, check updated data/timestamp are correctly updated on existing record, no new appended record
docker exec -it airbyte-destination psql --username=postgres
  \dt;
  SELECT * FROM table_two;
##source, insert new data, check inserted data/timestamp correct
docker exec -it mysql8 mysql -h127.0.0.1 -uroot -proot
  INSERT INTO cars VALUES(2, 'byd');
  SELECT * FROM cars;
#wait untill a new sync is compledte, or start a manual sync
#destination, check inserted data/timestamp are correctly inserted into a new appended record
docker exec -it airbyte-destination psql --username=postgres
  SELECT * FROM table_two;
##source, delete existing data, check records deleted
docker exec -it mysql8 mysql -h127.0.0.1 -uroot -proot
  DELETE FROM cars where id=0;
  SELECT * FROM cars;
#wait untill a new sync is compledte, or start a manual sync
#destination, check data deleted on source side are still existing on destination side
docker exec -it airbyte-destination psql --username=postgres
  SELECT * FROM cars;

3, Download http csv into postgresql
#setup source csv with below 2 fields
:<<EOF
#source-file image http://访问有SSL问题，但是进入容器wget又没问题
#[SSL: WRONG_VERSION_NUMBER] wrong version number (_ssl.c:1129)'))
#Storage Provider: HTTPS Public Web
#URL: 
#  http://download.tensorflow.org/data/iris_training.csv
#  http://mmubu:2080/iris_training.csv
Storage Provider: SSH: Secure Shell
URL: 
  /workspace/dockerfile/airbyte/iris_training.csv
Reader Options:
  #{ "sep" : ",", "header" : null, "names": ["sepal_length", "sepal_width", "petal_length", "petal_width", "label"], "dtype": {"col1": "float", "col2": "float", "col3": "float", "col4": "float", "col5": "int"}, "skiprows": 1}
  #{ "sep" : ",", "header" : null, "names": ["sepal_length", "sepal_width", "petal_length", "petal_width", "label"], "skiprows": 1}
  #"dtype": {"col1": "float", "col2": "float", "col3": "float", "col4": "float", "col5": "int"}, 
  #{ "sep" : ",", "header" : null, "names": ["sepal_length", "sepal_width", "petal_length", "petal_width", "label"], "dtype": {"sepal_length": "float", "sepal_width": "float", "petal_length": "float", "petal_width": "float", "label": "int"}, "skiprows": 1}
  { "sep" : ",", "header" : null, "names": ["sepal_length", "sepal_width", "petal_length", "petal_width", "label"], "dtype": {"sepal_length": "float", "sepal_width": "float", "petal_length": "float", "petal_width": "float", "label": "str"}, "skiprows": 1}
指定数据类型报错：
2024-04-15 10:59:04 source > Marking stream iris as STOPPED
2024-04-15 10:59:04 source > invalid literal for int() with base 10: 'label' 
去掉类型还是按照自动数字numeric(38,9)来创建字段，转成数字报一样的错 
把label指定为str还是在报一样的错
EOF
#setup connection to postgresql destination
#destination, check synced data value/format correct
docker exec -it airbyte-destination psql --username=postgres
  \dt;
  SELECT * FROM iris;

4, Airflow and Airbyte OSS - Better Together
#https://airbyte.com/tutorials/how-to-use-airflow-and-airbyte-together
:<<EOF
reuse MySQL2Postgresql-cdc-source → Incremental-destination to trigger
http://dtpct:30080/workspaces/a3587c9d-12bc-42c3-9bb0-d111d231cc38/connections/61ae3f48-89a8-49f3-854e-2e999451d3f5/status
61ae3f48-89a8-49f3-854e-2e999451d3f5
start airflow
setup airbyte connection
  Conn Id: airbyte_conn_example
  Conn Type: HTTP
  Host: mmubu
  Port: 8080
EOF
cat << EOF > ../../shouxieairflow/dags/my_example_airbyte.py
from airflow import DAG
from airflow.utils.dates import days_ago
from airflow.providers.airbyte.operators.airbyte import AirbyteTriggerSyncOperator
from airflow.providers.airbyte.sensors.airbyte import AirbyteJobSensor 

with DAG(dag_id='my_example_airbyte_sync',
         default_args={'owner': 'airflow'},
         schedule=None,
         start_date=days_ago(1)
    ) as dag:

    airbyte_operator = AirbyteTriggerSyncOperator(
        task_id='airbyte_mysql2postgres_cdc_example_sync',
        airbyte_conn_id='airbyte_conn_example',
        connection_id='61ae3f48-89a8-49f3-854e-2e999451d3f5',
        asynchronous=False,
        timeout=3600,
        wait_seconds=3
    )

with DAG(dag_id='my_example_airbyte_async',
         default_args={'owner': 'airflow'},
         schedule=None,
         start_date=days_ago(1)
    ) as dag:

    airbyte_operator = AirbyteTriggerSyncOperator(
        task_id='airbyte_mysql2postgres_cdc_example_async',
        airbyte_conn_id='airbyte_conn_example',
        connection_id='61ae3f48-89a8-49f3-854e-2e999451d3f5',
        asynchronous=True,
    )

    airbyte_sensor = AirbyteJobSensor(
        task_id='airbyte_sensor_mysql2postgres_cdc_example_async',
        airbyte_conn_id='airbyte_conn_example',
        airbyte_job_id=airbyte_operator.output
    )

    airbyte_operator >> airbyte_sensor
EOF
docker exec -it mysql8 mysql -h127.0.0.1 -uroot -proot
  INSERT INTO cars VALUES(0, 'mazda');
  SELECT * FROM cars;
#trigger airflow sync dag/task and check if sync operator waiting airbyte sync done
#check if airbyte sync is triggered and executed, wait untill the sync is compledte
#destination, check inserted data/timestamp are correctly inserted into a new appended record
docker exec -it airbyte-destination psql --username=postgres
  SELECT * FROM cars;
docker exec -it mysql8 mysql -h127.0.0.1 -uroot -proot
  UPDATE cars SET name='guangzhou_toyota' WHERE id=1;
  SELECT * FROM cars;
#trigger airflow async dag/task and check if async sensor waiting airbyte sync done
#check if airbyte sync is triggered and executed, wait untill the sync is compledte
#destination, check updated data/timestamp are correctly and no new record appended
docker exec -it airbyte-destination psql --username=postgres
  SELECT * FROM cars;
