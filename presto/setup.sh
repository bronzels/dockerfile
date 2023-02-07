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

PRESTO_HOME=${MYHOME}/workspace/dockerfile/presto

cd ${PRESTO_HOME}

TRINO_REV=406

wget -c https://github.com/trinodb/trino/archive/refs/tags/406.zip
gunzip -x trino-${TRINO_REV}.zip

cd trino-${TRINO_REV}

export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home
#./mvnw clean install -DskipTests
mvn clean install -DskipTests -Dmaven.test.skip=true
  mvn install:install-file -DgroupId=io.confluent -DartifactId=kafka-schema-serializer -Dversion=5.5.0 -Dpackaging=jar -Dfile=kafka-json-schema-serializer-5.5.0.jar
  mvn install:install-file -DgroupId=io.confluent -DartifactId=kafka-avro-serializer -Dversion=5.5.2 -Dpackaging=jar -Dfile=kafka-avro-serializer-5.5.2.jar
  #plugin/trino-elasticsearch，删除maven-dependency-plugin使用
