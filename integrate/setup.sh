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

WORK_HOME=${MYHOME}/workspace
PRJ_HOME=${WORK_HOME}/dockerfile

INT_HOME=${PRJ_HOME}/integrate

#TARGET_BUILT=hadoop2hive2
TARGET_BUILT=hadoop3hive3

FLINK_VERSION=1.16.1
FLINK_SHORT_VERSION=1.16


:<<EOF
FLINK_VERSION=1.17.0
FLINK_SHORT_VERSION=1.17

FLINK_VERSION=1.15.4
FLINK_SHORT_VERSION=1.15

FLINK_VERSION=1.15.4
FLINK_SHORT_VERSION=1.15
EOF

BITSAIL_REV=0.1.0

CHUNJUN_REV=master

SEATUNNEL_REV=2.3.1

export PATH=$PATH:${INT_HOME}

cd ${INT_HOME}


# bitsail start--------------------------------------------
unzip bitsail-master.zip
tar xzvf release-0.1.0.tar.gz
cd bitsail-release-0.1.0/
file=build.sh
cp ${file} ${file}.bk
#$SED -i 's/mvn clean package/mvn clean package -Denforcer.skip=true/g' ${file}
build.sh flink-1.16,flink-1.16-embedded
cp ${INT_HOME}/bitsail-master/bitsail-dist/src/main/resources/Dockerfile ${INT_HOME}/bitsail-release-${BITSAIL_REV}/
file=Dockerfile
cp ${file} ${file}.bk

cp ${INT_HOME}/bitsail-release-${BITSAIL_REV}/${file} ${INT_HOME}/${file}-bitsail

DOCKER_BUILDKIT=1 docker build ./ --progress=plain\
 --build-arg FLINK_VERSION="${FLINK_VERSION}"\
 --build-arg TARGET_BUILT="${TARGET_BUILT}"\
 -t harbor.my.org:1080/integrate/bitsail:${BITSAIL_REV}
docker push harbor.my.org:1080/integrate/bitsail:${BITSAIL_REV}

cp ${INT_HOME}/${file}-bitsail ${INT_HOME}/bitsail-release-${BITSAIL_REV}/${file} 

# bitsail end--------------------------------------------


# chunjun start--------------------------------------------
unzip chunjun-master.zip

# chunjun end--------------------------------------------


# seatunnel start--------------------------------------------
wget -c https://www.apache.org/dyn/closer.lua/incubator/seatunnel/${SEATUNNEL_REV}/apache-seatunnel-incubating-${SEATUNNEL_REV}-bin.tar.gz
tar xzvf apache-seatunnel-incubating-${SEATUNNEL_REV}-bin.tar.gz

# seatunnel end--------------------------------------------


