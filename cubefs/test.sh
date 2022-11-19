#use kubectl cp/exec to test all steps in ../image/Dockerfile-distfstest-cubefs
kubectl cp ../image/Centos-7.repo client-54fff98-cw2mv:/etc/yum.repos.d/CentOS-Base.repo -n chubaofs  -c client-pod
kubectl cp ../image/epel-7.repo client-54fff98-cw2mv:/etc/yum.repos.d/epel-7.repo -n chubaofs  -c client-pod
kubectl cp ../image/test-tool/mdtest-master.zip client-54fff98-cw2mv:/ -n chubaofs  -c client-pod
kubectl cp ../image/test-tool/fio-fio-3.32.zip client-54fff98-cw2mv:/ -n chubaofs  -c client-pod
kubectl cp ../image/test-tool/mpich-3.2.tar.gz client-54fff98-cw2mv:/ -n chubaofs  -c client-pod
kubectl exec -it -n chubaofs client-54fff98-cw2mv -c client-pod -- /bin/bash

#in ../image
nohup docker build ./ --progress=plain -f Dockerfile-distfstest-cubefs -t harbor.my.org:1080/test/distfstest-cubefs > build-Dockerfile-distfstest-cubefs.log 2>&1 &
tail -f build-Dockerfile-distfstest-cubefs.log
docker push harbor.my.org:1080/test/distfstest-cubefs

nohup docker build ./ --progress=plain -f Dockerfile-distfstest-ubuntu20 -t harbor.my.org:1080/test/distfstest-ubuntu20 > build-Dockerfile-distfstest-ubuntu20.log 2>&1 &
tail -f build-Dockerfile-distfstest-ubuntu20.log
docker push harbor.my.org:1080/test/distfstest-ubuntu20

docker run --privileged --name distfstest-ubuntu20 -itd harbor.my.org:1080/test/distfstest-ubuntu20 tail -f /dev/null

#!/bin/bash
set -e
TARGET_PATH="/cfs/mnt" # mount point of CubeFS volume
for FILE_SIZE in 1024 2048 4096 8192 16384 32768 65536 131072 # file size
do
#mpirun --allow-run-as-root -np 512 --hostfile hfile64 mdtest -n 1000 -w $i -e $FILE_SIZE -y -u -i 3 -N 1 -F -R -d $TARGET_PATH;
mpirun -np 512 --hostfile hfile64 mdtest -n 1000 -w $i -e $FILE_SIZE -y -u -i 3 -N 1 -F -R -d $TARGET_PATH;
done

#srvk8s-clik8s
fio -directory=/cfs/mnt \
    -ioengine=psync \
    -rw=randread \
    -bs=4k \
    -direct=1 \
    -group_reporting=1 \
    -fallocate=none \
    -time_based=1 \
    -runtime=120 \
    -name=test_file_c \
    -numjobs=1 \
    -nrfiles=1 \
    -size=10G
fio -directory=/cfs/mnt \
    -ioengine=psync \
    -rw=randread \
    -bs=4k \
    -direct=1 \
    -group_reporting=1 \
    -fallocate=none \
    -time_based=1 \
    -runtime=120 \dd if=/cfs/mnt/test-dd-w.dbf of=/dev/null status=progress bs=2M
    -name=test_file_c \
    -numjobs=4 \
    -nrfiles=1 \
    -size=10G
dd if=/dev/zero of=/cfs/mnt/test-dd-w.dbf status=progress bs=2M count=1000 oflag=direct
dd if=/cfs/mnt/test-dd-w.dbf of=/dev/null status=progress bs=2M
dd if=/cfs/mnt/test-dd-w.dbf of=/cfs/mnt/test-dd-rw.dbf status=progress bs=4k
TARGET_PATH="/cfs/mnt/test-mdtest"
FILE_SIZE=1024
mdtest -n 1000 -w $i -e $FILE_SIZE -y -u -i 3 -N 1 -F -R -d $TARGET_PATH
fio -directory=/cfs/mnt \
    -ioengine=psync \
    -rw=read \
    -bs=4k \
    -direct=1 \
    -group_reporting=1 \
    -fallocate=none \
    -time_based=1 \
    -runtime=120 \
    -name=test_file_c \
    -numjobs=1 \
    -nrfiles=1 \
    -size=10G
fio -directory=/cfs/mnt \
    -ioengine=psync \
    -rw=write \
    -bs=4k \
    -direct=1 \
    -group_reporting=1 \
    -fallocate=none \
    -time_based=1 \
    -runtime=120 \
    -name=test_file_c \
    -numjobs=4 \
    -nrfiles=1 \
    -size=10G
fio -directory=/cfs/mnt \
    -ioengine=psync \
    -rw=randwrite \
    -bs=4k \
    -direct=1 \
    -group_reporting=1 \
    -fallocate=none \
    -time_based=1 \
    -runtime=120 \
    -name=test_file_c \
    -numjobs=4 \
    -nrfiles=1 \
    -size=10G
fio -directory=/cfs/mnt \
    -ioengine=libaio \
    -rw=write \
    -bs=5M \
    -direct=0 \
    -fallocate=none \
    -name=test_file_c \
    -numjobs=1 \
    -size=10G

#srvk8s-clik8s-4c16g
fio -directory=/cfs/mnt \
    -ioengine=psync \
    -rw=randread \
    -bs=4k \
    -direct=1 \
    -group_reporting=1 \
    -fallocate=none \
    -time_based=1 \
    -runtime=120 \
    -name=test_file_c \
    -numjobs=1 \
    -nrfiles=1 \
    -size=10G
fio -directory=/cfs/mnt \
    -ioengine=psync \
    -rw=randread \
    -bs=4k \
    -direct=1 \
    -group_reporting=1 \
    -fallocate=none \
    -time_based=1 \
    -runtime=120 \
    -name=test_file_c \
    -numjobs=4 \
    -nrfiles=1 \
    -size=10G
dd if=/dev/zero of=/cfs/mnt/test-dd-w.dbf status=progress bs=2M count=1000 oflag=direct
dd if=/cfs/mnt/test-dd-w.dbf of=/dev/null status=progress bs=4k
dd if=/cfs/mnt/test-dd-w.dbf of=/cfs/mnt/test-dd-rw.dbf status=progress bs=4k

#srvk8s-clik8s
fio -directory=/cfs/mnt \
    -ioengine=psync \
    -rw=randread \
    -bs=4k \
    -direct=1 \
    -group_reporting=1 \
    -fallocate=none \
    -time_based=1 \
    -runtime=120 \
    -name=test_file_c \
    -numjobs=1 \
    -nrfiles=1 \
    -size=10G
fio -directory=/cfs/mnt \
    -ioengine=psync \
    -rw=randread \
    -bs=4k \
    -direct=1 \
    -group_reporting=1 \
    -fallocate=none \
    -time_based=1 \
    -runtime=120 \
    -name=test_file_c \
    -numjobs=4 \
    -nrfiles=1 \
    -size=10G
dd if=/dev/zero of=/cfs/mnt/test-dd-w.dbf status=progress bs=2M count=1000 oflag=direct
dd if=/cfs/mnt/test-dd-w.dbf of=/dev/null status=progress bs=4k
dd if=/cfs/mnt/test-dd-w.dbf of=/cfs/mnt/test-dd-rw.dbf status=progress bs=4k
TARGET_PATH="/cfs/mnt/test-mdtest"
FILE_SIZE=1024
mdtest -n 1000 -w $i -e $FILE_SIZE -y -u -i 3 -N 1 -F -R -d $TARGET_PATH
fio -directory=/cfs/mnt \
    -ioengine=psync \
    -rw=read \
    -bs=4k \
    -direct=1 \
    -group_reporting=1 \
    -fallocate=none \
    -time_based=1 \
    -runtime=120 \
    -name=test_file_c \
    -numjobs=1 \
    -nrfiles=1 \
    -size=10G
fio -directory=/cfs/mnt \
    -ioengine=psync \
    -rw=write \
    -bs=4k \
    -direct=1 \
    -group_reporting=1 \
    -fallocate=none \
    -time_based=1 \
    -runtime=120 \
    -name=test_file_c \
    -numjobs=4 \
    -nrfiles=1 \
    -size=10G
fio -directory=/cfs/mnt \
    -ioengine=psync \
    -rw=randwrite \
    -bs=4k \
    -direct=1 \
    -group_reporting=1 \
    -fallocate=none \
    -time_based=1 \
    -runtime=120 \
    -name=test_file_c \
    -numjobs=4 \
    -nrfiles=1 \
    -size=10G
fio -directory=/cfs/mnt \
    -ioengine=libaio \
    -rw=write \
    -bs=5M \
    -direct=0 \
    -fallocate=none \
    -name=test_file_c \
    -numjobs=1 \
    -size=10G

#srvk8sdouble-clik8s
fio -directory=/cfs/mnt \
    -ioengine=libaio \
    -rw=write \
    -bs=5M \
    -direct=0 \
    -fallocate=none \
    -name=test_file_c \
    -numjobs=1 \
    -size=10G
fio -directory=/cfs/mnt \
    -ioengine=psync \
    -rw=write \
    -bs=4k \
    -direct=1 \
    -group_reporting=1 \
    -fallocate=none \
    -time_based=1 \
    -runtime=120 \
    -name=test_file_c \
    -numjobs=4 \
    -nrfiles=1 \
    -size=10G
dd if=/dev/zero of=/cfs/mnt/test-dd-w.dbf status=progress bs=2M count=1000 oflag=direct
