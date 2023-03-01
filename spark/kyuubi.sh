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

KYUUBI_VERSION=1.6.1-incubating
KYUUBI_HOME=${SPARK_HOME}/apache-kyuubi-${KYUUBI_VERSION}-bin

BASE_IMAGE=harbor.my.org:1080/bronzels/spark-juicefs-volcano-rss:${SPARK_VERSION}


cd ${SPARK_HOME}

:<<EOF
wget -c https://github.com/apache/kyuubi/archive/refs/tags/v${KYUUBI_VERSION}.tar.gz
tar xzvf kyuubi-${KYUUBI_VERSION}.tar.gz
cd kyuubi-${KYUUBI_VERSION}/docker/
EOF

wget -c https://archive.apache.org/dist/incubator/kyuubi/kyuubi-1.6.1-incubating/apache-kyuubi-1.6.1-incubating-bin.tgz

tar xzvf apache-kyuubi-${KYUUBI_VERSION}-bin.tgz
cd ${KYUUBI_HOME}/docker/
file=Dockerfile
cp ${file} ${file}.bk
$SED -i 's/spark-binary/\/app\/hdfs\/spark/g' ${file}
#$SED -i '/    rm -rf \/var\/cache\/apt/i\    mkdir ${KYUUBI_WORK_DIR_ROOT}/kyuubi && chmod a+rwx -R ${KYUUBI_WORK_DIR_ROOT}/kyuubi && \\' ${file}
#$SED -i '/    rm -rf \/var\/cache\/apt/i\    mkdir ${KYUUBI_WORK_DIR_ROOT}/hdfs && chown hdfs:hdfs -R ${KYUUBI_WORK_DIR_ROOT}/hdfs && chmod a+rwx -R ${KYUUBI_WORK_DIR_ROOT}/hdfs && \\' ${file}
$SED -i 's/spark-binary/spark/g' ${file}

cd ${KYUUBI_HOME}

kubectl cp -n spark-operator `kubectl get pod -n spark-operator | grep Running | grep spark-test | awk '{print $1}'`:/app/hdfs/spark docker/spark

#DOCKER_BUILDKIT=1 docker build ./ -f docker/Dockerfile --progress=plain --build-arg spark_provided="spark_provided" --build-arg spark_home_in_docker="/app/hdfs/spark" --build-arg BASE_IMAGE="${BASE_IMAGE}" -t harbor.my.org:1080/bronzels/kyuubi-juicefs-volcano-rss:${KYUUBI_VERSION}
DOCKER_BUILDKIT=1 docker build ./ -f docker/Dockerfile --progress=plain -t harbor.my.org:1080/bronzels/kyuubi-juicefs-volcano-rss:${KYUUBI_VERSION}
docker push harbor.my.org:1080/bronzels/kyuubi-juicefs-volcano-rss:${KYUUBI_VERSION}

#docker
ansible all -m shell -a"docker images|grep kyuubi"
ansible all -m shell -a"docker images|grep kyuubi|awk '{print \$3}'|xargs docker rmi -f"
#containerd
ansible all -m shell -a"crictl images|grep kyuubi"
ansible all -m shell -a"crictl images|grep kyuubi|awk '{print \$3}'|xargs crictl rmi"

kubectl create ns kyuubi

cd ${KYUUBI_HOME}/docker/helm

helm install my -n kyuubi -f values.yaml \
  --set image.repository=harbor.my.org:1080/bronzels/kyuubi-juicefs-volcano-rss \
  --set image.tag=${KYUUBI_VERSION} \
  ./
watch kubectl get all -n kyuubi
kubectl get all -n kyuubi

helm uninstall my -n kyuubi
kubectl get pod -n kyuubi |grep -v Running |awk '{print $1}'| xargs kubectl delete pod "$1" -n kyuubi --force --grace-period=0
kubectl get pod -n kyuubi |grep Running |awk '{print $1}'| xargs kubectl delete pod "$1" -n kyuubi --force --grace-period=0

kubectl logs -n kyuubi kyuubi-server-7f865c77c4-8v57n

:<<EOF
NAME: my
LAST DEPLOYED: Mon Feb 27 08:18:12 2023
NAMESPACE: kyuubi
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

Get kyuubi expose URL by running these commands:
  export NODE_PORT=$(kubectl get --namespace kyuubi -o jsonpath="{.spec.ports[0].nodePort}" services my-kyuubi-nodeport)
  export NODE_IP=$(kubectl get nodes --namespace kyuubi -o jsonpath="{.items[0].status.addresses[0].address}")
  echo $NODE_IP:$NODE_PORT
EOF
