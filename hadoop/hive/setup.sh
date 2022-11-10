
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Mac detected."
    #mac
    HIVEHOME=/Volumes/data/workspace/cluster-sh-k8s/hadoop/hive
    SED=gsed
else
    echo "Assuming linux by default."
    #linux
    HIVEHOME=~/hive
    SED=sed
fi

cd $HIVEHOME
cd image

hiverev=3.1.2
wget -c https://archive.apache.org/dist/hive/hive-${hiverev}/apache-hive-${hiverev}-bin.tar.gz

wget -c https://cdn.mysql.com//archives/mysql-connector-java-5.1/mysql-connector-java-5.1.47.tar.gz
tar xzvf mysql-connector-java-5.1.47.tar.gz
cp mysql-connector-java-5.1.47/mysql-connector-java-5.1.47.jar mysql-connector-java.jar

docker images|grep "<none>"|awk '{print $3}'|xargs docker rmi -f

docker images|grep hive
docker images|grep hive|awk '{print $3}'|xargs docker rmi -f
docker images|grep hive
#docker
ansible all -m shell -a"docker images|grep hive"
ansible all -m shell -a"docker images|grep hive|awk '{print \$3}'|xargs docker rmi -f"
#containerd
ansible all -m shell -a"crictl images|grep hive"
ansible all -m shell -a"crictl images|grep hive|awk '{print \$3}'|xargs crictl rmi"

docker build --build-arg HIVEREV=3.1.2 -t harbor.my.org:1080/bronzels/hive-ubu16ssh:0.1 ./
docker push harbor.my.org:1080/bronzels/hive-ubu16ssh:0.1

git clone git@github.com:chenlein/database-tools.git
cd database-tools
file=build.gradle
cp ${file} ${file}.bk
$SED -i "/    compile group: 'dm', name: 'Dm7JdbcDriver', version: '7.1', classifier: 'jdk17-20170808'/d" ${file}
$SED -i "s@    compile group: 'mysql', name: 'mysql-connector-java', version: '5.1.46'@    compile group: 'mysql', name: 'mysql-connector-java', version: '5.1.47'@g" ${file}
#高版本gradle如果出错请修改
$SED -i "s@compile@implementation@g" ${file}
$SED -i "s@testCompile@testImplementation@g" ${file}
$SED -i "s@runtime@runtimeClasspath@g" ${file}

gradle build
ls build/distributions/database-tools-1.0-SNAPSHOT.tar
cp build/distributions/database-tools-1.0-SNAPSHOT.tar ../

cd $HIVEHOME/image

docker images|grep "<none>"|awk '{print $3}'|xargs docker rmi -f

docker images|grep database-tools
docker images|grep database-tools|awk '{print $3}'|xargs docker rmi -f
docker images|grep database-tools
#docker
sudo ansible all -m shell -a"docker images|grep database-tools|awk '{print \$3}'|xargs docker rmi -f"
sudo ansible all -m shell -a"docker images|grep database-tools"
#containerd
sudo ansible all -m shell -a"crictl images|grep database-tools|awk '{print \$3}'|xargs crictl rmi"
sudo ansible all -m shell -a"crictl images|grep database-tools"

docker build -f Dockerfile.dbtool -t harbor.my.org:1080/bronzels/database-tools:1.0-SNAPSHOT ./
docker push harbor.my.org:1080/bronzels/database-tools:1.0-SNAPSHOT

cd $HIVEHOME
kubectl apply -n hadoop -f yaml/

cat << students.txt > EOF
EOF

:<<EOF
kubectl delete -n hadoop -f yaml/

kubectl describe pod -n hadoop `kubectl get pod -n hadoop | grep hive-serv | awk '{print $1}'`
kubectl logs -n hadoop `kubectl get pod -n hadoop | grep hive-serv | awk '{print $1}'`
kubectl cp employee.txt -n hadoop `kubectl get pod -n hadoop | grep hive-serv | awk '{print $1}'` /usr/local/hadoop/
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep hive-serv | awk '{print $1}'` -- bash
  hadoop fs -put ./employee.txt /tmp/
  hadoop fs -ls /tmp/
  hive
    create database test1;
    use test1;
    create table employee (eud int,name String,salary String,destination String) COMMENT 'Employee table' ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' STORED AS TEXTFILE;
    load data local inpath 'employee.txt' overwrite into table test1.employee;
    select * from employee;

kubectl get configmap hive-custom-config-cm-ext -n hadoop -o yaml

kubectl run test-myubussh -n hadoop -ti --image=praqma/network-multitool --rm=true --restart=Never -- bash

kubectl get pod -n hadoop -o wide
kubectl get pvc -n hadoop -o wide
kubectl get svc -n hadoop -o wide

EOF