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

WORK_HOME=${MYHOME}/workspace
PRJ_HOME=${WORK_HOME}/dockerfile

PRJ_FLINK_HOME=${PRJ_HOME}/flink
PRJ_SPARK_HOME=${PRJ_HOME}/spark

PRJ_HUDI_HOME=${PRJ_HOME}/hudi

FLINK_VERSION=1.15.4
FLINK_SHORT_VERSION=1.15

SPARK_VERSION=3.3.1
SPARK_SHORT_VERSION=3.3

#HADOOP_VERSION=3.3.1
#HADOOP_VERSION=3.1.1
HADOOP_VERSION=3.3.4
HIVEREV=3.1.2

SCALA_VERSION=2.12

HUDI_VERSION=0.12.2
#1.16.1 only support hudi 0.13.0
#HUDI_VERSION=0.13.0

cd ${PRJ_HUDI_HOME}/

#hudi integration
wget -c https://github.com/apache/hudi/archive/refs/tags/release-${HUDI_VERSION}.tar.gz
cd ~
tar xzvf ${PRJ_HUDI_HOME}/hudi-release-${HUDI_VERSION}.tar.gz
cd hudi-release-${HUDI_VERSION}
#0.12.2以下版本
#修改hadoop3兼容问题
file=hudi-common/src/main/java/org/apache/hudi/common/table/log/block/HoodieParquetDataBlock.java
$SED -i 's@try (FSDataOutputStream outputStream = new FSDataOutputStream(baos))@try (FSDataOutputStream outputStream = new FSDataOutputStream(baos, null))@g' ${file}
#编译中镜像缺乏的jar包
mvn install:install-file -DgroupId=io.confluent -DartifactId=kafka-avro-serializer -Dversion=5.3.4 -Dpackaging=jar -Dfile=kafka-avro-serializer-5.3.4.jar
mvn install:install-file -DgroupId=io.confluent -DartifactId=common-config -Dversion=5.3.4 -Dpackaging=jar -Dfile=common-config-5.3.4.jar
mvn install:install-file -DgroupId=io.confluent -DartifactId=common-utils -Dversion=5.3.4 -Dpackaging=jar -Dfile=common-utils-5.3.4.jar
mvn install:install-file -DgroupId=io.confluent -DartifactId=kafka-schema-registry-client -Dversion=5.3.4 -Dpackaging=jar -Dfile=kafka-schema-registry-client-5.3.4.jar


#jdk11
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-11.0.17.jdk/Contents/Home
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin:3.8.0:compile (default-compile) on project hudi-common: Compilation failure: Compilation failure: 
[ERROR] /Users/apple/hudi-release-0.12.2-hadoop3hive3/hudi-common/src/main/java/org/apache/hudi/metadata/HoodieTableMetadataUtil.java:[201,9] 对于collect(java.util.stream.Collector<org.apache.hudi.common.model.HoodieColumnRangeMetadata<java.lang.Comparable>,capture#1, 共 ?,java.util.Map<java.lang.String,org.apache.hudi.common.model.HoodieColumnRangeMetadata<java.lang.Comparable>>>), 找不到合适的方法
[ERROR]     方法 java.util.stream.Stream.<R>collect(java.util.function.Supplier<R>,java.util.function.BiConsumer<R,? super org.apache.hudi.common.model.HoodieColumnRangeMetadata>,java.util.function.BiConsumer<R,R>)不适用
[ERROR]       (无法推断类型变量 R
[ERROR]         (实际参数列表和形式参数列表长度不同))
[ERROR]     方法 java.util.stream.Stream.<R,A>collect(java.util.stream.Collector<? super org.apache.hudi.common.model.HoodieColumnRangeMetadata,A,R>)不适用
[ERROR]       (无法推断类型变量 R,A
[ERROR]         (参数不匹配; java.util.stream.Collector<org.apache.hudi.common.model.HoodieColumnRangeMetadata<java.lang.Comparable>,capture#1, 共 ?,java.util.Map<java.lang.String,org.apache.hudi.common.model.HoodieColumnRangeMetadata<java.lang.Comparable>>>无法转换为java.util.stream.Collector<? super org.apache.hudi.common.model.HoodieColumnRangeMetadata,A,R>))
[ERROR] /Users/apple/hudi-release-0.12.2-hadoop3hive3/hudi-common/src/main/java/org/apache/hudi/common/util/ParquetUtils.java:[332,11] 对于collect(java.util.stream.Collector<org.apache.hudi.common.model.HoodieColumnRangeMetadata<java.lang.Comparable>,capture#2, 共 ?,java.util.Map<java.lang.String,java.util.List<org.apache.hudi.common.model.HoodieColumnRangeMetadata<java.lang.Comparable>>>>), 找不到合适的方法
[ERROR]     方法 java.util.stream.Stream.<R>collect(java.util.function.Supplier<R>,java.util.function.BiConsumer<R,? super org.apache.hudi.common.model.HoodieColumnRangeMetadata>,java.util.function.BiConsumer<R,R>)不适用
[ERROR]       (无法推断类型变量 R
[ERROR]         (实际参数列表和形式参数列表长度不同))
[ERROR]     方法 java.util.stream.Stream.<R,A>collect(java.util.stream.Collector<? super org.apache.hudi.common.model.HoodieColumnRangeMetadata,A,R>)不适用
[ERROR]       (无法推断类型变量 R,A
[ERROR]         (参数不匹配; java.util.stream.Collector<org.apache.hudi.common.model.HoodieColumnRangeMetadata<java.lang.Comparable>,capture#2, 共 ?,java.util.Map<java.lang.String,java.util.List<org.apache.hudi.common.model.HoodieColumnRangeMetadata<java.lang.Comparable>>>>无法转换为java.util.stream.Collector<? super org.apache.hudi.common.model.HoodieColumnRangeMetadata,A,R>))


#编译flink, hadoop3/hive3
cd packaging/hudi-flink-bundle
cp pom.xml pom.xml.bk
:<<EOF
flink sql里创建hudi catalog报错
Caused by: java.lang.NoSuchMethodError: org.apache.parquet.schema.Types$PrimitiveBuilder.as(Lorg/apache/parquet/schema/LogicalTypeAnnotation;)Lorg/apache/parquet/schema/Types$Builder;
参考这篇文章https://blog.csdn.net/m0_66705151/article/details/125781898
是org.apache.hudi.io.storage.row.parquet.ParquetSchemaConverter.convertToParquetType在org.apache.hudi:hudi-flink1.15-bundle_2.12和parquet-hadoop-bundle冲突了
+--- org.apache.hive:hive-metastore:3.0.0
|    +--- org.apache.hive:hive-serde:3.0.0
|    |    +--- org.apache.hive:hive-common:3.0.0 (*)
|    |    +--- org.apache.hive:hive-service-rpc:3.0.0
|    |    +--- org.apache.parquet:parquet-hadoop-bundle:1.9.0
增加排除项
    <dependency>
      <groupId>${hive.groupid}</groupId>
      <artifactId>hive-metastore</artifactId>
      <version>${hive.version}</version>
      <scope>${flink.bundle.hive.scope}</scope>
      <exclusions>

        <exclusion>
          <artifactId>org.apache.parquet</artifactId>
          <groupId>parquet-hadoop-bundle</groupId>
        </exclusion>
    </dependency>

EOF
#for spark和flink的hudi分开编译，对avro的依赖版本不同，会导致建flink 建hudi catalog报错
mvn clean package -DskipTests -Dflink1.15 -Dscala-2.12 -Dhadoop.version=3.3.4 -Dhive.version=3.1.2 -Dflink1.15.version=1.15.4 -Pflink-bundle-shade-hive3
mv packaging packaging.${JDK}
#default hadoop2/hive2
mvn clean package -DskipTests -Dspark3.3 -Dflink1.15 -Dscala-2.12 -Dflink1.15.version=1.15.4
TARGET_BUILT=hadoop3hive3
HIVEREV=3.1.2
#TARGET_BUILT=hadoop2hive2
#HIVEREV=2.3.6
cp packaging/hudi-flink-bundle/target/hudi-flink${FLINK_SHORT_VERSION}-bundle-${HUDI_VERSION}.jar ${PRJ_FLINK_HOME}/hudibk/${TARGET_BUILT}/
cp packaging/hudi-hive-sync-bundle/target/hudi-hive-sync-bundle-${HUDI_VERSION}.jar ${PRJ_FLINK_HOME}/hudibk/${TARGET_BUILT}/
cd ..
mv hudi-release-${HUDI_VERSION} ${PRJ_HUDI_HOME}/hudi-release-${HUDI_VERSION}-${TARGET_BUILT}


#编译spark, hadoop3/hive3
mvn clean package -DskipTests -Dspark3.3 -Dscala-2.12 -Dhadoop.version=3.3.4 -Dhive.version=3.1.2
TARGET_BUILT=hadoop3hive3
HIVEREV=3.1.2
#TARGET_BUILT=hadoop2hive2
#HIVEREV=2.3.6
cp packaging/hudi-spark-bundle/target/hudi-spark${SPARK_SHORT_VERSION}-bundle_${SCALA_VERSION}-${HUDI_VERSION}.jar ${PRJ_SPARK_HOME}/hudibk/${TARGET_BUILT}/
cd ..
mv hudi-release-${HUDI_VERSION} ${PRJ_HUDI_HOME}/hudi-release-${HUDI_VERSION}-${TARGET_BUILT}
#postgresql的hudicdc文件avro log读取有问题，重新用flink的命令构建，删除可能冲突的部分文件相关版本
#从
   <profile>
      <id>spark3.3</id>
      <properties>
        <spark3.version>${spark33.version}</spark3.version>
        <spark.version>${spark3.version}</spark.version>
        <sparkbundle.version>3.3</sparkbundle.version>
        <scala.version>${scala12.version}</scala.version>
        <scala.binary.version>2.12</scala.binary.version>
        <hudi.spark.module>hudi-spark3.3.x</hudi.spark.module>
        <!-- This glob has to include hudi-spark3-common, hudi-spark3.2plus-common -->
        <hudi.spark.common.modules.1>hudi-spark3-common</hudi.spark.common.modules.1>
        <hudi.spark.common.modules.2>hudi-spark3.2plus-common</hudi.spark.common.modules.2>
        <scalatest.version>${scalatest.spark3.version}</scalatest.version>
        <kafka.version>${kafka.spark3.version}</kafka.version>
        <parquet.version>1.12.2</parquet.version>
        <avro.version>1.11.1</avro.version>
        <orc.version>1.7.4</orc.version>
        <antlr.version>4.8</antlr.version>
        <fasterxml.spark3.version>2.13.3</fasterxml.spark3.version>
        <fasterxml.version>${fasterxml.spark3.version}</fasterxml.version>
        <fasterxml.jackson.databind.version>${fasterxml.spark3.version}</fasterxml.jackson.databind.version>
        <fasterxml.jackson.module.scala.version>${fasterxml.spark3.version}</fasterxml.jackson.module.scala.version>
        <fasterxml.jackson.dataformat.yaml.version>${fasterxml.spark3.version}</fasterxml.jackson.dataformat.yaml.version>
        <pulsar.spark.version>${pulsar.spark.scala12.version}</pulsar.spark.version>
        <skip.hudi-spark2.unit.tests>true</skip.hudi-spark2.unit.tests>
        <skipITs>true</skipITs>
      </properties>
      <modules>
        <module>hudi-spark-datasource/hudi-spark3.3.x</module>
        <module>hudi-spark-datasource/hudi-spark3-common</module>
        <module>hudi-spark-datasource/hudi-spark3.2plus-common</module>
      </modules>
      <activation>
        <property>
          <name>spark3.3</name>
        </property>
      </activation>
    </profile>
#改为
   <profile>
      <id>spark3.3</id>
      <properties>
        <spark3.version>${spark33.version}</spark3.version>
        <spark.version>${spark3.version}</spark.version>
        <sparkbundle.version>3.3</sparkbundle.version>
        <hudi.spark.module>hudi-spark3.3.x</hudi.spark.module>
        <!-- This glob has to include hudi-spark3-common, hudi-spark3.2plus-common -->
        <hudi.spark.common.modules.1>hudi-spark3-common</hudi.spark.common.modules.1>
        <hudi.spark.common.modules.2>hudi-spark3.2plus-common</hudi.spark.common.modules.2>
        <scalatest.version>${scalatest.spark3.version}</scalatest.version>
        <kafka.version>${kafka.spark3.version}</kafka.version>
        <parquet.version>1.12.2</parquet.version>
        <avro.version>1.11.1</avro.version>
        <orc.version>1.7.4</orc.version>
        <antlr.version>4.8</antlr.version>
        <fasterxml.spark3.version>2.13.3</fasterxml.spark3.version>
        <fasterxml.version>${fasterxml.spark3.version}</fasterxml.version>
        <fasterxml.jackson.databind.version>${fasterxml.spark3.version}</fasterxml.jackson.databind.version>
        <fasterxml.jackson.module.scala.version>${fasterxml.spark3.version}</fasterxml.jackson.module.scala.version>
        <fasterxml.jackson.dataformat.yaml.version>${fasterxml.spark3.version}</fasterxml.jackson.dataformat.yaml.version>
        <pulsar.spark.version>${pulsar.spark.scala12.version}</pulsar.spark.version>
        <skip.hudi-spark2.unit.tests>true</skip.hudi-spark2.unit.tests>
        <skipITs>true</skipITs>
      </properties>
      <modules>
        <module>hudi-spark-datasource/hudi-spark3.3.x</module>
        <module>hudi-spark-datasource/hudi-spark3-common</module>
        <module>hudi-spark-datasource/hudi-spark3.2plus-common</module>
      </modules>
      <activation>
        <property>
          <name>spark3.3</name>
        </property>
      </activation>
    </profile>


#编译starrocks，hadoop3/hive3，因为hudi MOR表是flink写入的，暂时没有spark写入的COW表
mvn clean package -DskipTests -Dflink1.15 -Dscala-2.12 -Dhadoop.version=3.3.4 -Dhive.version=3.1.2 -Dflink1.15.version=1.15.4 -Pflink-bundle-shade-hive3
