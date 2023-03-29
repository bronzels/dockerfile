#!/usr/bin/env bash
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Mac detected."
    #mac
    MYHOME=/Volumes/data
    SED=gsed
else
    echo "Assuming linux by default."
    #linux
    MYHOME=~
    SED=sed
fi

WORK_HOME=${MYHOME}/workspace
PRJ_HOME=${WORK_HOME}/dockerfile

VENV_HOME=${WORK_HOME}/venv

PRJ_FLINK_HOME=${PRJ_HOME}/flink

POSTGRESQL_VERSION=12.1

#postgresql
#主要一定要挪回去，不然需要重新生成tpcds数据
mv ${MYHOME}/dockervol/postgresql/data10 ${PRJ_FLINK_HOME}/tpcds-kit/tools/
rm -rf ${MYHOME}/dockervol/postgresql
mkdir -p ${MYHOME}/dockervol/postgresql
docker run --name postgres -e POSTGRES_PASSWORD=123456 -v ${MYHOME}/dockervol/postgresql:/var/lib/postgresql/data -p 5432:5432 -d postgres:12.1
docker run --name pgadmin -p 5080:80 \
  -e 'PGADMIN_DEFAULT_EMAIL=bronzels@hotmail.com' \
  -e 'PGADMIN_DEFAULT_PASSWORD=123456' \
  -e 'PGADMIN_CONFIG_ENHANCED_COOKIE_PROTECTION=True' \
  -e 'PGADMIN_CONFIG_LOGIN_BANNER="Authorised users only!"' \
  -e 'PGADMIN_CONFIG_CONSOLE_LOG_LEVEL=10' \
  -d dpage/pgadmin4:4.17


file=${MYHOME}/dockervol/postgresql/postgresql.conf
cp ${file} ${file}.bk
:<<EOF
# 更改wal日志方式为logical
wal_level = logical # minimal, replica, or logical

# 更改solts最大数量（默认值为10），flink-cdc默认一张表占用一个slots
max_replication_slots = 40 # max number of replication slots

# 更改wal发送最大进程数（默认值为10），这个值和上面的solts设置一样
max_wal_senders = 40 # max number of walsender processes
# 中断那些停止活动超过指定毫秒数的复制连接，可以适当设置大一点（默认60s）
wal_sender_timeout = 180s # in milliseconds; 0 disable　　
EOF
$SED -i 's/#wal_level = replica/wal_level = logical/g' ${file}
$SED -i 's/#max_replication_slots = 10/max_replication_slots = 40/g' ${file}
$SED -i 's/#max_wal_senders = 10/max_wal_senders = 40/g' ${file}
$SED -i 's/#wal_sender_timeout = 60s/wal_sender_timeout = 180s/g' ${file}

docker restart postgres

cat << EOF > db-env.sh
DB_CONTAINER=postgres
DB_PORT=5432
DB_USR=postgres
DB_PWD=123456EOF
DOCKER_DIR=${MYHOME}/dockervol/postgresql
INSIDE_DIR=/var/lib/postgresql/data
EOF
. ./db-env.sh 

docker exec -it ${DB_CONTAINER} psql -h 127.0.0.1 -p ${DB_PORT} -U ${DB_USR}

docker exec -it postgres bash

docker stop postgres && docker rm postgres

cat << EOF > flink_user_granting.sql
-- pg新建用户
CREATE USER flink WITH PASSWORD 'flinkpw';
-- 给用户复制流权限
ALTER ROLE flink replication;
-- 创建数据库
CREATE DATABASE mydb;
-- 给用户登录数据库权限
GRANT CONNECT ON DATABASE mydb to flink;
-- 把当前库public下所有表查询权限赋给用户
GRANT SELECT ON ALL TABLES IN SCHEMA public TO flink;
EOF

docker cp flink_user_granting.sql ${DB_CONTAINER}:/
docker cp db-env.sh ${DB_CONTAINER}:/
docker exec -it ${DB_CONTAINER} bash
  . /db-env.sh
  psql -h 127.0.0.1 -p ${DB_PORT} -U${DB_USR} -f /flink_user_granting.sql
  psql -h 127.0.0.1 -p ${DB_PORT} -d mydb -U flink

cat << EOF > postgre_mydb_products_orders.sql
CREATE SEQUENCE id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

CREATE TABLE products (
  id INT NOT NULL DEFAULT NEXTVAL('id_seq'),
  name VARCHAR(255) NOT NULL,
  description VARCHAR(512),
  dt VARCHAR(10),
  CONSTRAINT products_pkey PRIMARY KEY (id)
);

INSERT INTO products(name,description,dt)
VALUES ('scooter','Small 2-wheel scooter','20201214'),
       ('car battery','12V car battery','20201214'),
       ('12-pack drill bits','12-pack of drill bits with sizes ranging from #40 to #3','20201214'),
       ('hammer','12oz carpenter''s hammer','20211214'),
       ('hammer','14oz carpenter''s hammer','20211214'),
       ('hammer','16oz carpenter''s hammer','20211214'),
       ('rocks','box of assorted rocks','20221214'),
       ('jacket','water resistent black wind breaker','20221214'),
       ('spare tire','24 inch spare tire','20221214');

CREATE TABLE orders (
  id INT NOT NULL DEFAULT NEXTVAL('id_seq'),
  order_date TIMESTAMP NOT NULL,
  customer_name VARCHAR(255) NOT NULL,
  price DECIMAL(10, 5) NOT NULL,
  product_id INT NOT NULL,
  order_status BOOLEAN NOT NULL,
  CONSTRAINT orders_pkey PRIMARY KEY (id)
);

INSERT INTO orders(order_date,customer_name,price,product_id,order_status)
VALUES ('2020-07-30 10:08:22', 'Jark', 50.50, 102, FALSE),
       ('2020-07-30 10:11:09', 'Sally', 15.00, 105, FALSE),
       ('2020-07-30 12:00:30', 'Edward', 25.25, 106, FALSE);
EOF
cat << EOF > publication.sql
-- 设置发布为true
update pg_publication set puballtables=true where pubname is not null;
-- 把所有表进行发布
CREATE PUBLICATION dbz_publication FOR ALL TABLES;
-- 查询哪些表已经发布
SELECT * FROM pg_publication_tables;
EOF
docker cp postgre_mydb_products_orders.sql ${DB_CONTAINER}:/
docker cp publication.sql ${DB_CONTAINER}:/
docker exec -it ${DB_CONTAINER} bash
  . /db-env.sh
  psql -h 127.0.0.1 -p ${DB_PORT} -U${DB_USR} -d mydb -f /postgre_mydb_products_orders.sql
  psql -h 127.0.0.1 -p ${DB_PORT} -U${DB_USR} -d mydb -f /publication.sql
  psql -h 127.0.0.1 -p ${DB_PORT} -U${DB_USR} -d mydb
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO flink
  psql -h 127.0.0.1 -p ${DB_PORT} -d mydb -U flink
  cd /var/lib/postgresql/data/
  pg_dump -h 127.0.0.1 -p ${DB_PORT} -U${DB_USR}  -F c -b -v -f mydb.backup mydb
  #pg_restore -h 127.0.0.1 -p ${DB_PORT} -U${DB_USR} --dbname=mydb --create --jobs=4 --verbose mydb.backup

#after tpcds table created
  psql -h 127.0.0.1 -p ${DB_PORT} -U${DB_USR} -d tpcds
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO flink
  psql -h 127.0.0.1 -p ${DB_PORT} -U${DB_USR} -d tpcds -f /publication.sql
  cd /var/lib/postgresql/data/
  pg_dump -h 127.0.0.1 -p ${DB_PORT} -U${DB_USR}  -F c -b -v -f tpcds.backup tpcds
  #pg_restore -h 127.0.0.1 -p ${DB_PORT} -U${DB_USR} --dbname=tpcds --create --jobs=4 --verbose tpcds.backup
