git clone https://github.com/cubefs/cubefs-hadoop.git
#in idea
mvn package -Dmaven.test.skip=true

docker run --name linuxdev -d --network host -v $PWD/workspace:/root/workspace harbor.my.org:1080/base/python:3.8-centos7-netutil-ccplus7-go tail -f /dev/null
docker exec -it linuxdev /bin/bash
