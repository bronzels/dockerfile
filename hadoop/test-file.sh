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

cd ${MYHOME}/workspace/dockerfile/hadoop

#juicefs
distfs=juicefs
#cubefs
distfs=cubefs

cd helm-hadoop-3-templates-distfs/

cp -r ../../image/iotest ./files/
cp -r ../../image/fuse-2.9.2.tar.gz ./files/

docker build ./ --progress=plain --build-arg distfs="${distfs}" -f Dockerfile-distfs-test -t harbor.my.org:1080/chenseanxy/hadoop-ubussh-${distfs}-distfs-test:3.2.1-nolib
docker push harbor.my.org:1080/chenseanxy/hadoop-ubussh-${distfs}-distfs-test:3.2.1-nolib

file=distfs-test.yaml
cp ${file}.template ${file}
$SED -i "s@harbor.my.org:1080/chenseanxy/hadoop-ubussh-distfs-test@harbor.my.org:1080/chenseanxy/hadoop-ubussh-${distfs}-distfs-test@g" ${file}

kubectl apply -f $file
kubectl delete -f $file
kubectl exec -it distfs-test -- /bin/bash
  #加载fuse
  su
    modprobe fuse
    ls /dev/fuse

  #juicefs
  mntpath=/app/hdfs/hadoop/distfsmnt
  mkdir $mntpath
  juicefs mount "redis://:redis@my-redis-master.redis.svc.cluster.local:6379/2" distfsmnt > distfsmnt.log 2>&1 &
  #cubefs
  mntpath=/cfs/mnt
  mkdir $mntpath
  /cfs/bin/start.sh > distfsmnt.log 2>&1 &

  dd if=/dev/zero of=${mntpath}/test-dd-w.dbf status=progress bs=2M count=1000 oflag=direct
  dd if=${mntpath}/test-dd-w.dbf of=/dev/null status=progress bs=2M
  dd if=${mntpath}/test-dd-w.dbf of=${mntpath}/test-dd-rw.dbf status=progress bs=4k
  echo "----------------------------------------------------------------------------------------------------------------------------------------"

  TARGET_PATH="${mntpath}/test-mdtest"
  FILE_SIZE=1024
  mdtest -n 1000 -w $i -e $FILE_SIZE -y -u -i 3 -N 1 -F -R -d $TARGET_PATH
  echo "----------------------------------------------------------------------------------------------------------------------------------------"

  path=${mntpath}
  for ioengine in {psync,libaio}
  do
    echo "ioengine:${ioengine}"
    for iotest in {read,randread,write,randwrite}
    do
      echo "iotest:${iotest}"
      for numjobs in {1,4}
      do
        echo "numjobs:${numjobs}"
        fio -directory=${path} \
            -ioengine=${ioengine} \
            -rw=${iotest} \
            -bs=4k \
            -direct=1 \
            -group_reporting=1 \
            -fallocate=none \
            -time_based=1 \
            -runtime=120 \
            -name=test_file_c \
            -numjobs=${numjobs} \
            -nrfiles=1 \
            -size=10G
        echo "----------------------------------------------------------------------------------------------------------------------------------------"
      done
    done
  done

