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

MYSQL_VERSION_2BUILD=5.7.28
#MYSQL_VERSION_2BUILD=8.0.28

docker run --name mysql -p 3307:3306 -e MYSQL_ROOT_PASSWORD=newmysql -d mysql:8.0.28
docker cp mysql:/usr/local/bin/docker-entrypoint.sh docker-entrypoint-8.0.28.sh

f=x.sql
if [[ -f "$f".success ]]; then echo "$f is already executed, skipped"; else echo "execut $f" && echo "$f is executed" > $f.log 2>&1 && touch $f.success; cat $f.log; fi; echo ;
f=y.sql
if [[ -f "$f".success ]]; then echo "$f is already executed, skipped"; else echo "execut $f" && echo "$f is executed" > $f.log 2>&1 && touch $f.success; cat $f.log; fi; echo ;
f=z.sql
if [[ -f "$f".success ]]; then echo "$f is already executed, skipped"; else echo "execut $f" && echo "$f is executed" > $f.log 2>&1 && touch $f.success; cat $f.log; fi; echo ;
f=z.sql
if [[ -f "$f".success ]]; then echo "$f is already executed, skipped"; else echo "execut $f" && echo1 "$f is executed" > $f.log 2>&1 && touch $f.success; cat $f.log; fi; echo ;

f=x.sql
case "$f" in
    *.sh)     mysql_note "$0: running $f"; . "$f" ;;
    *.sql)    mysql_note "$0: running $f"; if [[ -f "$f".success ]]; then echo "$f is already executed, skipped"; else echo "execut $f" && echo "$f is executed" && touch $f.success; fi; echo ;;
    *.sql.gz) mysql_note "$0: running $f"; gunzip -c "$f" | docker_process_sql; echo ;;
    *)        mysql_warn "$0: ignoring $f" ;;
esac

:<<EOF
			*.sql)    mysql_note "$0: running $f"; docker_process_sql < "$f"; echo ;;
docker_process_sql < "$f"; echo ;;
    ->
if [[ -f ${DATADIR}/"$f".success ]]; then echo "$f is already executed, skipped"; else docker_process_sql < "$f" > ${DATADIR}/$f.log 2>&1 && touch ${DATADIR}/$f.success; cat ${DATADIR}/$f.log; fi; echo ;;
EOF

cat << EOF > /docker-entrypoint-initdb.d/01-DINKY.sql
-- create database
CREATE DATABASE IF NOT EXISTS dinky DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
-- create user and grant authorization
GRANT ALL ON dinky.* TO 'dinky'@'%' IDENTIFIED BY '___DINKY___';
EOF

cat << \EOF > test.sh
#!/usr/bin/env bash
DATADIR=/var/lib/mysql
DINKY_IDENTIFIED=dinkypw
_exec_sql_file_with_pwd_replaced_only_once() {
	local file="$1"
    echo "file:${file}"
	local filename=`basename ${file}`
    echo "filename:${filename}"
	local varname_wthno=`echo ${filename}|sed "s@.sql@@g"`
    echo "varname_wthno:${varname_wthno}"
	local varname=${varname_wthno:3}
    echo "varname:${varname}"
	if [[ -f ${DATADIR}/"$filename".success ]]; then 
		echo "$filename is already executed, skipped"
	else 
		cp "$file" /tmp/${filename}
		local secured_pwd_var=`eval echo '$'{${varname}_IDENTIFIED}`
        echo "secured_pwd_var:${secured_pwd_var}"
		sed -i "s@___${varname}___@${secured_pwd_var}@g" /tmp/${filename}
        #cat /tmp/${filename}
		#echo "docker_process_sql < /tmp/${filename}" > ${DATADIR}/$filename.log 2>&1
        docker_process_sql < /tmp/${filename} > ${DATADIR}/$filename.log 2>&1
		if [[ $? == 0 ]]; then
			touch ${DATADIR}/$filename.success
		fi
		rm -f /tmp/${filename}
		cat ${DATADIR}/$filename.log
	fi
}

# usage: docker_process_init_files [file [file [...]]]
#    ie: docker_process_init_files /always-initdb.d/*
# process initializer files, based on file extensions
docker_process_init_files() {
	# mysql here for backwards compatibility "${mysql[@]}"
	mysql=( docker_process_sql )

	#only line *.sql is modified to avoid sql executed every time container is restarted
	echo
	local f
	for f; do
		case "$f" in
			*.sh)     mysql_note "$0: running $f"; . "$f" ;;
			*.sql)    mysql_note "$0: running $f"; _exec_sql_file_with_pwd_replaced_only_once "$f"; echo ;;
			*.sql.gz) mysql_note "$0: running $f"; gunzip -c "$f" | docker_process_sql; echo ;;
			*)        mysql_warn "$0: ignoring $f" ;;
		esac
		echo
	done
}

docker_process_init_files /docker-entrypoint-initdb.d/*
EOF
chmod a+x test.sh
./test.sh

DOCKER_BUILDKIT=1 docker build ./ --progress=plain\
 --build-arg MYSQL_VERSION_2BUILD="${MYSQL_VERSION_2BUILD}"\
 -t harbor.my.org:1080/oltp/mysql:${MYSQL_VERSION_2BUILD}
docker push harbor.my.org:1080/oltp/mysql:${MYSQL_VERSION_2BUILD}

#docker
ansible all -m shell -a"docker images|grep 'oltp/mysql'"
ansible all -m shell -a"docker images|grep 'oltp/mysql'|awk '{print \$3}'|xargs docker rmi -f"
#containerd
ansible all -m shell -a"crictl images|grep 'oltp/mysql'"
ansible all -m shell -a"crictl images|grep 'oltp/mysql'|awk '{print \$3}'|xargs crictl rmi"

