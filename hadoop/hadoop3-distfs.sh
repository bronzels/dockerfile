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

file=values.yaml
cp ../helm-hadoop-3-templates-distfs/${file}.common ${file}
#juicefs
$SED -i 's@repository: harbor.my.org:1080/chenseanxy/hadoop-ubussh@repository: harbor.my.org:1080/chenseanxy/hadoop-ubussh-juicefs@g' ${file}
cat << \EOF >> templates/hadoop-configmap.yaml
      <property>
        <name>yarn.log.server.url</name>
        <value>jfs://miniofs/jobhistory/logs</value>
      </property>
      <property>
        <name>yarn.nodemanager.remote-app-log-dir</name>
        <value>jfs://miniofs/user/hdfs/yarn-logs</value>
      </property>
    </configuration>
EOF
#cubefs
$SED -i 's@repository: harbor.my.org:1080/chenseanxy/hadoop-ubussh@repository: harbor.my.org:1080/chenseanxy/hadoop-ubussh-cubefs@g' ${file}
cat << \EOF >> templates/hadoop-configmap.yaml
      <property>
        <name>yarn.log.server.url</name>
        <value>cfs://miniofs/jobhistory/logs</value>
      </property>
      <property>
        <name>yarn.nodemanager.remote-app-log-dir</name>
        <value>cfs://miniofs/user/hdfs/yarn-logs</value>
      </property>
    </configuration>
EOF
