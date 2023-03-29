if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Mac detected."
    #mac
    os=darwin
    MYHOME=/Volumes/data
    SED=gsed
    bin=/Users/apple/bin
else
    echo "Assuming linux by default."
    #linux
    os=linux
    MYHOME=~
    SED=sed
    bin=/usr/local/bin
fi

WORK_HOME=${MYHOME}/workspace
PRJ_HOME=${WORK_HOME}/dockerfile

DORIS_HOME=${PRJ_HOME}/doris
#DORIS_REV=1.2.1
DORIS_REV=1.2.2

STARROCKS_REV=2.5.2
#STARROCKS_REV=3.0.0-avro
STARROCKS_OP_REV=1.3
#STARROCKS_OP_REV=master

#JUICEFS_VERSION=1.0.2
JUICEFS_VERSION=1.0.3

cd ${DORIS_HOME}

kubectl create ns doris

# doris start--------------------------------------------

:<<EOF
cpu如何检测是否支持AVX2
cat /proc/cpuinfo | grep avx2
EOF
ansible all -m shell -a"cat /proc/cpuinfo|grep flags|grep vmx"

:<<EOF
wget -c https://www.apache.org/dyn/mirrors/mirrors.cgi?action=download&filename=doris/1.2/1.2.1-rc01/apache-doris-1.2.1-src.tar.xz
wget -c https://www.apache.org/dyn/mirrors/mirrors.cgi?action=download&filename=doris/1.2/1.2.1-rc01/apache-doris-fe-1.2.1-bin-x86_64.tar.xz
wget -c https://www.apache.org/dyn/mirrors/mirrors.cgi?action=download&filename=doris/1.2/1.2.1-rc01/apache-doris-be-1.2.1-bin-x86_64.tar.xz
wget -c https://www.apache.org/dyn/mirrors/mirrors.cgi?action=download&filename=doris/1.2/1.2.1-rc01/apache-doris-dependencies-1.2.1-bin-x86_64.tar.xz
EOF

wget -c https://dist.apache.org/repos/dist/dev/doris/1.2.2-rc01/apache-doris-1.2.2-src.tar.gz
wget -c https://dist.apache.org/repos/dist/dev/doris/1.2.2-rc01/apache-doris-fe-1.2.2-bin-x86_64.tar.xz
wget -c https://dist.apache.org/repos/dist/dev/doris/1.2.2-rc01/apache-doris-be-1.2.2-bin-x86_64.tar.xz
wget -c https://dist.apache.org/repos/dist/dev/doris/1.2.2-rc01/apache-doris-dependencies-1.2.2-bin-x86_64.tar.xz

#tar xzvf apache-doris-${DORIS_REV}-src.tar.xz
tar xzvf apache-doris-${DORIS_REV}-src.tar.gz

cd apache-doris-${DORIS_REV}-src


cd thirdparty
#checksum问题
file=vars.sh
cp ${file} ${file}.bk
#$SED -i 's@BRPC_MD5SUM="556c024d5f770dbd2336ca4541ae8c96"@BRPC_MD5SUM="c3c148e672dc660ad48d8bd973f95dcf"@g' ${file}
$SED -i 's@S2_MD5SUM="d41d8cd98f00b204e9800998ecf8427e"@S2_MD5SUM="293552c7646193b8b4a01556808fe155"@g' ${file}
./download-thirdparty.sh
  #从fmt-7.1.3.tar.gz开始，手工下载mv到src目录
  #brpc的压缩文件和解压目录不一致, 1.2.2纠正了这个问题
  #mv src/brpc-1.2.0 /incubator-brpc-1.2.0
#确保cmake,byacc/automake/pcre/bison已安装
./build-thirdparty.sh

cd ${DORIS_HOME}
cd apache-doris-${DORIS_REV}-src
cd fs_brokers/apache_hdfs_broker/
#依赖华为云hadoop包，阿里云/华为云镜像都没有，需要手工下载安装
wget -c https://repo.huaweicloud.com/repository/maven/huaweicloudsdk/org/apache/hadoop/hadoop-huaweicloud/2.8.3/hadoop-huaweicloud-2.8.3.jar
mvn install:install-file -DgroupId=org.apache.hadoop -DartifactId=hadoop-huaweicloud -Dversion=2.8.3 -Dpackaging=jar -Dfile=hadoop-huaweicloud-2.8.3.jar
./build.sh
cd output/
tar czf apache_hdfs_broker.tar.gz apache_hdfs_broker/


cd ${DORIS_HOME}/apache-doris-${DORIS_REV}-src/docker/runtime/


tar xzvf ${DORIS_HOME}/apache-doris-dependencies-${DORIS_REV}-bin-x86_64.tar.xz
cd apache-doris-dependencies-${DORIS_REV}-bin-x86_64
tar czvf apache_hdfs_broker.tar.gz apache_hdfs_broker/
cd ..

arr=(fe be broker)
for prj in ${arr[*]}
do
  cd ${prj}

  file=Dockerfile
  #cp ${file}.bk ${file}
  #cp ${file} ${file}.bk
  $SED -i 's@FROM openjdk:8u342-jdk@FROM registry.cn-hangzhou.aliyuncs.com/bronzels/openjdk-8u342-jdk:1.0@g' ${file}
  $SED -i "/RUN apt-get update/i\RUN sed -i -E 's/(deb|security).debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list" ${file}
  if [[ "${prj}" != "be" ]]; then
    cp ${PRJ_HOME}/juicefs/juicefs-hadoop-${JUICEFS_VERSION}.jar ./
  fi
  if [[ "${prj}" == "fe" ]]; then
    $SED -i "/	apt-get install -y default-mysql-client/a\	apt install -y dnsutils bc && \\\\" ${file}
  else
    $SED -i "/	apt-get install -y default-mysql-client/a\	apt install -y dnsutils && \\\\" ${file}
  fi
  if [[ "${prj}" == "broker" ]]; then
    #mv ${DORIS_HOME}/apache-doris-${DORIS_REV}-src/fs_brokers/apache_hdfs_broker/output/apache_hdfs_broker.tar.gz resource/
    $SED -i 's@init_be.sh@init_broker.sh@g' ${file}
    mv ${DORIS_HOME}/apache-doris-${DORIS_REV}-src/docker/runtime/apache-doris-dependencies-${DORIS_REV}-bin-x86_64/apache_hdfs_broker.tar.gz resource/
cat << EOF >> ${file}
COPY juicefs-hadoop-1.0.2.jar /opt/apache-doris/broker/lib/
EOF
  else
    #tar xzvf ${DORIS_HOME}/apache-doris-${prj}-1.2.2-bin-x86_64.tar.xz -C resource/
    if [[ "${prj}" == "be" ]]; then
      cp ${DORIS_HOME}/apache-doris-${DORIS_REV}-src/docker/runtime/apache-doris-dependencies-${DORIS_REV}-bin-x86_64/java-udf-jar-with-dependencies.jar resource/
    else
      $SED -i 's@-bin@-bin-x86_64@g' ${file}
    fi
    #mv ${DORIS_HOME}/apache-doris-${prj}-${DORIS_REV}-bin-x86_64.tar.xz resource/
    $SED -i '/FROM /a\ARG DORIS_REV=' ${file}
    $SED -i 's@x.x.x@${DORIS_REV}@g' ${file}
    $SED -i "s@ADD ./resource/apache-doris-${prj}-\${DORIS_REV}-bin-x86_64.tar.gz /opt/@COPY ./resource/apache-doris-${prj}-\${DORIS_REV}-bin-x86_64 /opt/apache-doris-${prj}-\${DORIS_REV}-bin-x86_64@g" ${file}
    if [[ "${prj}" == "be" ]]; then
      $SED -i '/ADD ./resource\/init_be.sh \/opt\/apache-doris\/be\/bin/a\ADD resource\/java-udf-jar-with-dependencies.jar \/opt\/apache-doris\/be\/lib/' ${file}
    fi
    if [[ "${prj}" == "fe" ]]; then
cat << EOF >> ${file}
COPY juicefs-hadoop-1.0.2.jar /opt/apache-doris/fe/lib/
EOF
    fi
  fi
  $SED -i 's/ENTRYPOINT/#ENTRYPOINT/g' ${file}
  $SED -i '/resource\/init/,+1d' ${file}
  $SED -i '/RUN chmod 755 \/opt\/apache-doris/,+1d' ${file}

  cd ..
done


#arr=(fe be broker)
arr=(be broker)
arr=(be)
for prj in ${arr[*]}
do
  cd ${prj}
  docker build ./ --progress=plain --build-arg DORIS_REV="${DORIS_REV}" -t harbor.my.org:1080/doris/doris-${prj}:${DORIS_REV}
  docker push harbor.my.org:1080/doris/doris-${prj}:${DORIS_REV}
  cd ..
done

#docker
ansible all -m shell -a"docker images|grep doris-"
ansible all -m shell -a"docker images|grep doris-|awk '{print \$3}'|xargs docker rmi -f"
#containerd
ansible all -m shell -a"crictl images|grep doris-"
ansible all -m shell -a"crictl images|grep doris-|awk '{print \$3}'|xargs crictl rmi"
ansible all -m shell -a"crictl images|grep doris-fe|awk '{print \$3}'|xargs crictl rmi"
ansible all -m shell -a"crictl images|grep doris-be|awk '{print \$3}'|xargs crictl rmi"
ansible all -m shell -a"crictl images|grep doris-broker|awk '{print \$3}'|xargs crictl rmi"


cd ${DORIS_HOME}

#git clone git@github.com:mfanoffice/dataease-helm.git
git clone git@github.com:mfanoffice/k8s-doris.git k8s-doris-orig
cp -r k8s-doris-orig k8s-doris

ansible all -m shell -a"rm -rf /data0/doris;mkdir -p /data0/doris/fe;mkdir -p /data0/doris/be;mkdir -p /data0/doris/broker"

rm -rf pvs
mkdir pvs

for prj in {fe,be,broker}
do
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
   name: doris-local-storage-${prj}
provisioner: kubernetes.io/no-provisioner
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
EOF
  if [[ "${prj}" =~ "fe" ]]; then
    capacity=10Gi
  elif [[ "${prj}" =~ "broker" ]]; then
    capacity=1Gi
  else
    capacity=40Gi
  fi
cat << EOF > doris-pv-template-${prj}.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
   name: myhost-doris-${prj}
   labels:
     app: doris-${prj}
spec:
   capacity:
      storage: ${capacity}
   volumeMode: Filesystem
   accessModes:
   - ReadWriteOnce
   persistentVolumeReclaimPolicy: Retain
   storageClassName: doris-local-storage-${prj}
   local:
      path: /data0/doris/${prj}
   nodeAffinity:
      required:
         nodeSelectorTerms:
         - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
              - myhost
EOF

  for myhost in {dtpct,mdubu,mdlapubu}
  do
    echo "myhost:${myhost}"
    cp doris-pv-template-${prj}.yaml pvs/doris-pv-${prj}-${myhost}.yaml
    sed -i "" "s/myhost/${myhost}/g" pvs/doris-pv-${prj}-${myhost}.yaml
    cat pvs/doris-pv-${prj}-${myhost}.yaml
  done

done

kubectl get sc | grep doris

kubectl apply -f pvs/
kubectl delete -f pvs/
kubectl get pv | grep doris

rm -f k8s-doris/doris-pvc.yaml
rm -f k8s-doris/*Dockerfile
for prj in {fe,be}
do
  PRJ=`echo "${prj}" | tr '[a-z]' '[A-Z]'`
  file=k8s-doris/${PRJ}-deployment.yaml
  mv ${file} k8s-doris/${prj}-statefulset.yaml
  newfile=k8s-doris/${prj}-statefulset.yaml
  $SED -i 's@kind: Deployment@kind: StatefulSet@g' ${newfile}
  $SED -i 's@  replicas: 1@  replicas: 3@g' ${newfile}
  if [[ "${prj}" =~ "fe" ]]; then
    capacity=10Gi
    $SED -i '/      volumeMounts:/,+3d' ${newfile}
cat << EOF >> ${newfile}
          volumeMounts:
            - mountPath: /opt/apache-doris/fe/doris-meta
              name: volume-fe
EOF
  else
    capacity=40Gi
  fi
  $SED -i '/      volumes:/,+3d' ${newfile}
cat << EOF >> ${newfile}
            - name: config-init-volume
              mountPath: /tmp/preconf
      volumes:
        - name: config-init-volume
          configMap:
            name: doris-configmap
            defaultMode: 493
  volumeClaimTemplates:
    - metadata:
        name: volume-${prj}
      spec:
        accessModes: [ "ReadWriteOnce" ]
        resources:
          requests:
            storage: ${capacity}
        storageClassName: "doris-local-storage-${prj}"
EOF
done

for prj in {fe,be}
do
  newfile=k8s-doris/${prj}-statefulset.yaml
  #$SED -i "s@tail -f /dev/null@/tmp/preconf/wait-es.sh ${prj} 3@g" ${newfile}
  $SED -i "s@          image: uhub.service.ucloud.cn/dataease/doris-${prj}:v1.1.3@          image: harbor.my.org:1080/doris/doris-${prj}:${DORIS_REV}@g" ${newfile}
  $SED -i '/  selector:/i\  serviceName: '${prj}'-service' ${newfile}
  $SED -i '/      hostNetwork: true/i\      nodeSelector:' ${newfile}
  $SED -i '/      nodeSelector:/a\        component.doris/'${prj}': enabled' ${newfile}
  $SED -i 's@/opt/doris@/opt/apache-doris/'${prj}'@g' ${newfile}
done

cp fe.yaml k8s-doris/
cp be-service.yaml k8s-doris/
:<<EOF
cp doris-configmap.yaml k8s-doris/
cp add-bes2fe-job.yaml k8s-doris/
EOF

kubectl label node dtpct component.doris/fe=enabled
kubectl label node mdubu component.doris/fe=enabled
kubectl label node mdlapubu component.doris/fe=enabled

kubectl label node dtpct component.doris/be=enabled
kubectl label node mdubu component.doris/be=enabled
kubectl label node mdlapubu component.doris/be=enabled

kubectl label node dtpct component.doris/broker=enabled
kubectl label node mdubu component.doris/broker=enabled
kubectl label node mdlapubu component.doris/broker=enabled

kubectl apply -f pvs/

kubectl create cm doris-configmap -n doris --from-file=k8s-doris/conf
kubectl apply -n doris -f k8s-doris/

kubectl get all -n doris
watch kubectl get all -n doris

kubectl describe pod -n doris doris-be-0
kubectl describe pod -n doris doris-fe-0
kubectl describe pod -n doris doris-fe-1

kubectl delete pod -n doris --force --grace-period=0 doris-fe-0
kubectl logs -n doris doris-fe-0
kubectl logs -f -n doris doris-fe-0
kubectl delete pod -n doris --force --grace-period=0 doris-fe-1
kubectl logs -n doris doris-fe-1
kubectl logs -f -n doris doris-fe-1
kubectl delete pod -n doris --force --grace-period=0 doris-be-0
kubectl logs -n doris doris-be-0
kubectl logs -f -n doris doris-be-0
kubectl delete pod -n doris --force --grace-period=0 doris-broker-0
kubectl logs -n doris doris-broker-0
kubectl logs -f -n doris doris-broker-0


kubectl get pvc -n doris
kubectl get pv | grep doris

kubectl delete -n doris -f k8s-doris/
kubectl delete cm doris-configmap -n doris --grace-period=5
sleep 3
#kubectl delete cm doris-configmap -n doris
###
kubectl get pod -n doris |grep -v Running |awk '{print $1}'| xargs kubectl delete pod "$1" -n doris --force --grace-period=0
#kubectl get pod -n doris |grep -v Running |awk '{print $1}'| xargs kubectl delete pod "$1" -n doris --grace-period=200
###
kubectl get pvc -n doris | awk '{print $1}' | xargs kubectl delete pvc -n doris
kubectl delete -f pvs/
ansible all -m shell -a"rm -rf /data0/doris;mkdir -p /data0/doris/fe;mkdir -p /data0/doris/be;mkdir -p /data0/doris/broker"

ansible all -m shell -a"ls /data0/doris/"

kubectl get pod -n doris -o wide
:<<EOF
0     192.168.3.6     mdlapubu
1     192.168.3.14    dtpct
2     192.168.3.103   mdub

#HA测试
:<<EOF
fe.conf
metadata_failure_recovery=true

关机脚本需要加入，或者关机之前执行：
kubectl delete pods --all --grace-period=60 -n doris

集群正常
1, mysql --default-character-set=utf8 -h fe -P 9030 -u'root' -e"SHOW PROC '/frontends'"
2, mysql --default-character-set=utf8 -h fe -P 9030 -u'root' -e"SHOW PROC '/backends'"
3，8030 fe转发的web界面查询已有数据正常

1, 初次安装fe-0缺省是leader，重启集群多次以后，第1次杀掉fe-0
fe-1成为master而且ReplayedJournalId最大，集群正常

2, fe-1是leader情况下，第2次杀掉fe-0
集群正常

3, fe-1是leader情况下，重启整个集群delete all pods
集群正常

4, fe-1是leader情况下，第3次杀掉fe-0
集群正常

5，fe-1是leader情况下，第1次杀掉fe-2
集群正常

6, fe-1是leader情况下，重启整个集群，删除yaml重新创建
集群正常

7，fe-1是leader情况下，第1次杀掉be-0
集群正常

8，fe-1是leader情况下，第2次杀掉be-0
集群正常

9，fe-1是leader情况下，第1次杀掉fe-1
fe-0成为master而且ReplayedJournalId最大，集群正常

10，fe-0是leader情况下，第2次杀掉fe-1
集群正常

11，fe-0是leader情况下，杀掉fe-0
fe-1成为master而且ReplayedJournalId最大，集群正常，svc portforward需要重新执行

12，fe-1是leader情况下，重启物理机集群
fe-1是master而且ReplayedJournalId最大，集群正常，svc portforward需要重新执行
  把物理集群重启后，会出现偶尔连不上fe master的query端口，fe的log和warn log也有一些打印
  mysql命令-h参数，不管是指定svc，svc的ip，还是master的直连ip，3种方式都有1/10概率连不上，直连ip出问题概率还要大一点，感觉不是网络或者负载均衡问题的问题

mysql连接问题，把fe的内存limit改到12g以后，连续测试20次
  pod.svc，，出现1次
  svc，出现3次
  svc的ip，出现1次
  还是master的直连ip，没出现

  #kubectl run mysql-client -n doris --rm --tty -i --restart='Never' --image docker.io/library/mysql:5.7 --command -- \
myhost="fe"
#myhost="doris-fe-1.fe"
#myhost="10.96.3.161"
#myhost="192.168.3.14"
let success_sum=0
let test_rounds=320
#sedstr="FOLLOWER | true"
sedstr="FOLLOWER	true"
for num in `seq 1 ${test_rounds}`
do
    mysql --default-character-set=utf8 -h ${myhost} -P 9030 -u'root' -e"SHOW PROC '/frontends'" \
    | grep "${sedstr}"
  if [[ $? == "0" ]]; then
    let success_sum+=1
  fi
done
echo "success_sum:${success_sum}"

myhost="192.168.3.14"
160，出现3次

myhost="doris-fe-1.fe"
40，没问题
80，出现1次

myhost="doris-fe-1.fe"
把request和limit增到到一样
80，出现2次

myhost="192.168.3.14"，进入不同非master pod执行
320，没问题

myhost="10.96.3.161"，进入不同非master pod执行
320，没问题

myhost="doris-fe-1.fe"，进入不同非master pod执行
320，没问题

myhost="fe"，进入不同非master pod执行
320，没问题

是kubectl run有问题

EOF


kubectl port-forward -n doris svc/fe 8030:8030 &
kubectl port-forward -n doris svc/fe 9030:9030 &

kubectl port-forward -n doris doris-be-0 8040:8040 &
kubectl port-forward -n doris doris-be-1 8041:8040 &
kubectl port-forward -n doris doris-be-2 8042:8040 &

kubectl delete pod -n doris doris-fe-0
kubectl delete pod -n doris doris-fe-0 --grace-period=30
kubectl exec -it -n doris `kubectl get pod -n doris | grep doris-fe-0 | awk '{print $1}'` -- tail -f /opt/apache-doris/fe/doris-meta/stop.log
kubectl exec -it -n doris `kubectl get pod -n doris | grep doris-fe-0 | awk '{print $1}'` -- cat /opt/apache-doris/fe/doris-meta/stop.log

kubectl delete pod -n doris doris-fe-1
kubectl delete pod -n doris doris-fe-1 --grace-period=30
kubectl exec -it -n doris `kubectl get pod -n doris | grep doris-fe-1 | awk '{print $1}'` -- tail -f /opt/apache-doris/fe/doris-meta/stop.log
kubectl exec -it -n doris `kubectl get pod -n doris | grep doris-fe-1 | awk '{print $1}'` -- cat /opt/apache-doris/fe/doris-meta/stop.log

kubectl delete pod -n doris doris-be-0
kubectl delete pod -n doris doris-be-0 --grace-period=30
kubectl exec -it -n doris `kubectl get pod -n doris | grep doris-be-0 | awk '{print $1}'` -- tail -f /opt/apache-doris/be/storage/stop.log
kubectl exec -it -n doris `kubectl get pod -n doris | grep doris-be-0 | awk '{print $1}'` -- cat /opt/apache-doris/be/storage/stop.log

kubectl delete pods --all --grace-period=120 -n doris
kubectl delete pods --all --grace-period=200 -n doris
kubectl delete pods --all --grace-period=360 -n doris

#重启host集群以后，fe状态不正常无法恢复，需要在重启以前先删除所有pod，调用stop_be/fe.sh，重启host集群以后才能正常
kubectl cp k8s-doris/conf/shutdown.sh -n doris `kubectl get pod -n doris | grep Running | grep doris-fe-0 | awk '{print $1}'`:/root/
#!/bin/bash
nmb1=1676123468.580202864
nmb2=1676123598.941084000
var1=`echo "scale=9;$nmb2 - $nmb1"|bc`
echo "$var1"
#130.360881136
#205.253036653
#372.109651414
kubectl exec -it -n doris `kubectl get pod -n doris | grep doris-fe-0 | awk '{print $1}'` -- \
cat /stop.log
kubectl exec -it -n doris `kubectl get pod -n doris | grep doris-fe-0 | awk '{print $1}'` -- \
tail -f /stop.log
kubectl exec -it -n doris `kubectl get pod -n doris | grep doris-fe-2 | awk '{print $1}'` -- ls -l /opt/apache-doris/fe/doris-meta

kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep doris-fe-0 | awk '{print $1}'` -- \
cat /opt/apache-doris/fe/doris-meta/common.conf
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep doris-be-0 | awk '{print $1}'` -- \
cat /opt/apache-doris/be/storage/common.conf


kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep doris-broker-0 | awk '{print $1}'` -- \
bash
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep doris-broker-0 | awk '{print $1}'` -- \
ls /opt/apache-doris/broker/log
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep doris-broker-0 | awk '{print $1}'` -- \
cat /opt/apache-doris/broker/log/apache_hdfs_broker.out
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep doris-broker-0 | awk '{print $1}'` -- \
cat /opt/apache-doris/broker/log/apache_hdfs_broker.log


srvmaxno=2
for num in `seq 0 ${srvmaxno}`
do
  kubectl run curl-json -it --image=radial/busyboxplus:curl --restart=Never --rm -- \
    curl http://doris-fe-${srvmaxno}.fe.doris.svc.cluster.local:8030/api/bootstrap
  kubectl run curl-json -it --image=radial/busyboxplus:curl --restart=Never --rm -- \
    curl http://doris-be-${srvmaxno}.be-service.doris.svc.cluster.local:8040/api/health
done
:<<EOF
{"msg":"success","code":0,"data":{"replayedJournalId":0,"queryPort":0,"rpcPort":0,"version":""},"count":0}pod "curl-json" deleted
{"status": "OK","msg": "To Be Added"}pod "curl-json" deleted
{"msg":"success","code":0,"data":{"replayedJournalId":0,"queryPort":0,"rpcPort":0,"version":""},"count":0}pod "curl-json" deleted
{"status": "OK","msg": "To Be Added"}pod "curl-json" deleted
{"msg":"success","code":0,"data":{"replayedJournalId":0,"queryPort":0,"rpcPort":0,"version":""},"count":0}pod "curl-json" deleted
{"status": "OK","msg": "To Be Added"}pod "curl-json" deleted
EOF

kubectl run mysql-client --rm --tty -i --restart='Never' --image docker.io/library/mysql:5.7 --command -- \
  mysql --default-character-set=utf8 -h fe.doris.svc.cluster.local -P 9030 -u'root' \
  -e'SHOW DATABASES'
#默认的用户名和密码是 root/空的

# doris end--------------------------------------------


# starrocks start--------------------------------------------
cd ${DORIS_HOME}

wget -c https://releases.starrocks.io/starrocks/StarRocks-${STARROCKS_REV}.tar.gz
tar xzvf StarRocks-${STARROCKS_REV}.tar.gz

mkdir starrocks-src
wget -c https://github.com/StarRocks/starrocks/archive/refs/tags/${STARROCKS_REV}.tar.gz -O starrocks-src/
cd starrocks-src/
tar xzvf starrocks-${STARROCKS_REV}.tar.gz
mkdir ../tmp/
mv starrocks-2.5.2.tar.gz ../tmp/

cd ${DORIS_HOME}/starrocks-src/starrocks-${STARROCKS_REV}

mv ${DORIS_HOME}/StarRocks-${STARROCKS_REV} ${DORIS_HOME}/starrocks-src/starrocks-${STARROCKS_REV}/output
sudo scp dtpct:/data0/starrocks-3.0.0-avro/output.tgz ./
tar xzvf output.tgz
rm -rf output.tgz

cp ${PRJ_HOME}/juicefs/juicefs-hadoop-${JUICEFS_VERSION}-jdk11-ubuntu22.jar ./
cp ${PRJ_HOME}/juicefs/juicefs-hadoop-${JUICEFS_VERSION}-jdk11-centos7.jar ./
cp ${PRJ_HOME}/juicefs/core-site.xml ./
cp ${PRJ_HOME}/spark/hdfs-site.xml ./
cp ${PRJ_HOME}/spark/hive-site.xml ./
cp ${PRJ_HOME}/image/Centos-7.repo ./
cp ${PRJ_HOME}/image/epel-7.repo ./
arr=(Dockerfile-fe-ubuntu Dockerfile_be_centos Dockerfile_cn_centos)
for dfile in ${arr[*]}
do
  echo "DEBUG >>>>>> dfile:${dfile}"
  if [[ "${dfile}" == "Dockerfile-fe-ubuntu" ]]; then
    OLD_IFS="$IFS"
    IFS="-"
    arr=($dfile)
    IFS="$OLD_IFS"
    prj=${arr[1]}
  else
    OLD_IFS="$IFS"
    IFS="_"
    arr=($dfile)
    IFS="$OLD_IFS"
    prj=${arr[1]}
  fi
  echo "DEBUG >>>>>> prj:${prj}"

  file=docker/dockerfiles/${dfile}  
  cp  ${file} ${file}.bk
  if [[ "${prj}" == "cn" ]]; then
    $SED -i 's/java-11-openjdk/java-11-openjdk bc/g' ${file}
  fi
  if [[ "${prj}" == "fe" ]]; then
    $SED -i '/RUN git clone /,+2d' ${file}
    $SED -i "s@COPY --from=builder /opt/starrocks/fe@COPY output/fe@g" ${file}
    $SED -i 'COPY output/a\COPY docker\/dockerfiles\/fe\/fe_entrypoint.sh docker\/dockerfiles\/fe\/fe_prestop.sh \/opt\/starrocks\/' ${file}
    $SED -i '/RUN apt-get update -y/i\RUN sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list' ${file}
cat << \EOF >> ${file}
ARG JUICEFS_VERSION=?
COPY juicefs-hadoop-${JUICEFS_VERSION}-jdk11-ubuntu22.jar /opt/starrocks/${prj}/lib/
EOF
  else
    $SED -i '/RUN yum install -y/i\RUN rm -f \/etc\/yum.repos.d\/CentOS-Base.repo\nCOPY Centos-7.repo \/etc\/yum.repos.d\/Centos-7.repo\nCOPY epel-7.repo \/etc\/yum.repos.d\/epel-7.repo\nRUN yum clean all && yum makecache && yum -y update' ${file}
cat << \EOF >> ${file}
ARG JUICEFS_VERSION=?
COPY juicefs-hadoop-${JUICEFS_VERSION}-jdk11-centos7.jar /opt/starrocks/${prj}/lib/
EOF
  fi
cat << EOF >> ${file}
COPY core-site.xml /opt/starrocks/${prj}/conf/
COPY hdfs-site.xml /opt/starrocks/${prj}/conf/
COPY hive-site.xml /opt/starrocks/${prj}/conf/
EOF
done

arr=(Dockerfile-fe-ubuntu Dockerfile_be_centos Dockerfile_cn_centos)
arr=(Dockerfile_be_centos Dockerfile_cn_centos)
arr=(Dockerfile-fe-ubuntu)
for dfile in ${arr[*]}
do
  echo "DEBUG >>>>>> dfile:${dfile}"
  if [[ "${dfile}" == "Dockerfile-fe-ubuntu" ]]; then
    OLD_IFS="$IFS"
    IFS="-"
    arr=($dfile)
    IFS="$OLD_IFS"
    prj=${arr[1]}
  else
    OLD_IFS="$IFS"
    IFS="_"
    arr=($dfile)
    IFS="$OLD_IFS"
    prj=${arr[1]}
  fi
  echo "DEBUG >>>>>> prj:${prj}"

  DOCKER_BUILDKIT=1 docker build ./ -f docker/dockerfiles/${dfile}\
   --build-arg JUICEFS_VERSION="${JUICEFS_VERSION}"\
   --progress=plain -t harbor.my.org:1080/doris/starrocks-juicefs-${prj}:${STARROCKS_REV}
  docker push harbor.my.org:1080/doris/starrocks-juicefs-${prj}:${STARROCKS_REV}
done

#docker
ansible all -m shell -a"docker images|grep starrocks-"
ansible all -m shell -a"docker images|grep starrocks-|awk '{print \$3}'|xargs docker rmi -f"
#containerd
ansible all -m shell -a"crictl images|grep starrocks-"
ansible all -m shell -a"crictl images|grep starrocks-|awk '{print \$3}'|xargs crictl rmi"

#docker
ansible all -m shell -a"docker images|grep starrocks-juicefs"
ansible all -m shell -a"docker images|grep starrocks-juicefs|awk '{print \$3}'|xargs docker rmi -f"
#containerd
ansible all -m shell -a"crictl images|grep starrocks-juicefs"
ansible all -m shell -a"crictl images|grep starrocks-juicefs|awk '{print \$3}'|xargs crictl rmi"


cd ${DORIS_HOME}

#2023-3-2
git clone git@github.com:StarRocks/starrocks-kubernetes-operator.git
mv starrocks-kubernetes-operator starrocks-kubernetes-operator-master
:<<EOF
wget -c https://github.com/StarRocks/starrocks-kubernetes-operator/archive/refs/tags/v${STARROCKS_OP_REV}.tar.gz
tar xzvf starrocks-kubernetes-operator-${STARROCKS_OP_REV}.tar.gz
EOF

file=${DORIS_HOME}/starrocks-kubernetes-operator-${STARROCKS_OP_REV}/deploy/operator.yaml
#cp ${file}.bk ${file}
cp ${file} ${file}.bk
#cp ${file} ${file}.doris.ns
#cp ${file}.doris.ns ${file}
$SED -i '1,7d' ${file}
$SED -i 's/namespace: starrocks/namespace: doris/g' ${file}
EOF

kubectl apply -f ${DORIS_HOME}/starrocks-kubernetes-operator-${STARROCKS_OP_REV}/deploy/starrocks.com_starrocksclusters.yaml
kubectl apply -f ${DORIS_HOME}/starrocks-kubernetes-operator-${STARROCKS_OP_REV}/deploy/operator.yaml

kubectl delete -f ${DORIS_HOME}/starrocks-kubernetes-operator-${STARROCKS_OP_REV}/deploy/operator.yaml
kubectl delete -f ${DORIS_HOME}/starrocks-kubernetes-operator-${STARROCKS_OP_REV}/deploy/starrocks.com_starrocksclusters.yaml

cd starrocks-kubernetes-operator-${STARROCKS_OP_REV}/examples/starrocks
file=starrocks-fe-and-be.yaml
clusterfile=starrocks-fe-and-be-and-cn-with-autoscaler.yaml
cp ${file} ${DORIS_HOME}/${clusterfile}
cp starrocks-fe-and-cn-with-autoscaler.yaml swap
$SED -i '1,12d' swap
echo "" >> ${DORIS_HOME}/${clusterfile}
cat swap >> ${DORIS_HOME}/${clusterfile}
rm -f swap
$SED -i 's/2.4.1/2.5.2/g' ${DORIS_HOME}/${clusterfile}
$SED -i 's/2.5.2/3.0.0-avro/g' ${DORIS_HOME}/${clusterfile}
$SED -i 's/namespace: starrocks/namespace: doris/g' ${DORIS_HOME}/${clusterfile}
$SED -i 's/starrocks\/alpine-fe/harbor.my.org:1080\/doris\/starrocks-fe/g' ${DORIS_HOME}/${clusterfile}
$SED -i 's/starrocks\/centos-be/harbor.my.org:1080\/doris\/starrocks-be/g' ${DORIS_HOME}/${clusterfile}
$SED -i 's/starrocks\/centos-cn/harbor.my.org:1080\/doris\/starrocks-cn/g' ${DORIS_HOME}/${clusterfile}
$SED -i 's/starrockscluster-sample/starrockscluster/g' ${DORIS_HOME}/${clusterfile}
$SED -i 's/starrockscluster-sample/starrockscluster/g' ${DORIS_HOME}/${clusterfile}
$SED -i 's/cpu: 4/cpu: 2/g' ${DORIS_HOME}/${clusterfile}
#fe 1cpu as 1 fe is pending due to no available CPU res
#fe replicas is set to 1 as always 1 fe pending even CPU is set to 1
$SED -i 's/memory: 16Gi/memory: 8Gi/g' ${DORIS_HOME}/${clusterfile}
$SED -i "/  starRocksFeSpec:/a\    storageVolumes:\n      - name: fe-meta\n        storageClassName: juicefs-sc\n        storageSize: 1Gi\n        mountPath: /opt/starrocks/fe/meta" ${DORIS_HOME}/${clusterfile}
$SED -i "/  starRocksBeSpec:/a\    storageVolumes:\n      - name: be-data\n        storageClassName: juicefs-sc\n        storageSize: 50Gi\n        mountPath: /opt/starrocks/be/storage" ${DORIS_HOME}/${clusterfile}

cd ${DORIS_HOME}

clusterfile=starrocks-fe-and-be-and-cn-with-autoscaler.yaml

#hive外表tpcds测试
:<<EOF
  starRocksBeSpec:
    storageVolumes:
      - name: be-data
        storageClassName: juicefs-sc
        storageSize: 50Gi
        mountPath: /opt/starrocks/be/storage
    image: harbor.my.org:1080/doris/starrocks-juicefs-be:2.5.2
    replicas: 3->1
    requests:
      cpu: 2->1
      memory: 8Gi->4
  starRocksCnSpec:
    image: harbor.my.org:1080/doris/starrocks-juicefs-cn:2.5.2
    requests:
      cpu: 2
      memory: 4Gi->18
      #when you use autoscalingPolicy, it is recommended that replicas removed from manifests.
    autoScalingPolicy:
      maxReplicas: 10->3
      minReplicas: 1
EOF
#内表tpcds测试
:<<EOF
  starRocksBeSpec:
    storageVolumes:
      - name: be-data
        storageClassName: juicefs-sc
        storageSize: 50Gi
        mountPath: /opt/starrocks/be/storage
    image: harbor.my.org:1080/doris/starrocks-juicefs-be:2.5.2
    replicas: 3
    requests:
      cpu: 2->1
      memory: 8Gi->18
  starRocksCnSpec:
    image: harbor.my.org:1080/doris/starrocks-juicefs-cn:2.5.2
    requests:
      cpu: 2->1
      memory: 4Gi
      #when you use autoscalingPolicy, it is recommended that replicas removed from manifests.
    autoScalingPolicy:
      maxReplicas: 10->3
      minReplicas: 1
EOF


kubectl apply -f ${DORIS_HOME}/${clusterfile}

kubectl get all -n doris
watch kubectl get all -n doris

kubectl delete -f ${DORIS_HOME}/${clusterfile} --force --grace-period=0
kubectl get pod -n doris |grep -v Running |awk '{print $1}'| xargs kubectl delete pod "$1" -n doris --force --grace-period=0
kubectl get pvc -n doris | grep starrockscluster | awk '{print $1}' | xargs kubectl delete pvc -n doris
kubectl get pod -n kube-system | grep juicefs | grep pvc | grep Terminating | awk '{print $1}' | xargs kubectl delete pod -n kube-system --force --grace-period=0
kubectl get pod -n kube-system | grep juicefs | grep pvc | grep Terminating | awk '{print $1}' | xargs kubectl patch pod $1 -n kube-system -p '{"metadata":{"finalizers":null}}'

cp ${clusterfile} ${clusterfile}.bk
$SED -i 's/starrocks-/starrocks-juicefs-/g' ${DORIS_HOME}/${clusterfile}


kubectl logs -f -n doris `kubectl get pod -n doris | grep controller | awk '{print $1}'`


kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep cn-0 | awk '{print $1}'` -- \
bash
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep cn-0 | awk '{print $1}'` -- \
cat /opt/starrocks/cn/log/cn.out
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep cn-0 | awk '{print $1}'` -- \
cat /opt/starrocks/cn/log/cn.WARNING
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep cn-0 | awk '{print $1}'` -- \
cat /opt/starrocks/cn/log/cn.INFO

# starrocks end--------------------------------------------

#svc=fe
svc=starrockscluster-fe-service

kubectl run mysql-client -n doris --rm --tty -i --restart='Never' --image docker.io/library/mysql:5.7 --command -- \
  mysql --default-character-set=utf8 -h ${svc} -P 9030 -u'root' -e"SHOW PROC '/frontends'"

kubectl run mysql-client -n doris --rm --tty -i --restart='Never' --image docker.io/library/mysql:5.7 --command -- \
  mysql --default-character-set=utf8 -h ${svc} -P 9030 -u'root' -e"SHOW PROC '/backends'"

#doris
kubectl run mysql-client -n doris --rm --tty -i --restart='Never' --image docker.io/library/mysql:5.7 --command -- \
  mysql --default-character-set=utf8 -h ${svc} -P 9030 -u'root' -e"SHOW PROC '/brokers'"
#starrocks
kubectl run mysql-client -n doris --rm --tty -i --restart='Never' --image docker.io/library/mysql:5.7 --command -- \
  mysql --default-character-set=utf8 -h ${svc} -P 9030 -u'root' -e"SHOW PROC '/compute_nodes'"

#app=apache-doris
app=starrocks
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep fe-0 | awk '{print $1}'` -- \
bash
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep fe-0 | awk '{print $1}'` -- \
cat /opt/${app}/fe/log/fe.out
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep fe-0 | awk '{print $1}'` -- \
cat /opt/${app}/fe/log/fe.log
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep fe-0 | awk '{print $1}'` -- \
cat /opt/${app}/fe/log/fe.log | grep 'master client, get client from cache failed.host'
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep fe-0 | awk '{print $1}'` -- \
cat /opt/${app}/fe/log/fe.log | grep 'failed'
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep fe-2 | awk '{print $1}'` -- \
cat /opt/${app}/fe/log/fe.warn.log
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep fe-0 | awk '{print $1}'` -- \
ls /opt/${app}/fe/log/
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep fe-0 | awk '{print $1}'` -- \
cat /opt/${app}/fe/log/fe.gc.log.20230209-020244
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep fe-1 | awk '{print $1}'` -- \
cat /opt/${app}/fe/conf/fe.conf

kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep be-0 | awk '{print $1}'` -- \
bash
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep be-0 | awk '{print $1}'` -- \
ls /opt/${app}/be/log/be.out
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep be-0 | awk '{print $1}'` -- \
cat /opt/${app}/be/log/be.out
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep be-0 | awk '{print $1}'` -- \
cat /opt/${app}/be/log/be.WARNING
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep be-0 | awk '{print $1}'` -- \
cat /opt/${app}/be/log/be.INFO
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep be-0 | awk '{print $1}'` -- \
cat /opt/${app}/be/log/be.INFO | grep 'waiting to receive first heartbeat from frontend'
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep dorisbe-0 | awk '{print $1}'` -- \
cat /opt/${app}/be/log/be.INFO | grep 'waiting'
:<<EOF
doris重新安装，没有删除hostpath，会有如下报错，重启也发生类似报错
0
W0207 08:26:51.680299  1104 heartbeat_server.cpp:97] invalid cluster id: 1150857714. ignore.
1
W0207 08:26:01.544231  1101 heartbeat_server.cpp:97] invalid cluster id: 1150857714. ignore.
W0207 08:26:02.154709  1099 heartbeat_server.cpp:97] invalid cluster id: 1126033748. ignore.
2
W0207 08:27:29.726495  1102 heartbeat_server.cpp:97] invalid cluster id: 829007597. ignore.
W0207 08:27:31.780303  1105 heartbeat_server.cpp:97] invalid cluster id: 1150857714. ignore.
EOF
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep be-0 | awk '{print $1}'` -- \
cat /opt/${app}/be/conf/be.conf