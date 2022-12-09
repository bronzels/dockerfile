if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Mac detected."
    #mac
    HDPHOME=/Volumes/data/workspace/dockerfile/hadoop/helm-hadoop-3
    SED=gsed
else
    echo "Assuming linux by default."
    #linux
    HDPHOME=~/helm-hadoop-3
    SED=sed
fi

cd $HDPHOME

cp -f ../helm-hadoop-3-templates-distfs/hadoop-configmap.yaml templates/
rm -f templates/hdfs-*.yaml

cp ${file}.common ${file}
#juicefs
$SED -i 's@repository: harbor.my.org:1080/chenseanxy/hadoop-ubussh@repository: harbor.my.org:1080/chenseanxy/hadoop-ubussh-juicefs@g' ${file}
#cubefs
$SED -i 's@repository: harbor.my.org:1080/chenseanxy/hadoop-ubussh@repository: harbor.my.org:1080/chenseanxy/hadoop-ubussh-cubefs@g' ${file}
