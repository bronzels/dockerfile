git clone https://github.com/cubefs/cubefs-hadoop.git
#in idea
mvn package -Dmaven.test.skip=true

docker run --name centosdev -d --network=host -v /Volumes/data/workspace:/root/workspace harbor.my.org:1080/base/python:3.8-centos7-netutil-ccplus7-go tail -f /dev/null
#ssh remote dev
docker run --privileged --name centosdev -d -p 1022:22 -v /Volumes/data/workspace:/root/workspace harbor.my.org:1080/base/python:3.8-centos7-netutil-ccplus7-go-mpich /usr/sbin/init
  systemctl start sshd
  systemctl status sshd

docker exec -it centosdev /bin/bash

