#!/usr/bin/env bash
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


img=$1
echo "img:${img}"
tagged=$2
tarfile=`echo "${tagged}"|gsed 's@/@-@g'|gsed 's@:@-@g'`.tar
echo "tarfile:${tarfile}"

docker pull $img
docker tag $img $tagged

docker save ${tagged} -o ${tarfile}
ansible all -m copy -a"src=${tarfile} dest=/data0/"
ansible all -m shell -a"docker load -i /data0/${tarfile}"
ansible all -m shell -a"rm -f /data0/${tarfile}"
rm -f ${tarfile}
