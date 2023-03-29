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

INT_HOME=${PRJ_HOME}/integration
SEATUNNEL_REV=2.3.0

cd ${INT_HOME}

# chunjun start--------------------------------------------

# chunjun end--------------------------------------------


# seatunnel start--------------------------------------------

wget -c https://www.apache.org/dyn/closer.lua/incubator/seatunnel/${SEATUNNEL_REV}/apache-seatunnel-incubating-${SEATUNNEL_REV}-bin.tar.gz
tar xzvf apache-seatunnel-incubating-${SEATUNNEL_REV}-bin.tar.gz

# seatunnel end--------------------------------------------


# inlong start--------------------------------------------

# inlong end--------------------------------------------


# tis start--------------------------------------------

# tis end--------------------------------------------
