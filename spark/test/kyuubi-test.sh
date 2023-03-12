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
SPARK_HOME=${PRJ_HOME}/spark

SPARK_VERSION=3.3.1

#KYUUBI_VERSION=1.6.1-incubating
KYUUBI_VERSION=1.7.0
KYUUBI_HOME=${SPARK_HOME}/apache-kyuubi-${KYUUBI_VERSION}-bin

BASE_IMAGE=harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss:${SPARK_VERSION}


cd ${SPARK_HOME}/test

kubectl get pod -n spark-operator |grep Running | grep kyuubi-connection-spark-sql | awk '{print $1}'| xargs kubectl delete pod "$1" -n spark-operator --force --grace-period=0
kubectl get pod -n spark-operator |grep Running | grep exec | awk '{print $1}'| xargs kubectl delete pod "$1" -n spark-operator --force --grace-period=0
kubectl get pod -n spark-operator |grep -v Running | grep kyuubi-connection-spark-sql | awk '{print $1}'| xargs kubectl delete pod "$1" -n spark-operator --force --grace-period=0

kubectl exec -it -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep spark-test | awk '{print $1}'` -- bash
  #beeline -u jdbc:hive2://kyuubi-thrift-binary.spark-operator.svc.cluster.local:10009 -n kyuubi
  beeline -u jdbc:hive2://kyuubisrv-thrift-binary.spark-operator.svc.cluster.local:10009 -n hdfs
  #大概有20s才能连接成功
  #会有1个driver，1个executor pod在Running状态，过几秒以后exec-1会消失，以后如果有查询会从exec-2开始新创建
kubectl get pod -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep kyuubi-connection-spark-sql | awk '{print $1}'` -o yaml
    resources:
      limits:
        memory: 1408Mi
      requests:
        cpu: "1"
        memory: 1408Mi
    SHOW DATABASES;
    USE tpcds_bin_partitioned_orc_10;
    SHOW TABLES;
    SELECT * FROM store_sales LIMIT 5;
kubectl get pod -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep kyuubi | grep 'exec-2 ' | awk '{print $1}'` -o yaml
    resources:
      limits:
        memory: 1408Mi
      requests:
        cpu: "1"
        memory: 1408Mi
:<<EOF
对一个很大的表SELECT * LIMIT 5，启动30多个executor，查询结束后很多还在pending状态
退出beeline时，就能自动删掉exector的pod，driver的pod也变成Completed状态。
EOF
    SELECT COUNT(1) FROM store_sales;
    !quit
    -- 或者ctrl + d退出
:<<EOF
执行了一个对很大的表的SELECT COUNT(1)，启动50多个executor，这个查询做完了，pending状态的executor会消失，只剩下running的，这些exec pod只要beeline不退出，就一直是Running状态。
执行时间1分钟10s。
这样如果是对接1个BI，譬如superset之类的，数据分析人员的查询窗口如果一直开着，是不是exec pod都一直保持在最大资源占用的查询跑起来的数目，就算他啥都不查，这些资源都还是占着。
出现这种情况以后，sharelevel设置为CONNECTION，退出beeline时，driver/executor的pod都还是Running状态。
EOF
    SELECT COUNT(1) FROM call_center;
:<<EOF
执行了一个对很小的表的SELECT COUNT(1)，executor的数目还是1。
退出beeline时，就能自动删掉exector的pod，driver的pod也变成Completed状态。
EOF

  #beeline -n hdfs -u 'jdbc:hive2://kyuubisrv-thrift-binary.spark-operator.svc.cluster.local:10009/tpcds_bin_partitioned_orc_10;spark.kubernetes.scheduler.volcano.podGroupTemplateFile=/opt/spark/work-dir/podgroups/volcano-halfavailable-podgroup-high.yaml;spark.driver.memory=2g;spark.driver.cores=1;spark.executor.memory=4g;spark.executor.cores=1；'
  #beeline -n hdfs -u 'jdbc:hive2://kyuubisrv-thrift-binary.spark-operator.svc.cluster.local:10009/tpcds_bin_partitioned_orc_10;kyuubi.engineEnv.spark.kubernetes.scheduler.volcano.podGroupTemplateFile=/opt/spark/work-dir/podgroups/volcano-halfavailable-podgroup-high.yaml;kyuubi.engineEnv.spark.driver.memory=2g;kyuubi.engineEnv.spark.driver.cores=1;kyuubi.engineEnv.spark.executor.memory=4g;kyuubi.engineEnv.spark.executor.cores=1；'
  #数据库名到第一个配置项中间是;#，漏了#不行
  beeline -n hdfs -u 'jdbc:hive2://kyuubisrv-thrift-binary.spark-operator.svc.cluster.local:10009/tpcds_bin_partitioned_orc_10;#spark.kubernetes.scheduler.volcano.podGroupTemplateFile=/opt/spark/work-dir/podgroups/volcano-halfavailable-podgroup-high.yaml;spark.driver.memory=2g;spark.driver.cores=1;spark.executor.memory=4g;spark.executor.cores=1;'
  #从server的日志检查检查连接设置正确格式化成了spark-submit命令
kubectl logs -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep kyuubisrv | awk '{print $1}'`
spark-submit \
	--class org.apache.kyuubi.engine.spark.SparkSQLEngine \
	--conf spark.hive.server2.thrift.resultset.default.fetch.size=1000 \
	--conf spark.kyuubi.client.ipAddress=100.110.242.100 \
	--conf spark.kyuubi.engine.share.level=CONNECTION \
	--conf spark.kyuubi.engine.submit.time=1678420345460 \
	--conf spark.kyuubi.frontend.protocols=THRIFT_BINARY \
	--conf spark.kyuubi.ha.engine.ref.id=9e43bdd8-5057-4e53-a9ff-769d720fbf99 \
	--conf spark.kyuubi.ha.namespace=/kyuubi_1.7.0_CONNECTION_SPARK_SQL/hdfs/9e43bdd8-5057-4e53-a9ff-769d720fbf99 \
	--conf spark.kyuubi.ha.zookeeper.quorum=zk-zookeeper \
	--conf spark.kyuubi.kubernetes.namespace=spark-operator \
	--conf spark.kyuubi.server.ipAddress=0.0.0.0 \
	--conf spark.kyuubi.session.connection.url=0.0.0.0:10009 \
	--conf spark.kyuubi.session.real.user=hdfs \
	--conf spark.app.name=kyuubi_CONNECTION_SPARK_SQL_hdfs_9e43bdd8-5057-4e53-a9ff-769d720fbf99 \

	--conf spark.driver.cores=1 \
	--conf spark.driver.memory=2g \
	--conf spark.executor.cores=1 \
	--conf spark.executor.memory=4g \

	--conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss:3.3.1 \
	--conf spark.kubernetes.driver.label.kyuubi-unique-tag=9e43bdd8-5057-4e53-a9ff-769d720fbf99 \
	--conf spark.kubernetes.driver.pod.featureSteps=org.apache.spark.deploy.k8s.features.VolcanoFeatureStep \
	--conf spark.kubernetes.executor.pod.featureSteps=org.apache.spark.deploy.k8s.features.VolcanoFeatureStep \
	--conf spark.kubernetes.scheduler.name=volcano \

	--conf spark.kubernetes.scheduler.volcano.podGroupTemplateFile=/opt/spark/work-dir/podgroups/volcano-halfavailable-podgroup-high.yaml \

	--conf spark.submit.deployMode=cluster \
	--conf spark.kubernetes.driverEnv.SPARK_USER_NAME=hdfs \
	--conf spark.executorEnv.SPARK_USER_NAME=hdfs \
	--proxy-user hdfs /opt/kyuubi/externals/engines/spark/kyuubi-spark-sql-engine_2.12-1.7.0.jar
  #driver的日志里有driver/executor设置不生效的warning提示
23/03/10 03:52:44 WARN SparkSessionImpl:  Cannot modify the value of a Spark config: spark.driver.memory. See also 'https://spark.apache.org/docs/latest/sql-migration-guide.html#ddl-statements'
23/03/10 03:52:44 WARN SparkSessionImpl:  Cannot modify the value of a Spark config: spark.driver.cores. See also 'https://spark.apache.org/docs/latest/sql-migration-guide.html#ddl-statements'
23/03/10 03:52:44 WARN SparkSessionImpl:  Cannot modify the value of a Spark config: spark.executor.memory. See also 'https://spark.apache.org/docs/latest/sql-migration-guide.html#ddl-statements'
23/03/10 03:52:44 WARN SparkSessionImpl:  Cannot modify the value of a Spark config: spark.executor.cores. See also 'https://spark.apache.org/docs/latest/sql-migration-guide.html#ddl-statements'
  #从pod的yaml检查driver/executor设置生效了
kubectl get pod -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep kyuubi-connection-spark-sql | awk '{print $1}'` -o yaml
    resources:
      limits:
        memory: 2432Mi
      requests:
        cpu: "1"
        memory: 2432Mi
    SELECT * FROM store_sales LIMIT 5;
kubectl get pod -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep kyuubi | grep 'exec-2 ' | awk '{print $1}'` -o yaml
    resources:
      limits:
        memory: 4505Mi
      requests:
        cpu: "1"
        memory: 4505Mi


cat << EOF > setting.sql
SET spark.kubernetes.scheduler.volcano.podGroupTemplateFile=/opt/spark/work-dir/podgroups/volcano-halfavailable-podgroup-high.yaml;
SET spark.driver.memory=2g;
SET spark.driver.cores=1;
SET spark.executor.memory=4g;
SET spark.executor.cores=1;
EOF
echo "SELECT * FROM store_sales LIMIT 5" > query.sql
beeline -n hdfs -u 'jdbc:hive2://kyuubisrv-thrift-binary.spark-operator.svc.cluster.local:10009/tpcds_bin_partitioned_orc_10' -i setting.sql -f query.sql
  #从server的日志检查检查连接设置格式化成了spark-submit命令，没有包括-i的设置内容
kubectl logs -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep kyuubisrv | awk '{print $1}'`
/opt/spark/bin/spark-submit \
	--class org.apache.kyuubi.engine.spark.SparkSQLEngine \
	--conf spark.hive.server2.thrift.resultset.default.fetch.size=1000 \
	--conf spark.kyuubi.client.ipAddress=100.110.242.100 \
	--conf spark.kyuubi.engine.share.level=CONNECTION \
	--conf spark.kyuubi.engine.submit.time=1678421325605 \
	--conf spark.kyuubi.frontend.protocols=THRIFT_BINARY \
	--conf spark.kyuubi.ha.engine.ref.id=16320969-fa53-40a8-88b7-91b3ae79ea41 \
	--conf spark.kyuubi.ha.namespace=/kyuubi_1.7.0_CONNECTION_SPARK_SQL/hdfs/16320969-fa53-40a8-88b7-91b3ae79ea41 \
	--conf spark.kyuubi.ha.zookeeper.quorum=zk-zookeeper \
	--conf spark.kyuubi.kubernetes.namespace=spark-operator \
	--conf spark.kyuubi.server.ipAddress=0.0.0.0 \
	--conf spark.kyuubi.session.connection.url=0.0.0.0:10009 \
	--conf spark.kyuubi.session.real.user=hdfs \
	--conf spark.app.name=kyuubi_CONNECTION_SPARK_SQL_hdfs_16320969-fa53-40a8-88b7-91b3ae79ea41 \
	--conf spark.kubernetes.container.image=harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss:3.3.1 \
	--conf spark.kubernetes.driver.label.kyuubi-unique-tag=16320969-fa53-40a8-88b7-91b3ae79ea41 \
	--conf spark.kubernetes.driver.pod.featureSteps=org.apache.spark.deploy.k8s.features.VolcanoFeatureStep \
	--conf spark.kubernetes.executor.pod.featureSteps=org.apache.spark.deploy.k8s.features.VolcanoFeatureStep \
	--conf spark.kubernetes.scheduler.name=volcano \
	--conf spark.kubernetes.scheduler.volcano.podGroupTemplateFile=/opt/spark/work-dir/podgroups/volcano-halfavailable-podgroup.yaml \
	--conf spark.submit.deployMode=cluster \
	--conf spark.kubernetes.driverEnv.SPARK_USER_NAME=hdfs \
	--conf spark.executorEnv.SPARK_USER_NAME=hdfs \
	--proxy-user hdfs /opt/kyuubi/externals/engines/spark/kyuubi-spark-sql-engine_2.12-1.7.0.jar
kubectl logs -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep kyuubi-connection-spark-sql | awk '{print $1}'`
  #driver的日志里有driver/executor设置不生效的error提示
23/03/10 04:09:05 ERROR ExecuteStatement: Error operating ExecuteStatement: org.apache.spark.sql.AnalysisException:  Cannot modify the value of a Spark config: spark.driver.memory. See also 'https://spark.apache.org/docs/latest/sql-migration-guide.html#ddl-statements'
  #从pod的yaml检查driver/executor设置没有生效
kubectl get pod -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep kyuubi-connection-spark-sql | awk '{print $1}'` -o yaml
      resources:
        requests:
          cpu: 250m
          memory: 256Mi
kubectl get pod -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep kyuubi | grep 'exec-2 ' | awk '{print $1}'` -o yaml
      resources:
        requests:
          cpu: 250m
          memory: 256Mi


USER=hdfs
cat << EOF > setting.sql
SET ___${USER}___.spark.kubernetes.scheduler.volcano.podGroupTemplateFile=/opt/spark/work-dir/podgroups/volcano-halfavailable-podgroup-high.yaml;
SET ___${USER}___.spark.driver.memory=2g;
SET ___${USER}___.spark.driver.cores=1;
SET ___${USER}___.spark.executor.memory=4g;
SET ___${USER}___.spark.executor.cores=1;
EOF
echo "SELECT * FROM store_sales LIMIT 5" > query.sql
beeline -n ${USER} -u 'jdbc:hive2://kyuubisrv-thrift-binary.spark-operator.svc.cluster.local:10009/tpcds_bin_partitioned_orc_10' -i setting.sql -f query.sql
  #driver的日志里有相关提示，但是似乎没有生效
:<<EOF
23/03/10 04:22:40 INFO ExecuteStatement: Processing hdfs's query[3ee89efd-4b89-4567-9e45-fe27dbb89f72]: PENDING_STATE -> RUNNING_STATE, statement:
SET ___hdfs___.spark.driver.memory=2g
EOF
  #从pod的yaml检查driver/executor设置没有生效
kubectl get pod -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep kyuubi-connection-spark-sql | awk '{print $1}'` -o yaml
      resources:
        requests:
          cpu: 250m
          memory: 256Mi
kubectl get pod -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep kyuubi | grep 'exec-2 ' | awk '{print $1}'` -o yaml
      resources:
        requests:
          cpu: 250m
          memory: 256Mi