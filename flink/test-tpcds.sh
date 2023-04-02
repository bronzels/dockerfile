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

. ./db-env.sh

git clone git@github.com:gregrahn/tpcds-kit.git
cd tpcds-kit/tools
make OS=MACOS

cp *.sql ${DOCKER_DIR}/

docker exec -it ${DB_CONTAINER} bash
  . /db-env.sh
  #mysql
  mysql -h127.0.0.1 -u${DB_USR} -p${DB_PWD} -P${DB_PORT} -e "CREATE DATABASE tpcds"
  mysql -h127.0.0.1 -u${DB_USR} -p${DB_PWD} -P${DB_PORT} tpcds < /etc/mysql/tpcds.sql
  mysql -h127.0.0.1 -u${DB_USR} -p${DB_PWD} -P${DB_PORT} -e "USE tpcds;SHOW TABLES"
  #postgresql
  psql -h 127.0.0.1 -p ${DB_PORT} -U ${DB_USR}
    CREATE DATABASE tpcds;
  psql -h 127.0.0.1 -p ${DB_PORT} -U ${DB_USR} -d tpcds < /var/lib/postgresql/data/tpcds.sql
  psql -h 127.0.0.1 -p ${DB_PORT} -U ${DB_USR} -d tpcds
    \dt



cat << \EOF > remove_last_sep.sh
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

for i in `ls *.dat`
do
     name=$i
     echo $name
     $SED -i 's#|$##g' $name
done
EOF
chmod a+x remove_last_sep.sh

mkdir data10
./dsdgen -sc 10 -PARALLEL 4 -DIR 'data10/'
cd data10
chmod 777 *.dat
../remove_last_sep.sh
cd ..
mv data10 ${DOCKER_DIR}/

docker exec -it ${DB_CONTAINER} bash
  . /db-env.sh
  cd ${INSIDE_DIR}
  cp data10/call_center_1_4.dat call_center_1_4.dat
  #mysql
  mysql -h127.0.0.1 -u${DB_USR} -p${DB_PWD} -P${DB_PORT} tpcds -e "load data local infile '/etc/mysql/call_center_1_4.dat' into table call_center fields terminated by '|' lines terminated by '\n'"
  mysql -h127.0.0.1 -u${DB_USR} -p${DB_PWD} -P${DB_PORT} tpcds -e "SELECT * FROM call_center"
  mysql -h127.0.0.1 -u${DB_USR} -p${DB_PWD} -P${DB_PORT} tpcds -e "TRUNCATE TABLE call_center"
  #postgresql
  echo "COPY call_center FROM '${INSIDE_DIR}/call_center_1_4.dat' WITH DELIMITER AS '|' NULL '';" > call_center.sql
  psql -h 127.0.0.1 -p ${DB_PORT} -U${DB_USR} -d tpcds -f call_center.sql

  cd ${INSIDE_DIR}/data10
  for i in `ls *.dat`
  do
    name=$i
    echo $name
    table=`echo $i | sed "s/_1_4.dat//g"`

    #OLD_IFS="$IFS"
    #IFS="_"
    #arr=($name)
    #IFS="$OLD_IFS"
    #table=${arr[0]}

    echo $table
    #mysql -h127.0.0.1 -u${DB_USR} -p${DB_PWD} -P${DB_PORT} tpcds -e "COPY $table FROM '/etc/mysql/data10/$table.dat' WITH DELIMITER AS '|' NULL ''"
    #mysql -h127.0.0.1 -u${DB_USR} -p${DB_PWD} -P${DB_PORT} tpcds -e "LOAD DATA LOCAL INFILE '/etc/mysql/data10/$table.dat' INTO TABLE $table FIELDS TERMINATED BY '|' LINES TERMINATED BY '\n'"
    echo "COPY ${table} FROM '${INSIDE_DIR}/data10/${name}' WITH DELIMITER AS '|' NULL '';" > ${table}.sql
    cat ${table}.sql
    psql -h 127.0.0.1 -p ${DB_PORT} -U${DB_USR} -d tpcds -f ${table}.sql
  done

docker exec -it ${DB_CONTAINER} bash
  mysql -h127.0.0.1 -u${DB_USR} -p${DB_PWD} -P${DB_PORT} tpcds < /etc/mysql/tpcds_ri.sql
