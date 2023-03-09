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

HIVEHOME=${MYHOME}/workspace/dockerfile/hadoop/hive

HIVEREV=3.1.2
cd $HIVEHOME
cd image

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

file=Dockerfile
cp -f ${file}.template ${file}

#juicefs
distfs=juicefs
$SED -i 's@harbor.my.org:1080/chenseanxy/hadoop-ubussh@harbor.my.org:1080/chenseanxy/hadoop-ubussh-juicefs@g' ${file}
#cubefs
distfs=cubefs
$SED -i 's@harbor.my.org:1080/chenseanxy/hadoop-ubussh@harbor.my.org:1080/chenseanxy/hadoop-ubussh-cubefs@g' ${file}

git clone https://github.com/hortonworks/hive-testbench.git -b hdp3
cd hive-testbench
#for f in tpcds-setup.sh tpch-setup.sh; do
  f=tpcds-setup.sh
  file=hive-testbench/$f
  cp ${file} ${file}.bk
  #cp ${file}.bk ${file}
  $SED -i 's@HIVE="beeline -n hive -u@#HIVE="beeline -n hive -u@g' ${file}
  $SED -i '/#HIVE="beeline -n hive -u/a\HIVE="hive "\' ${file}
#done
cp -r settings settings.bk
#cp -r settings.bk settings
for file in settings/*.sql
do
  $SED -i 's@set hive.optimize.sort.dynamic.partition.threshold=0;@set hive.optimize.sort.dynamic.partition=true;@g' ${file}
done

docker build ./ --progress=plain --build-arg HIVEREV="${HIVEREV}" -t harbor.my.org:1080/bronzels/hive-ubussh-${distfs}:0.1
docker push harbor.my.org:1080/bronzels/hive-ubussh-${distfs}:0.1

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
#juicefs
distfs=juicefs
#cubefs
distfs=cubefs


#！！！tpcds数据生成时meta和client都需要足够资源，平时使用时为了节省系统资源删除资源配置
file=yaml/hive-deploy.yaml
cp -f ${file}.template ${file}
$SED -i "s@harbor.my.org:1080/bronzels/hive-ubussh:0.1@harbor.my.org:1080/bronzels/hive-ubussh-${distfs}:0.1@g" ${file}
:<<EOF
          resources:
            requests:
              memory: "8Gi"
              cpu: "2000m"
            limits:
              memory: "20Gi"
              cpu: "2000m"
EOF
file=yaml/hive-client.yaml
cp -f ${file}.template ${file}
$SED -i "s@harbor.my.org:1080/bronzels/hive-ubussh:0.1@harbor.my.org:1080/bronzels/hive-ubussh-${distfs}:0.1@g" ${file}
:<<EOF
          resources:
            requests:
              memory: "8Gi"
              cpu: "2000m"
            limits:
              memory: "20Gi"
              cpu: "2000m"
EOF

:<<EOF
beeline -n hive -u "jdbc:hive2://hive-service:9083/;auth=noSasl"
core-site.xml
      <property>
        <name>hadoop.proxyuser.hive.hosts</name>
        <value>*</value>
      </property>
      <property>
        <name>hadoop.proxyuser.hive.groups</name>
        <value>*</value>
      </property>

    <property>
        <name>hadoop.proxyuser.hdfs.hosts</name>
        <value>*</value>
    </property>
    <property>
        <name>hadoop.proxyuser.root.groups</name>
        <value>*</value>
    </property>
hive-site.xml
      <property>
        <name>hive.server2.enable.doAs</name>
        <value>false</value>
      </property>

      <property>
        <name>hive.optimize.sort.dynamic.partition</name>
        <value>true</value>
        <description>When enabled dynamic partitioning column will be globally sorted.
        This way we can keep only one record writer open for each partition value
        in the reducer thereby reducing the memory pressure on reducers.</description>
      </property>
      <property>
        <name>hive.exec.dynamic.partition.mode</name>
        <value>nostrict</value>
        <description>In strict mode, the user must specify at least one static partition in case the user accidentally overwrites all partitions.</description>
      </property>

set mapred.map.child.java.opts=-server -Xmx3072m -Djava.net.preferIPv4Stack=true;
set mapred.reduce.child.java.opts=-server -Xms2048m -Xmx4096m -Djava.net.preferIPv4Stack=true;
set mapreduce.map.memory.mb=2048;
set mapreduce.reduce.memory.mb=3072;
set io.sort.mb=800;

set mapreduce.job.reduces=8

  hive-env.sh: |-
    export HADOOP_CLIENT_OPTS="-Xms4096m  -Xmx4096m $HADOOP_CLIENT_OPTS"
  metastore.sh: |-
    THISSERVICE=metastore
    export SERVICE_LIST="${SERVICE_LIST}${THISSERVICE} "
    metastore() {
      echo "$(timestamp): Starting Hive Metastore Server"
      CLASS=org.apache.hadoop.hive.metastore.HiveMetaStore
      if $cygwin; then
      HIVE_LIB=`cygpath -w "$HIVE_LIB"`
      fi
      JAR=${HIVE_LIB}/hive-metastore-*.jar
      # hadoop 20 or newer - skip the aux_jars option and hiveconf
      export HADOOP_CLIENT_OPTS=" -Dproc_metastore $HADOOP_CLIENT_OPTS "
      export HIVE_METASTORE_HADOOP_OPTS="-Xmx14336m"
      export HADOOP_OPTS="$HIVE_METASTORE_HADOOP_OPTS $HADOOP_OPTS"
      exec $HADOOP jar $JAR $CLASS "$@"
    }
    metastore_help() {
      metastore -h
    }
    timestamp()
    {
      date +"%Y-%m-%d %T"
      date +"%Y-%m-%d %T"
    }

          resources:
            requests:
              memory: "6Gi"
              cpu: "2000m"
            limits:
              memory: "6Gi"
              cpu: "2000m"

          resources:
            requests:
              memory: "8Gi"
              cpu: "2000m"
            limits:
              memory: "16Gi"
              cpu: "2000m"

EOF

#如果没有安装hdfs/yarn单独安装hive
kubectl apply -n hadoop -f hadoop-configmap.yaml
kubectl delete -n hadoop -f hadoop-configmap.yaml

#需要先安装好nfs client sc
#kubectl apply -f meta-pvc.yaml -n hadoop
kubectl apply -n hadoop -f yaml/
kubectl delete -n hadoop -f yaml/
kubectl get pod -n hadoop |grep -v Running |awk '{print $1}'| xargs kubectl delete pod "$1" -n hadoop --force --grace-period=0
#kubectl delete -f meta-pvc.yaml -n hadoop
kubectl logs -n hadoop `kubectl get pod -n hadoop | grep hive-serv | awk '{print $1}'`

cat << students.txt > EOF
EOF

:<<EOF
kubectl delete -n hadoop -f yaml/

kubectl describe pod -n hadoop `kubectl get pod -n hadoop | grep hive-serv | awk '{print $1}'`
kubectl logs -n hadoop `kubectl get pod -n hadoop | grep hive-serv | awk '{print $1}'`
kubectl cp employee.txt -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'`:/app/hdfs/hive/
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep Running | grep hive-client | awk '{print $1}'` -- bash
  #hadoop fs -put employee.txt /tmp/
  #hadoop fs -ls /tmp/
  hive
    DROP DATABASE IF EXISTS test1 CASCADE;
    CREATE DATABASE test1;
    USE test1;
    CREATE TABLE employee (eud INT,name STRING,salary STRING,destination STRING) COMMENT 'Employee table' ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' STORED AS TEXTFILE;
    LOAD DATA LOCAL INPATH 'employee.txt' OVERWRITE INTO TABLE test1.employee;
    USE test1;
    SELECT * FROM employee;
    DROP DATABASE test1 CASCADE;

kubectl get configmap hive-custom-config-cm-ext -n hadoop -o yaml

kubectl run test-myubussh -n hadoop -ti --image=praqma/network-multitool --rm=true --restart=Never -- bash

kubectl get pod -n hadoop -o wide
kubectl get pvc -n hadoop -o wide
kubectl get svc -n hadoop -o wide

EOF