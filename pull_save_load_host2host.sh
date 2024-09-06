from=$1
to=$2
image=$3
tarfile=`echo "${image}"|gsed 's@/@-@g'|gsed 's@:@-@g'`.tar

sudo ssh $from docker save $image -o /data0/${tarfile}
sudo ssh $from scp /data0/${tarfile} $to:/data0/
sudo ssh $from rm -f /data0/${tarfile}
sudo ssh $to docker load -i /data0/${tarfile}
sudo ssh $to rm -f /data0/${tarfile}
