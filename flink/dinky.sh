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

WORK_HOME=${MYHOME}/workspace
PRJ_HOME=${WORK_HOME}/dockerfile

PRJ_FLINK_HOME=${PRJ_HOME}/flink
:<<EOF
FLINK_VERSION=1.16.1
FLINK_SHORT_VERSION=1.16
FLINKOP_VERSION=1.4.0
EOF
FLINK_VERSION=1.15.3
FLINK_SHORT_VERSION=1.15
FLINKOP_VERSION=1.3.1

DINKY_VERSION=0.7.2

#wget -c https://github.com/DataLinkDC/dinky/releases/download/v${DINKY_VERSION}/dlink-release-${DINKY_VERSION}.tar.gz
wget -c https://github.com/DataLinkDC/dinky/archive/refs/tags/v${DINKY_VERSION}.tar.gz
tar xzvf dinky-${DINKY_VERSION}.tar.gz
cd dinky-${DINKY_VERSION}
#安装node.js
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-11.0.17.jdk/Contents/Home
npm config set registry https://registry.npm.taobao.org
#mvn spotless:apply
mvn clean install -DskipTests=true -Dmaven.test.skip=true -Pjava11-target -P aliyun,nexus,prod,scala-2.12,web,flink-1.15,flink-1.16 -Dspotless.check.skip=true
