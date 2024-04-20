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
tarfile=`echo "${img}"|gsed 's@/@-@g'|gsed 's@:@-@g'`.tar
echo "tarfile:${tarfile}"

#docker pull $img

docker save ${img} -o ${tarfile}
ansible all -m copy -a"src=${tarfile} dest=/root/"
ansible all -m shell -a"docker load -i /root/${tarfile}"
ansible all -m shell -a"rm -f /root/${tarfile}"
