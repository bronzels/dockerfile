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

PRJ_FLINK_HOME=${PRJ_HOME}/flink

PATH=$PATH:${PRJ_HOME}:${PRJ_FLINK_HOME}

VENV_HOME=${WORK_HOME}/venv

DB_VERSION=5.7.28


cat << EOF > db-env.sh
DB_CONTAINER=mysql-binlog2
DB_PORT=3306
DB_USR=root
DB_PWD=123456
DB_PRIV="SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT"
DOCKER_DIR=${MYHOME}/dockervol/mysqlmaster/conf
INSIDE_DIR=/etc/mysql
EOF
cat << EOF > db-env.sh
DB_CONTAINER=ploardbx-binlog2
DB_PORT=8527
DB_USR=polardbx_root
DB_PWD=123456
DB_PRIV="SELECT, REPLICATION SLAVE, REPLICATION CLIENT"
INSIDE_DIR=/etc/mysql
EOF
. ./db-env.sh

#mysql
#主要一定要挪回去，不然需要重新生成tpcds数据
mv ${MYHOME}/dockervol/mysqlmaster/conf/data10 ${PRJ_FLINK_HOME}/tpcds-kit/tools/
rm -rf ${MYHOME}/dockervol/mysqlmaster
mkdir -p ${MYHOME}/dockervol/mysqlmaster/{data,log,conf}
cat << EOF > docker-compose-mysql.yml
version: "3.7"
services:
  mysql:
    image: mysql:${DB_VERSION}
    container_name: ${DB_CONTAINER}
    command: --default-authentication-plugin=DB_native_password
    restart: always
    environment:
      # root用户密码
      DB_ROOT_PASSWORD: ${DB_PWD}
      TZ: Asia/Shanghai
    ports:
      - 3306:3306
    volumes:
      - ${MYHOME}/dockervol/mysqlmaster/data:/var/lib/mysql
      - ${MYHOME}/dockervol/mysqlmaster/log:/var/log/mysql
      - ${MYHOME}/dockervol/mysqlmaster/conf:/etc/mysql
EOF

cat << EOF > ${MYHOME}/dockervol/mysqlmaster/conf/my.cnf
[mysqld]
## 局域网唯一
server_id=1
## 指定不需要同步的数据库名称
binlog-ignore-db=master
## 开启二进制日志功能
log-bin=/var/lib/mysql/mysql-bin
## 设置二进制日志使用内存大小（事务）
binlog_cache_size=1M
## 设置使用的二进制日志格式（mixed,statement,row）
binlog_format=ROW
## 二进制日志过期清理时间。默认值为0，表示不自动清理。
expire_logs_days=7
## 连接超时时间
interactive_timeout=60
wait_timeout=60
## 最大连接数
max_connections = 320
max_user_connections= 300
EOF

docker-compose -f docker-compose-mysql.yml up -d
docker-compose -f docker-compose-mysql.yml down


#polardb for mysql
#docker run -d --name ploardbx-binlog2 -p 8527:8527 registry.cn-hangzhou.aliyuncs.com/bronzels/polardbx-polardb-x-2.2.1:1.0
:<<EOF
cd ${VENV_HOME}
python3 -m venv polardbx
source polardbx/bin/activate
#Upgrade the PIP before installation
pip install --upgrade pip
#Install PXD
#Note: Mainland China users downloading packages from pypi is slow, you can download it from the AliCloud.
pip install -i https://mirrors.aliyun.com/pypi/simple/ pxd
#Install PolarDB-X
#Running the pxd tryout command to create an up-to-date version of the PolarDB-X database (with 1 node each of GMS, CN, DN, CDC).
#pxd tryout
#You can also specify the number of CN, DN, CDC nodes and the version with the following command.
pxd tryout -cn_replica 1 -cn_version latest -dn_replica 1 -dn_version latest -cdc_replica 1 -cdc_version latest
EOF

kubectl create namespace polardbx
helm repo add polardbx https://polardbx-charts.oss-cn-beijing.aliyuncs.com
helm install --namespace polardbx polardbx-operator polardbx/polardbx-operator

watch kubectl get all -n polardbx

helm uninstall --namespace polardbx polardbx-operator
kubectl get pod -n polardbx |grep -v Running |awk '{print $1}'| xargs kubectl delete pod "$1" -n polardbx --force --grace-period=0

mysql -h127.0.0.1 -P8527 -upolardbx_root -p${DB_PWD}


mysql -h127.1 -P8527 -upolardbx_root -p123456



docker stop ${DB_CONTAINER} && docker rm ${DB_CONTAINER}

docker logs -f ${DB_CONTAINER}

docker exec -it ${DB_CONTAINER} mysql -h127.0.0.1 -u${DB_USR} -p${DB_PWD} -P${DB_PORT} -e "SHOW DATABASES"

docker exec -it ${DB_CONTAINER} mysql -h127.0.0.1 -u${DB_USR} -p${DB_PWD} -P${DB_PORT}
  show global variables like "%binlog%";
  show global variables like "%log_bin%";

cat << EOF > flink_user_granting.sql
CREATE USER 'flink'@'%' IDENTIFIED BY 'flinkpw';
-- 授权
GRANT ${DB_PRIV} ON *.* TO 'flink'@'%' IDENTIFIED BY 'flinkpw';
-- 查看授权
SHOW GRANTS FOR 'flink'@'%';
FLUSH PRIVILEGES;
EOF

#docker exec -it ${DB_CONTAINER} mysql -h127.0.0.1 -u${DB_USR} -p${DB_PWD} -P${DB_PORT} < flink_user_granting.sql
docker cp flink_user_granting.sql ${DB_CONTAINER}:/
docker cp db-env.sh${DB_CONTAINER}:/
docker exec -it ${DB_CONTAINER} bash
  . /mysql-env.sh
  mysql -h127.0.0.1 -u${DB_USR} -p${DB_PWD} -P${DB_PORT} < /flink_user_granting.sql
:<<EOF
#polardbx
ERROR 3009 (HY000) at line 3: [15dc7fb279c00000][172.17.0.2:8527][polardbx]Unrecognized privilege name: RELOAD
ERROR 3009 (HY000) at line 3: [15dc83192ac00000][172.17.0.2:8527][polardbx]Unrecognized privilege name: SHOW DATABASES
EOF

docker exec -it ${DB_CONTAINER} mysql -h127.0.0.1 -uflink -pflinkpw -P${DB_PORT} -e "SHOW DATABASES"

cat << EOF > DB_mydb_products_orders.sql
CREATE DATABASE mydb;
USE mydb;
CREATE TABLE products (
  id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description VARCHAR(512),
  dt VARCHAR(10)
);
ALTER TABLE products AUTO_INCREMENT = 101;

INSERT INTO products
VALUES (default,"scooter","Small 2-wheel scooter","20201214"),
       (default,"car battery","12V car battery","20201214"),
       (default,"12-pack drill bits","12-pack of drill bits with sizes ranging from #40 to #3","20201214"),
       (default,"hammer","12oz carpenter's hammer","20211214"),
       (default,"hammer","14oz carpenter's hammer","20211214"),
       (default,"hammer","16oz carpenter's hammer","20211214"),
       (default,"rocks","box of assorted rocks","20221214"),
       (default,"jacket","water resistent black wind breaker","20221214"),
       (default,"spare tire","24 inch spare tire","20221214");

CREATE TABLE orders (
  order_id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
  order_date DATETIME NOT NULL,
  customer_name VARCHAR(255) NOT NULL,
  price DECIMAL(10, 5) NOT NULL,
  product_id INTEGER NOT NULL,
  order_status BOOLEAN NOT NULL -- Whether order has been placed
) AUTO_INCREMENT = 10001;

INSERT INTO orders
VALUES (default, '2020-07-30 10:08:22', 'Jark', 50.50, 102, false),
       (default, '2020-07-30 10:11:09', 'Sally', 15.00, 105, false),
       (default, '2020-07-30 12:00:30', 'Edward', 25.25, 106, false);
EOF

docker cp DB_mydb_products_orders.sql ${DB_CONTAINER}:/
docker exec -it ${DB_CONTAINER} bash
  . /mysql-env.sh
  mysql -h127.0.0.1 -u${DB_USR} -p${DB_PWD} -P${DB_PORT} < /DB_mydb_products_orders.sql
:<<EOF
polardbx导入一点数据非常慢，container死掉，再start就不断重启
=========================================================================

cdc is running.
try polardb-x by:
mysql -h127.1 -P8527 -upolardbx_root
Process dead. Exit.
stop cdc...
cdc is stopped.
stop cn...

Usage:
 kill [options] <pid|name> [...]

Options:
 -a, --all              do not restrict the name-to-pid conversion to processes
                        with the same uid as the present process
 -s, --signal <sig>     send specified signal
 -q, --queue <sig>      use sigqueue(2) rather than kill(2)
 -p, --pid              print pids without signaling them
 -l, --list [=<signal>] list signal names, or convert one to a name
 -L, --table            list signal names and numbers

 -h, --help     display this help and exit
 -V, --version  output version information and exit

For more details see kill(1).
cn is stopped.
stop dn & gms...
dn & gms are stopped.
start with mode=play
start polardb-x
start gms & dn...
EOF


docker exec -it ${DB_CONTAINER} mysql -uflink -pflinkpw -e "USE mydb; SELECT * FROM products;"

docker exec -it ${DB_CONTAINER} mysql -h127.0.0.1 -u${DB_USR} -p${DB_PWD} -P${DB_PORT} -e "CREATE DATABASE tpcds DEFAULT CHARSET utf8 COLLATE utf8_general_ci"

