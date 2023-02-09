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

DORIS_HOME=${MYHOME}/workspace/dockerfile/doris
DORIS_REV=1.2.1

cd ${DORIS_HOME}

:<<EOF
cpu如何检测是否支持AVX2
cat /proc/cpuinfo | grep avx2
EOF
ansible all -m shell -a"cat /proc/cpuinfo|grep flags|grep vmx"

wget -c https://www.apache.org/dyn/mirrors/mirrors.cgi?action=download&filename=doris/1.2/1.2.1-rc01/apache-doris-1.2.1-src.tar.xz
wget -c https://www.apache.org/dyn/mirrors/mirrors.cgi?action=download&filename=doris/1.2/1.2.1-rc01/apache-doris-fe-1.2.1-bin-x86_64.tar.xz
wget -c https://www.apache.org/dyn/mirrors/mirrors.cgi?action=download&filename=doris/1.2/1.2.1-rc01/apache-doris-be-1.2.1-bin-x86_64.tar.xz
wget -c https://www.apache.org/dyn/mirrors/mirrors.cgi?action=download&filename=doris/1.2/1.2.1-rc01/apache-doris-dependencies-1.2.1-bin-x86_64.tar.xz

tar xzvf apache-doris-${DORIS_REV}-src.tar.xz

cd apache-doris-${DORIS_REV}-src


cd thirdparty
#checksum问题
file=vars.sh
cp ${file} ${file}.bk
$SED -i 's@BRPC_MD5SUM="556c024d5f770dbd2336ca4541ae8c96"@BRPC_MD5SUM="c3c148e672dc660ad48d8bd973f95dcf"@g' ${file}
$SED -i 's@S2_MD5SUM="d41d8cd98f00b204e9800998ecf8427e"@S2_MD5SUM="293552c7646193b8b4a01556808fe155"@g' ${file}
./download-thirdparty.sh
  #从fmt-7.1.3.tar.gz开始，手工下载mv到src目录
  #brpc的压缩文件和解压目录不一致
  mv src/brpc-1.2.0 /incubator-brpc-1.2.0
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


cd ${DORIS_HOME}
cd apache-doris-${DORIS_REV}-src
cd docker/runtime/

tar xzvf ${DORIS_HOME}/apache-doris-dependencies-1.2.1-bin-x86_64.tar.xz

#arr=(fe be broker)
arr=(fe be)
#arr=(broker)
for prj in ${arr[*]}
do
  cd ${prj}
  file=Dockerfile
  cp ${file} ${file}.bk
  if [[ "${prj}" =~ "be" ]]; then
    $SED -i '/FROM openjdk:8u342-jdk/i\FROM harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss:3.3.1 AS spark' ${file}
    cp ../apache-doris-dependencies-${DORIS_REV}-bin-x86_64/java-udf-jar-with-dependencies.jar resource/
  fi
:<<EOF
  if [[ "${prj}" =~ "broker" ]]; then
    #mv ${DORIS_HOME}/apache-doris-${DORIS_REV}-src/fs_brokers/apache_hdfs_broker/output/apache_hdfs_broker.tar.gz resource/
    echo ""
  else
  fi
EOF
  #mv ${DORIS_HOME}/apache-doris-${prj}-${DORIS_REV}-bin-x86_64.tar.xz resource/
  $SED -i '/FROM openjdk:8u342-jdk/a\ARG DORIS_REV=' ${file}
  $SED -i 's@x.x.x@${DORIS_REV}@g' ${file}
  $SED -i 's@FROM openjdk:8u342-jdk@FROM registry.cn-hangzhou.aliyuncs.com/bronzels/openjdk-8u342-jdk:1.0@g' ${file}
  $SED -i 's@.tar.gz@.tar.xz@g' ${file}
  if [[ "${prj}" =~ "fe" ]]; then
    $SED -i 's@-bin@-bin-x86_64@g' ${file}
  fi
  $SED -i '/ADD resource\/init_be.sh \/opt\/apache-doris\/be\/bin/a\ADD resource\/java-udf-jar-with-dependencies.jar \/opt\/apache-doris\/be\/lib' ${file}
  if [[ "${prj}" =~ "be" ]]; then
cat << EOF >> ${file}
RUN mkdir -p /opt/spark/{conf,jars}
COPY --from=spark /app/hdfs/spark/conf/core-site.xml /opt/spark/conf/
COPY --from=spark /app/hdfs/spark/conf/hdfs-site.xml /opt/spark/conf/
COPY --from=spark /app/hdfs/spark/jars/juicefs-hadoop-1.0.2.jar /opt/spark/conf/jars/
ENV _STARTUP_SH=/opt/apache-doris/fe/bin/start_${prj}.sh
RUN cp \${_STARTUP_SH} \${_STARTUP_SH}.bk
RUN sed -i '/export CLASSPATH=/a\export CLASSPATH="${CLASSPATH}:/opt/spark/jars/*:/opt/spark/conf"' \${_STARTUP_SH}
RUN cat \${_STARTUP_SH}
EOF
  fi
  cd ..
done

#arr=(fe be broker)
#arr=(broker)
arr=(fe be)
arr=(fe)
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

#git clone git@github.com:mfanoffice/dataease-helm.git
git clone git@github.com:mfanoffice/k8s-doris.git k8s-doris-orig
cp -r k8s-doris-orig k8s-doris

ansible all -m shell -a"rm -rf /data0/doris;mkdir -p /data0/doris/fe;mkdir -p /data0/doris/be"

rm -rf pvs
mkdir pvs

for prj in {fe,be}
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

cp fe-service.yaml k8s-doris/
cp be-service.yaml k8s-doris/
cp doris-configmap.yaml k8s-doris/
cp add-bes2fe-job.yaml k8s-doris/

kubectl create ns doris

kubectl label node dtpct component.doris/fe=enabled
kubectl label node mdubu component.doris/fe=enabled
kubectl label node mdlapubu component.doris/fe=enabled

kubectl label node dtpct component.doris/be=enabled
kubectl label node mdubu component.doris/be=enabled
kubectl label node mdlapubu component.doris/be=enabled

kubectl apply -f pvs/
kubectl apply -n doris -f k8s-doris/

watch kubectl get all -n doris
kubectl get all -n doris

kubectl get pvc -n doris
kubectl get pv | grep doris

kubectl delete -n doris -f k8s-doris/
###
kubectl get pod -n doris |grep Terminating |awk '{print $1}'| xargs kubectl delete pod "$1" -n doris --force --grace-period=0
kubectl get pod -n doris |grep CrashLoopBackOff |awk '{print $1}'| xargs kubectl delete pod "$1" -n doris --force --grace-period=0
###
kubectl get pvc -n doris | awk '{print $1}' | xargs kubectl delete pvc -n doris
kubectl delete -f pvs/
ansible all -m shell -a"rm -rf /data0/doris;mkdir -p /data0/doris/fe;mkdir -p /data0/doris/be"

kubectl apply -n doris -f k8s-doris/doris-configmap.yaml
kubectl apply -n doris -f k8s-doris/add-bes2fe-job.yaml

kubectl delete -f k8s-doris/add-bes2fe-job.yaml -n doris
kubectl delete -f k8s-doris/doris-configmap.yaml -n doris
kubectl get pod -n doris |grep Terminating |awk '{print $1}'| xargs kubectl delete pod "$1" -n doris --force --grace-period=0


kubectl describe pod -n doris `kubectl get pod -n doris | grep doris-add-bes2fe | awk '{print $1}'`

kubectl logs -n doris -c wait-bes-ready `kubectl get pod -n doris | grep doris-add-bes2fe | awk '{print $1}'`
kubectl logs -n doris -c wait-fes-ready `kubectl get pod -n doris | grep doris-add-bes2fe | awk '{print $1}'`
kubectl logs -n doris -c add-bes2fe `kubectl get pod -n doris | grep doris-add-bes2fe | awk '{print $1}'`

kubectl describe pod -n doris doris-be-0
kubectl logs -n doris doris-be-0
kubectl describe pod -n doris doris-fe-0
kubectl logs -n doris doris-fe-0

kubectl exec -it -n doris -c wait-bes-ready `kubectl get pod -n doris | grep doris-add-bes2fe | awk '{print $1}'` -- bash
kubectl exec -it -n doris -c wait-fes-ready `kubectl get pod -n doris | grep doris-add-bes2fe | awk '{print $1}'` -- bash
kubectl exec -it -n doris -c add-bes2fe `kubectl get pod -n doris | grep doris-add-bes2fe | awk '{print $1}'` -- bash

kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep doris-be-0 | awk '{print $1}'` -- \
bash
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep doris-be-0 | awk '{print $1}'` -- \
cat /opt/apache-doris/be/log/be.out
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep doris-be-0 | awk '{print $1}'` -- \
cat /opt/apache-doris/be/log/be.WARNING
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep doris-be-0 | awk '{print $1}'` -- \
cat /opt/apache-doris/be/log/be.INFO
:<<EOF
重新安装，没有删除hostpath，会有如下报错
0
W0207 08:26:51.680299  1104 heartbeat_server.cpp:97] invalid cluster id: 1150857714. ignore.
1
W0207 08:26:01.544231  1101 heartbeat_server.cpp:97] invalid cluster id: 1150857714. ignore.
W0207 08:26:02.154709  1099 heartbeat_server.cpp:97] invalid cluster id: 1126033748. ignore.
2
W0207 08:27:29.726495  1102 heartbeat_server.cpp:97] invalid cluster id: 829007597. ignore.
W0207 08:27:31.780303  1105 heartbeat_server.cpp:97] invalid cluster id: 1150857714. ignore.
EOF

kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep doris-fe-0 | awk '{print $1}'` -- \
bash
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep doris-fe-0 | awk '{print $1}'` -- \
cat /opt/apache-doris/fe/log/fe.log
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep doris-fe-0 | awk '{print $1}'` -- \
ls /opt/apache-doris/fe/log/
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep doris-fe-0 | awk '{print $1}'` -- \
cat /opt/apache-doris/fe/log/fe.out
kubectl exec -it -n doris `kubectl get pod -n doris | grep Running | grep doris-fe-0 | awk '{print $1}'` -- \
cat /opt/apache-doris/fe/log/fe.gc.log*


kubectl run mysql-client -n doris --rm --tty -i --restart='Never' --image docker.io/library/mysql:5.7 --command -- bash
  mysql --default-character-set=utf8 -h fe-service -P 9030 -u'root' -e"SHOW PROC '/backends'"
#不知道为什么执行执行不行，必须bash进入交互模式

kubectl port-forward -n doris svc/fe-service 9030:9030 &
kubectl port-forward -n doris svc/fe-service 8030:8030 &

kubectl port-forward -n doris doris-be-0 8040:8040 &
kubectl port-forward -n doris doris-be-1 8041:8040 &
kubectl port-forward -n doris doris-be-2 8042:8040 &

kubectl run mysql-client --rm --tty -i --restart='Never' --image docker.io/library/mysql:5.7 --command -- \
  mysql --default-character-set=utf8 -h fe-service.doris.svc.cluster.local -P 9030 -u'root' \
  -e'SHOW DATABASES'

#默认的用户名和密码是 root/空的
