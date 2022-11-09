git clone https://github.com/cubefs/cubefs-hadoop.git
#in idea
mvn package -Dmaven.test.skip=true

#ssh remote dev
docker run --privileged --name centosdev -d -p 1022:22 -v /Volumes/data/workspace:/root/workspace harbor.my.org:1080/base/python:3.8-centos7-netutil-ccplus7-go-mpich /usr/sbin/init
docker exec -it centosdev /bin/bash
  systemctl start sshd
  systemctl status sshd
ssh root@localhost -p 1022

