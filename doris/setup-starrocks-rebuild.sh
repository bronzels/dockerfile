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

PRJ_DORIS_HOME=${PRJ_HOME}/doris
#DORIS_REV=1.2.1
DORIS_REV=1.2.2

STARROCKS_REV=2.5.2
STARROCKS_OP_REV=1.3
#STARROCKS_OP_REV=master

#JUICEFS_VERSION=1.0.2
JUICEFS_VERSION=1.0.3

maven_version=3.8.6

maven_home=${MYHOME}/apache-maven-${maven_version}
m2_home=${MYHOME}/m2
go_path=${MYHOME}/gopath

# ### all in ubuntu start--------------------------------------------
cd ${PRJ_DORIS_HOME}/starrocks-src
cp ${PRJ_HOME}/juicefs/juicefs-hadoop-${JUICEFS_VERSION}-jdk11-ubuntu22.04.jar ./
cp ${PRJ_HOME}/juicefs/core-site.xml ./
cp ${PRJ_HOME}/spark/hdfs-site.xml ./
cp ${PRJ_HOME}/spark/hive-site.xml ./

docker run -itd --name starrocks-dev-ubuntu --restart unless-stopped --oom-kill-disable -v starrocks-2.5.2:/root/starrocks starrocks/dev-ubuntu:main tail -f /dev/null
docker exec -it starrocks-dev-ubuntu bash
  cd starrocks/
  ./build.sh --fe
docker stop starrocks-dev-ubuntu rm docker delete starrocks-dev-ubuntu

mv output ${PRJ_DORIS_HOME}/StarRocks-${STARROCKS_REV}

#be必须在cn的后面
arr=(Dockerfile-fe-ubuntu Dockerfile-cn-ubuntu Dockerfile-be-ubuntu)
for dfile in ${arr[*]}
do
  echo "DEBUG >>>>>> dfile:${dfile}"
  OLD_IFS="$IFS"
  IFS="-"
  arr=($dfile)
  IFS="$OLD_IFS"
  prj=${arr[1]}
  echo "DEBUG >>>>>> prj:${prj}"
  dpath="starrocks-${STARROCKS_REV}/docker/dockerfiles"
  echo "DEBUG >>>>>> dpath:${dpath}"

  if [[ "${prj}" != "cn" ]]; then
    cp ${dpath}/${dfile} ${dpath}/${dfile}.bk
  else
    cp ${dpath}/Dockerfile-be-ubuntu ${dpath}/${dfile}
  fi

  $SED -i "/RUN git clone /a\ARG STARROCKS_REV=?\nCOPY starrocks-\${STARROCKS_REV} starrocks" ${dpath}/${dfile}
  $SED -i '/RUN git clone /d' ${dpath}/${dfile}
  $SED -i 's/        && cd /RUN cd /g' ${dpath}/${dfile}

  if [[ "${prj}" == "be" ]]; then
    $SED -i 's/apt-get install -y --no-install-recommends binutils-dev mysql-client default-jdk/apt-get install -y --no-install-recommends binutils-dev mysql-client default-jdk bc/g' ${dpath}/${dfile}
  fi

  if [[ "${prj}" == "cn" ]]; then
    $SED -i 's/COPY --from=builder \/opt\/starrocks\/be \/opt\/starrocks\/be/COPY --from=builder \/opt\/starrocks\/be \/opt\/starrocks\/cn/g' ${dpath}/${dfile}
    $SED -i "/COPY --from=builder/a\COPY starrocks-\${STARROCKS_REV}\/docker\/bin\/cn_entrypoint.sh starrocks-\${STARROCKS_REV}\/docker\/bin\/cn_prestop.sh \/opt\/starrocks\/\nCOPY starrocks-\${STARROCKS_REV}\/docker/bin/cn_entrypoint.sh starrocks-\${STARROCKS_REV}\/docker\/bin\/cn_prestop.sh \/root\/" ${dpath}/${dfile}
  fi

cat << EOF >> ${dpath}/${dfile}
COPY juicefs-hadoop-1.0.2-jdk11.jar /opt/starrocks/${prj}/lib/
COPY core-site.xml /opt/starrocks/${prj}/conf/
COPY hdfs-site.xml /opt/starrocks/${prj}/conf/
COPY hive-site.xml /opt/starrocks/${prj}/conf/
EOF
done

arr=(Dockerfile-fe-ubuntu Dockerfile-cn-ubuntu Dockerfile-be-ubuntu)
for dfile in ${arr[*]}
do
  echo "DEBUG >>>>>> dfile:${dfile}"
  OLD_IFS="$IFS"
  IFS="-"
  arr=($dfile)
  IFS="$OLD_IFS"
  prj=${arr[1]}
  echo "DEBUG >>>>>> prj:${prj}"
  dpath="docker/dockerfiles"
  echo "DEBUG >>>>>> dpath:${dpath}"

  DOCKER_BUILDKIT=1 docker build ./ -f ${dpath}/${dfile} --progress=plain  --build-arg JUICEFS_VERSION="${JUICEFS_VERSION}" --build-arg STARROCKS_REV="${STARROCKS_REV}" -t harbor.my.org:1080/doris/starrocks-juicefs-${prj}:${STARROCKS_REV}
  docker push harbor.my.org:1080/doris/starrocks-juicefs-${prj}:${STARROCKS_REV}
done
# ### all in ubuntu start--------------------------------------------

rm -rf fe/build_Release/ fe/output/
rm -rf be/build_Release/ be/output/
rm -rf cn/build_Release/ cn/output/


# ### only fe in ubuntu start--------------------------------------------
cd ${PRJ_DORIS_HOME}/starrocks-src
arr=(Dockerfile-fe-ubuntu Dockerfile_be_centos Dockerfile_cn_centos)
for dfile in ${arr[*]}
do
  echo "DEBUG >>>>>> dfile:${dfile}"
  OLD_IFS="$IFS"
  if [[ "${dfile}" == "Dockerfile-fe-ubuntu" ]]; then
    IFS="-"
  else
    IFS="_"
  fi
  arr=($dfile)
  IFS="$OLD_IFS"
  prj=${arr[1]}
  echo "DEBUG >>>>>> prj:${prj}"
  dpath="starrocks-${STARROCKS_REV}/docker/dockerfiles"
  echo "DEBUG >>>>>> dpath:${dpath}"

  if [[ "${prj}" == "be" ]]; then
    $SED -i 's/apt-get install -y --no-install-recommends binutils-dev mysql-client default-jdk/apt-get install -y --no-install-recommends binutils-dev mysql-client default-jdk bc/g' ${dpath}/${dfile}
  fi
  if [[ "${prj}" == "fe" ]]; then
    #cp ${dpath}/${dfile} ${dpath}/${dfile}.bk
    #$SED -i 's/apt-get install -y --no-install-recommends default-jdk curl/apt-get install -y --no-install-recommends default-jdk curl bc/g' ${dpath}/${dfile}
    $SED -i "/RUN git clone /i\COPY .m2 \/root\/.m2" ${dpath}/${dfile}
    #$SED -i "/RUN git clone /i\COPY jackson-mapper-asl-1.9.13-cloudera.2.jar .\/\nRUN mvn install:install-file -DgroupId=org.codehaus.jackson -DartifactId=jackson-mapper-asl -Dversion=1.9.13-cloudera.2 -Dpackaging=jar -Dfile=.\/jackson-mapper-asl-1.9.13-cloudera.2.jar\nCOPY je-7.3.7.jar .\/\nRUN mvn install:install-file -DgroupId=com.sleepycat -DartifactId=je -Dversion=7.3.7 -Dpackaging=jar -Dfile=.\/je-7.3.7.jar" ${dpath}/${dfile}
    $SED -i "/RUN git clone /i\COPY jackson-mapper-asl-1.9.13-cloudera.2.jar .\/\nRUN mvn install:install-file -DgroupId=org.codehaus.jackson -DartifactId=jackson-mapper-asl -Dversion=1.9.13-cloudera.2 -Dpackaging=jar -Dfile=.\/jackson-mapper-asl-1.9.13-cloudera.2.jar" ${dpath}/${dfile}
    $SED -i "/RUN git clone /a\ARG STARROCKS_REV=?\nCOPY starrocks-\${STARROCKS_REV} starrocks" ${dpath}/${dfile}
    $SED -i '/RUN git clone /d' ${dpath}/${dfile}
    $SED -i 's/        && cd /RUN cd /g' ${dpath}/${dfile}
    $SED -i "/COPY --from=builder/a\COPY starrocks-\${STARROCKS_REV}/docker/bin/fe_entrypoint.sh starrocks-\${STARROCKS_REV}/docker/bin/fe_prestop.sh /opt/starrocks/" ${dpath}/${dfile}
    #$SED -i "s@COPY --from=builder /opt/starrocks/fe /opt/starrocks/fe@COPY --from=builder /opt/starrocks /opt/starrocks@g" ${dpath}/${dfile}
    $SED -i "/FROM ubuntu:22.04 as base/a\ARG STARROCKS_REV=?\nARG JUICEFS_VERSION=?" ${dpath}/${dfile}

  fi

cat << EOF >> docker/dockerfiles/${dfile}
COPY core-site.xml /opt/starrocks/${prj}/conf/
COPY hdfs-site.xml /opt/starrocks/${prj}/conf/
COPY hive-site.xml /opt/starrocks/${prj}/conf/
EOF

if [[ "${prj}" == "fe" ]]; then
dockerfile=docker/dockerfiles/${dfile}
cat << EOF >> ${dockerfile}
ARG JUICEFS_VERSION=?
COPY juicefs-hadoop-${JUICEFS_VERSION}-jdk11-ubuntu22.jar /opt/starrocks/${prj}/lib/
EOF
elif [[ "${prj}" == "be" ]]; then
dockerfile=${dpath}/${dfile}
cat << EOF >> ${dockerfile}
ARG JUICEFS_VERSION=?
COPY juicefs-hadoop-${JUICEFS_VERSION}-jdk11-centos7.jar /opt/starrocks/${prj}/lib/
EOF
else #cn
dockerfile=${dpath}/${dfile}
cat << EOF >> ${dockerfile}
ARG JUICEFS_VERSION=?
COPY juicefs-hadoop-${JUICEFS_VERSION}-jdk11-centos7.jar /opt/starrocks/cn/lib/hadoop/hdfs/
EOF
fi

cat << EOF >> ${dockerfile}
ARG TARGET_BUILT=?
ARG HUDI_VERSION=?
ARG HUDI_OLD_VERSION=?
#RUN rm -f /opt/starrocks/${prj}/lib/hudi-common-${HUDI_OLD_VERSION}.jar
#RUN rm -f /opt/starrocks/${prj}/lib/hudi-hadoop-mr-${HUDI_OLD_VERSION}.jar
#COPY hudibk/${TARGET_BUILT}/hudi-common-${HUDI_VERSION}.jar /opt/starrocks/${prj}/lib/
#COPY hudibk/${TARGET_BUILT}/hudi-hadoop-mr-${HUDI_VERSION}.jar /opt/starrocks/${prj}/lib/
EOF

done

cd ${PRJ_DORIS_HOME}/starrocks-src
cp -r ${PRJ_DORIS_HOME}/hudibk ./
cp ${PRJ_HOME}/juicefs/juicefs-hadoop-${JUICEFS_VERSION}-jdk11-ubuntu22.jar ./
cp ${PRJ_HOME}/juicefs/core-site.xml ./
cp ${PRJ_HOME}/spark/hdfs-site.xml ./
cp ${PRJ_HOME}/spark/hive-site.xml ./
rm -rf .m2 && mkdir .m2
#！！！必须用腾讯maven源，阿里和华为的都不会导致je jar下载不下来，手工下载下来install提示not readable artifact
cp ${MYHOME}/m2/settings.xml .m2/
mv ${PRJ_DORIS_HOME}/starrocks-src/starrocks-${STARROCKS_REV}/output ${PRJ_DORIS_HOME}/StarRocks-${STARROCKS_REV}
dfile=Dockerfile-fe-ubuntu
echo "DEBUG >>>>>> dfile:${dfile}"
OLD_IFS="$IFS"
IFS="-"
dpath="starrocks-${STARROCKS_REV}/docker/dockerfiles"
arr=($dfile)
IFS="$OLD_IFS"
prj=${arr[1]}
echo "DEBUG >>>>>> prj:${prj}"
echo "DEBUG >>>>>> dpath:${dpath}"

TARGET_BUILT=hadoop3hive3
#TARGET_BUILT=hadoop2hive2
HUDI_VERSION=0.12.2
HUDI_OLD_VERSION=0.10.1

#--no-cache
DOCKER_BUILDKIT=1 docker build ./ -f ${dpath}/${dfile} --network=host --progress=plain\
  --build-arg TARGET_BUILT="${TARGET_BUILT}"\
  --build-arg HUDI_VERSION="${HUDI_VERSION}"\
  --build-arg HUDI_OLD_VERSION="${HUDI_OLD_VERSION}"\
  --build-arg STARROCKS_REV="${STARROCKS_REV}"\
  --build-arg JUICEFS_VERSION="${JUICEFS_VERSION}"\
  -t harbor.my.org:1080/doris/starrocks-juicefs-${prj}:${STARROCKS_REV}
docker push harbor.my.org:1080/doris/starrocks-juicefs-${prj}:${STARROCKS_REV}

cd ${PRJ_DORIS_HOME}/starrocks-src/starrocks-${STARROCKS_REV}
cp -r ${PRJ_DORIS_HOME}/hudibk ./
cp ${PRJ_HOME}/juicefs/juicefs-hadoop-${JUICEFS_VERSION}-jdk11-centos7.jar ./
cp ${PRJ_HOME}/juicefs/core-site.xml ./
cp ${PRJ_HOME}/spark/hdfs-site.xml ./
cp ${PRJ_HOME}/spark/hive-site.xml ./
mv ${PRJ_DORIS_HOME}/StarRocks-${STARROCKS_REV} ${PRJ_DORIS_HOME}/starrocks-src/starrocks-${STARROCKS_REV}/output
arr=(Dockerfile_be_centos Dockerfile_cn_centos)
#arr=(Dockerfile_cn_centos)
for dfile in ${arr[*]}
do
  echo "DEBUG >>>>>> dfile:${dfile}"
  OLD_IFS="$IFS"
  IFS="_"
  dpath="docker/dockerfiles"
  arr=($dfile)
  IFS="$OLD_IFS"
  prj=${arr[1]}
  echo "DEBUG >>>>>> prj:${prj}"
  echo "DEBUG >>>>>> dpath:${dpath}"

  #--no-cache
  DOCKER_BUILDKIT=1 docker build ./ -f ${dpath}/${dfile} --network=host --progress=plain\
    --build-arg TARGET_BUILT="${TARGET_BUILT}"\
    --build-arg HUDI_VERSION="${HUDI_VERSION}"\
    --build-arg HUDI_OLD_VERSION="${HUDI_OLD_VERSION}"\
    --build-arg STARROCKS_REV="${STARROCKS_REV}"\
    --build-arg JUICEFS_VERSION="${JUICEFS_VERSION}"\
    -t harbor.my.org:1080/doris/starrocks-juicefs-${prj}:${STARROCKS_REV}
  docker push harbor.my.org:1080/doris/starrocks-juicefs-${prj}:${STARROCKS_REV}
done


# ### only fe in ubuntu end--------------------------------------------

#rebuild in docker from source code for all other than just fe in Dockerfile
STARROCKS_2BUILD=3.0.0-avro
cd $PWD/starrocks-${STARROCKS_2BUILD}/thirdparty
file=vars.sh
cp ${file} ${file}.bk
#$SED -i 's/LIBEVENT_MD5SUM="c6c4e7614f03754b8c67a17f68177649"/LIBEVENT_MD5SUM="d41d8cd98f00b204e9800998ecf8427e"/g' ${file}
#$SED -i 's/PROTOBUF_MD5SUM="0c9d2a96f3656ba7ef3b23b533fb6170"/PROTOBUF_MD5SUM="d41d8cd98f00b204e9800998ecf8427e"/g' ${file}
$SED -i 's/GTEST_MD5SUM="ecd1fa65e7de707cd5c00bdac56022cd"/GTEST_MD5SUM="d41d8cd98f00b204e9800998ecf8427e"/g' ${file}
$SED -i 's/AWS_SDK_CPP_MD5SUM="3a4e2703eaeeded588814ee9e61a3342"/AWS_SDK_CPP_MD5SUM="d41d8cd98f00b204e9800998ecf8427e"/g' ${file}
$SED -i 's///g' ${file}
cd $PWD/starrocks-${STARROCKS_2BUILD}
SED=sed
file=build.sh
cp ${file} ${file}.bk
$SED -i 's/-DskipTests/-DskipTests -Dspotless.check.skip=true -Dmaven.javadoc.skip=true -Dcheckstyle.skip=true -Dlicense.skip=true/g' ${file}
-DskipTests
#mac
docker run -itd --name centos7-netutil-ccplus7-go-jdk --restart unless-stopped -v /Volumes/data/m2:/root/.m2 -v $PWD/starrocks-${STARROCKS_2BUILD}:/root/workspace/starrocks -v /Volumes/data/gopath:/root/workspace/gopath harbor.my.org:1080/base/python:3.8-centos7-netutil-ccplus7-go-jdk tail -f /dev/null
docker stop centos7-netutil-ccplus7-go-jdk && docker rm centos7-netutil-ccplus7-go-jdk
docker exec -it centos7-netutil-ccplus7-go-jdk bash
#dtpct
cd /data0
wget -c https://github.com/containernetworking/plugins/releases/download/v1.2.0/cni-plugins-linux-amd64-v1.2.0.tgz
cd /opt/cni/bin
tar xzvf /data0/cni-plugins-linux-amd64-v1.2.0.tgz
cd /data0
nerdctl run -d --insecure-registry --ulimit nofile=65536:65536 --name centos7-netutil-ccplus7-go-jdk -v $PWD/.m2:/root/.m2 -v $PWD/starrocks-${STARROCKS_2BUILD}:/root/workspace/starrocks -v $PWD/gopath:/root/workspace/gopath harbor.my.org:1080/base/python:3.8-centos7-netutil-ccplus7-go-jdk tail -f /dev/null
nerdctl stop centos7-netutil-ccplus7-go-jdk && nerdctl rm centos7-netutil-ccplus7-go-jdk
nerdctl exec -it centos7-netutil-ccplus7-go-jdk bash
  export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.18.0.10-1.el7_9.x86_64
  java -version
  scl enable devtoolset-10 bash
  source scl_source enable devtoolset-10
  gcc --version
  cmake -version
  
  cd /root/workspace/starrocks
  cd thirdparty/
  ./download-thirdparty.sh
  ./build-thirdparty.sh
  cd ..
  export STARROCKS_VERSION="3.0.0-avro"
:<<EOF
be/src/service/starrocks_main.cpp:74:2: error: #error _GLIBCXX_USE_CXX11_ABI must be non-zero
我临时删除了be/src/service/starrocks_main.cpp中的来重新编译
if !_GLIBCXX_USE_CXX11_ABI
error _GLIBCXX_USE_CXX11_ABI must be non-zero
endif
file=be/src/service/starrocks_main.cpp
cp ${file} ${file}.bk
EOF
  #多重复运行build.sh也能下载下来
  mvn install:install-file -DgroupId=com.amazonaws -DartifactId=aws-java-sdk-bundle -Dversion=1.11.1026 -Dpackaging=jar -Dfile=aws-java-sdk-bundle-1.11.1026.jar
  ./build.sh
  #sh build.sh  --fe --be --spark-dpp --clean
  

# ### backup for rebuild juicefs jar in centos --------------------------------------------
cd ${PRJ_DORIS_HOME}/starrocks-src
arr=(Dockerfile-fe-ubuntu Dockerfile_be_centos Dockerfile_cn_centos)
for dfile in ${arr[*]}
do
  echo "DEBUG >>>>>> dfile:${dfile}"
  OLD_IFS="$IFS"
  if [[ "${dfile}" == "Dockerfile-fe-ubuntu" ]]; then
    IFS="-"
  else
    IFS="_"
  fi
  arr=($dfile)
  IFS="$OLD_IFS"
  prj=${arr[1]}
  echo "DEBUG >>>>>> prj:${prj}"
  dpath="starrocks-${STARROCKS_REV}/docker/dockerfiles"
  echo "DEBUG >>>>>> dpath:${dpath}"

  if [[ "${prj}" != "fe" ]]; then
    $SED -i 's/FROM centos:7/FROM centos:7 as base/g' ${dpath}/${dfile}
  fi

  if [[ "${prj}" == "be" ]]; then
    $SED -i 's/apt-get install -y --no-install-recommends binutils-dev mysql-client default-jdk/apt-get install -y --no-install-recommends binutils-dev mysql-client default-jdk bc/g' ${dpath}/${dfile}
  fi
  if [[ "${prj}" == "fe" ]]; then
    #cp ${dpath}/${dfile} ${dpath}/${dfile}.bk
    #$SED -i 's/apt-get install -y --no-install-recommends default-jdk curl/apt-get install -y --no-install-recommends default-jdk curl bc/g' ${dpath}/${dfile}
    $SED -i "/RUN git clone /i\COPY .m2 \/root\/.m2" ${dpath}/${dfile}
    #$SED -i "/RUN git clone /i\COPY jackson-mapper-asl-1.9.13-cloudera.2.jar .\/\nRUN mvn install:install-file -DgroupId=org.codehaus.jackson -DartifactId=jackson-mapper-asl -Dversion=1.9.13-cloudera.2 -Dpackaging=jar -Dfile=.\/jackson-mapper-asl-1.9.13-cloudera.2.jar\nCOPY je-7.3.7.jar .\/\nRUN mvn install:install-file -DgroupId=com.sleepycat -DartifactId=je -Dversion=7.3.7 -Dpackaging=jar -Dfile=.\/je-7.3.7.jar" ${dpath}/${dfile}
    $SED -i "/RUN git clone /i\COPY jackson-mapper-asl-1.9.13-cloudera.2.jar .\/\nRUN mvn install:install-file -DgroupId=org.codehaus.jackson -DartifactId=jackson-mapper-asl -Dversion=1.9.13-cloudera.2 -Dpackaging=jar -Dfile=.\/jackson-mapper-asl-1.9.13-cloudera.2.jar" ${dpath}/${dfile}
    $SED -i "/RUN git clone /a\ARG STARROCKS_REV=?\nCOPY starrocks-\${STARROCKS_REV} starrocks" ${dpath}/${dfile}
    $SED -i '/RUN git clone /d' ${dpath}/${dfile}
    $SED -i 's/        && cd /RUN cd /g' ${dpath}/${dfile}
    $SED -i "/COPY --from=builder/a\COPY starrocks-\${STARROCKS_REV}/docker/bin/fe_entrypoint.sh starrocks-\${STARROCKS_REV}/docker/bin/fe_prestop.sh /opt/starrocks/" ${dpath}/${dfile}
    #$SED -i "s@COPY --from=builder /opt/starrocks/fe /opt/starrocks/fe@COPY --from=builder /opt/starrocks /opt/starrocks@g" ${dpath}/${dfile}
    $SED -i "/FROM ubuntu:22.04 as base/a\ARG STARROCKS_REV=?\nARG JUICEFS_VERSION=?" ${dpath}/${dfile}

  fi

cat << EOF >> docker/dockerfiles/${dfile}
COPY core-site.xml /opt/starrocks/${prj}/conf/
COPY hdfs-site.xml /opt/starrocks/${prj}/conf/
COPY hive-site.xml /opt/starrocks/${prj}/conf/
EOF

  if [[ "${prj}" == "fe" ]]; then
cat << EOF >> docker/dockerfiles/${dfile}
COPY juicefs-hadoop-1.0.2-jdk11-ubuntu22.04.jar /opt/starrocks/${prj}/lib/
EOF
  else
cat << EOF >> ${dpath}/${dfile}

ENV MY_HOME=/opt/starrocks

FROM base as juicefs
ARG JUICEFS_VERSION=?
ADD go1.19.2.linux-amd64.tar.gz ./
ENV PATH ${MY_HOME}/go/bin:$PATH
ENV GOPROXY https://goproxy.cn

ADD juicefs-${JUICEFS_VERSION}.tar.gz ./

COPY Centos-7.repo /etc/yum.repos.d/CentOS-Base.repo
COPY epel-7.repo /etc/yum.repos.d/epel-7.repo
RUN yum clean all && yum makecache && yum -y update
RUN yum install -y centos-release-scl
RUN yum install -y devtoolset-7-gcc devtoolset-7-make
RUN yum install -y devtoolset-7-gcc-c++ devtoolset-7-gcc-gfortran
RUN scl enable devtoolset-7 bash
RUN echo "source scl_source enable devtoolset-7" >> /root/.bashrc

COPY gopath ${MY_HOME}/gopath
ENV GOPATH ${MY_HOME}/gopath
COPY apache-maven ${MY_HOME}/maven
COPY .m2 ${MY_HOME}/.m2

WORKDIR ${MY_HOME}/juicefs-${JUICEFS_VERSION}/sdk/java
ENV PATH ${MY_HOME}/maven/bin:$PATH
RUN sed -i 's/-Dmaven.test.skip=true/-Dmaven.test.skip=true -Dmaven.javadoc.skip=true/g' Makefile
RUN go env -w GO111MODULE=auto
RUN make

FROM base
ARG JUICEFS_VERSION=?
COPY --from=juicefs ${MY_HOME}/juicefs-${JUICEFS_VERSION}/sdk/java/target/juicefs-hadoop-${JUICEFS_VERSION}.jar /opt/starrocks/${prj}/lib/juicefs-hadoop-${JUICEFS_VERSION}-jdk11-centos7.jar

EOF

fi


cd ${PRJ_DORIS_HOME}/starrocks-src
mv ${PRJ_DORIS_HOME}/starrocks-src/starrocks-${STARROCKS_REV}/output ${PRJ_DORIS_HOME}/StarRocks-${STARROCKS_REV}
arr=(Dockerfile-fe-ubuntu Dockerfile_be_centos Dockerfile_cn_centos)
for dfile in ${arr[*]}
do
  echo "DEBUG >>>>>> dfile:${dfile}"
  OLD_IFS="$IFS"
  if [[ "${dfile}" == "Dockerfile-fe-ubuntu" ]]; then
    IFS="-"
    dpath="starrocks-${STARROCKS_REV}/docker/dockerfiles"
  else
    IFS="_"
    dpath="docker/dockerfiles"
  fi
  arr=($dfile)
  IFS="$OLD_IFS"
  prj=${arr[1]}
  echo "DEBUG >>>>>> prj:${prj}"
  echo "DEBUG >>>>>> dpath:${dpath}"

  rm -rf .m2 && mkdir .m2
  cp ${MYHOME}/m2/settings.xml .m2/
  if [[ "${prj}" != "fe" ]]; then
    if [[ ! -f ./juicefs-${JUICEFS_VERSION}.tar.gz ]]; then
      echo "DEBUG >>>>>> copy building files for Dockerfile"
      cp ${PRJ_HOME}/juicefs/juicefs-${JUICEFS_VERSION}.tar.gz ./
      cp ${PRJ_HOME}/image/go1.19.2.linux-amd64.tar.gz ./
      cp ${PRJ_HOME}/image/Centos-7.repo ./
      cp ${PRJ_HOME}/image/epel-7.repo ./
    fi
    mv ${maven_home} ./apache-maven
    mv ${go_path} ./
  fi

  #--no-cache
  DOCKER_BUILDKIT=1 docker build ./ -f ${dpath}/${dfile} --network=host --progress=plain  --build-arg STARROCKS_REV="${STARROCKS_REV}" --build-arg JUICEFS_VERSION="${JUICEFS_VERSION}" -t harbor.my.org:1080/doris/starrocks-juicefs-${prj}:${STARROCKS_REV}
  docker push harbor.my.org:1080/doris/starrocks-juicefs-${prj}:${STARROCKS_REV}

  if [[ "${prj}" != "fe" ]]; then
    mv apache-maven ${MYHOME}/apache-maven-${maven_version}
    mv gopath ${MYHOME}/
  fi

  if [[ "${prj}" == "fe" ]]; then
    mv ${PRJ_DORIS_HOME}/StarRocks-${STARROCKS_REV} ${PRJ_DORIS_HOME}/starrocks-src/starrocks-${STARROCKS_REV}/output
    cd ${PRJ_DORIS_HOME}/starrocks-src/starrocks-${STARROCKS_REV}
    if [[ ! -f ./core-site.xml ]]; then
      echo "DEBUG >>>>>> copy hadoop xml files for Dockerfile"
      cp ${PRJ_HOME}/juicefs/core-site.xml ./
      cp ${PRJ_HOME}/spark/hdfs-site.xml ./
      cp ${PRJ_HOME}/spark/hive-site.xml ./
    fi
  fi
done


