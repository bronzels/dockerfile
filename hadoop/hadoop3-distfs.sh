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

HDPHOME=${MYHOME}/workspace/dockerfile/hadoop/helm-hadoop-3


cd $HDPHOME

file=values.yaml
cp ../helm-hadoop-3-templates-distfs/${file}.common ${file}

rm -f templates/hdfs-*.yaml
cp -f ../helm-hadoop-3-templates-distfs/hadoop-configmap.yaml templates/

#juicefs
$SED -i 's@harbor.my.org:1080/chenseanxy/hadoop-ubussh@harbor.my.org:1080/chenseanxy/hadoop-ubussh-juicefs@g' ${file}
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
$SED -i 's@harbor.my.org:1080/chenseanxy/hadoop-ubussh@harbor.my.org:1080/chenseanxy/hadoop-ubussh-cubefs@g' ${file}
cat << \EOF >> templates/hadoop-configmap.yaml
      <property>
        <name>yarn.log.server.url</name>
        <value>cfs://hdfs/jobhistory/logs</value>
      </property>
      <property>
        <name>yarn.nodemanager.remote-app-log-dir</name>
        <value>cfs://hdfs/user/hdfs/yarn-logs</value>
      </property>
    </configuration>
EOF
