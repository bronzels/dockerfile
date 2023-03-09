#!/bin/bash

path=$1
echo "DEBUG >>>>>> path:${path}"
prefix=$2
echo "DEBUG >>>>>> prefix:${prefix}"
parallelism=$3
echo "DEBUG >>>>>> parallelism:${parallelism}"
SED=sed
name=${prefix}`echo ${path}|$SED 's/\\//\-/g'|$SED 's/\./\-/g'|$SED '1,/\-/s/\-//'`
echo "DEBUG >>>>>> name:${name}"

#FLINKOP_VERSION=1.4.0
FLINKOP_VERSION=1.3.1

cat << EOF >> ${name}.yaml
apiVersion: flink.apache.org/v1beta1
kind: FlinkDeployment
metadata:
  name: ${name}
spec:
  image: harbor.my.org:1080/flink/flink-kubernetes-operator-juicefs:${FLINKOP_VERSION}
  flinkVersion: v1_15
  flinkConfiguration:
    taskmanager.numberOfTaskSlots: "${parallelism}"
  serviceAccount: flink
  jobManager:
    resource:
      memory: "2048m"
      cpu: 1
  taskManager:
    resource:
      memory: "2048m"
      cpu: 1
  job:
    jarURI: local:///flink-kubernetes-operator/flink-sql-runner-1.3.1.jar
    args: ["jfs://miniofs${path}"]operator
    parallelism: ${parallelism}
    upgradeMode: stateless
EOF

start=$(date +"%s.%9N")
kubectl apply -f ${name}.yaml -n flink
#podname=`kubectl get pod -n flink | grep ${name} | awk '{print $1}'`
status=`kubectl get pod -n flink | grep ${name} | awk '{print $3}'`
#kubectl port-forward -n flink svc/${name}-rest 8081:8081 &
until [[ "${status}" == "Completed" ]]
do
  sleep 1
done
end=$(date +"%s.%9N")
delta=`echo "scale=9;$end - $start" | bc`
echo "DEBUG >>>>>> delta:${delta}"
echo -e "${name},${delta}" > ${name}.delta
