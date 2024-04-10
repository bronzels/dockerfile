docker build ./ -f Dockerfile-jenkins -t harbor.my.org:1080/library/ci/jenkins_jenkins_2.263.1-lts-centos7
docker push harbor.my.org:1080/library/ci/jenkins_jenkins_2.263.1-lts-centos7
docker run -d --name jenkins --restart unless-stopped -p 28080:8080 -p 50000:50000 -v /var/run/docker.sock:/var/run/docker.sock -v /cdhdata1/bigopera/jenkins/data:/var/jenkins_home harbor.my.org:1080/library/ci/jenkins_jenkins_2.263.1-lts-centos7

docker build ./ -f Dockerfile-alpine-mvn -t harbor.my.org:1080/library/ci/rookieops/maven:3.5.0-alpine
docker push harbor.my.org:1080/library/ci/rookieops/maven:3.5.0-alpine

nohup docker build ./ --add-host pypi.my.org:192.168.0.62 -f Dockerfile-alpine-py37-jenkins-build -t harbor.my.org:1080/library/ci/python:3.7-alpine-jenkins-build > build-Dockerfile-alpine-py37-jenkins-build.log 2>&1 &
tail -f build-Dockerfile-alpine-py37-jenkins-build.log
docker push harbor.my.org:1080/library/ci/python:3.7-alpine-jenkins-build

docker build ./ --add-host pypi.my.org:192.168.0.62 -f Dockerfile-base-nginx -t harbor.my.org:1080/base/nginx
docker push harbor.my.org:1080/base/nginx

nohup docker build ./ --add-host pypi.my.org:192.168.0.62 -f Dockerfile-base-py37 -t harbor.my.org:1080/base/py/python:3.7-alpine > build-Dockerfile-base-py37.log 2>&1 &
tail -f build-Dockerfile-base-py37.log
docker push harbor.my.org:1080/base/py/python:3.7-alpine

#copy libadsusertestsys requirements.txt, add libadsusertestsys into
nohup docker build ./ --add-host pypi.my.org:192.168.0.62 -f Dockerfile-usertestsys-py37 -t harbor.my.org:1080/base/py/usertestsys > build-Dockerfile-usertestsys-py37.log 2>&1 &
tail -f build-Dockerfile-usertestsys-py37.log
docker push harbor.my.org:1080/base/py/usertestsys

docker build ./ --add-host pypi.my.org:192.168.0.62 -f Dockerfile-usertestsys-spe-py37 -t harbor.my.org:1080/base/py/usertestsys-spe
docker push harbor.my.org:1080/base/py/usertestsys-spe

#copy usertestsys-vocabularysizeestimation requirements.txt
nohup docker build ./ -f Dockerfile-vocabularysizeestimation-req --add-host pypi.my.org:192.168.0.62 -t harbor.my.org:1080/python-app/usertestsys-vocabularysizeestimation-req > build-Dockerfile-usertestsys-vocabularysizeestimation-req.log 2>&1 &
tail -f build-Dockerfile-usertestsys-vocabularysizeestimation-req.log
docker push harbor.my.org:1080/python-app/usertestsys-vocabularysizeestimation-req

nohup docker build ./ --add-host pypi.my.org:192.168.0.62 -f Dockerfile-api-doc -t harbor.my.org:1080/base/node/api-doc > build-Dockerfile-api-doc.log 2>&1 &
tail -f build-Dockerfile-api-doc.log
docker push harbor.my.org:1080/base/node/api-doc

nohup docker build ./ --add-host pypi.my.org:192.168.0.62 -f Dockerfile-doc-mdbook -t harbor.my.org:1080/base/node/doc-mdbook > build-Dockerfile-doc-mdbook.log 2>&1 &
tail -f build-Dockerfile-doc-mdbook.log
docker push harbor.my.org:1080/base/node/doc-mdbook

nohup docker build ./ --add-host pypi.my.org:192.168.0.62 -f Dockerfile-jenkins-docker-kustomize -t harbor.my.org:1080/library/ci/jenkins-docker-kustomize > build-Dockerfile-jenkins-docker-kustomize.log 2>&1 &
tail -f build-Dockerfile-jenkins-docker-kustomize.log
docker push harbor.my.org:1080/library/ci/jenkins-docker-kustomize

nohup docker build ./ --add-host pypi.my.org:192.168.0.62 -f Dockerfile-sandman -t harbor.my.org:1080/base/py/sandman > build-Dockerfile-sandman-base.log 2>&1 &
tail -f build-Dockerfile-sandman-base.log
docker push harbor.my.org:1080/base/py/sandman

nohup docker build ./ --add-host pypi.my.org:192.168.0.62 -f Dockerfile-centos-py37 -t harbor.my.org:1080/base/py/python:3.7-centos > build-Dockerfile-centos-py37.log 2>&1 &
tail -f build-Dockerfile-centos-py37.log
docker push harbor.my.org:1080/base/py/python:3.7-centos

nohup docker build ./ --add-host pypi.my.org:192.168.0.62 -f Dockerfile-centos-py37-jenkins-build -t harbor.my.org:1080/library/ci/python:3.7-centos-jenkins-build > build-Dockerfile-centos-py37-jenkins-build.log 2>&1 &
tail -f build-Dockerfile-centos-py37-jenkins-build.log
docker push harbor.my.org:1080/library/ci/python:3.7-centos-jenkins-build

nohup docker build ./ -f Dockerfile-centos7-py38-netutil -t harbor.my.org:1080/base/python:3.8-centos7-netutil > build-Dockerfile-centos7-py38-netutil.log 2>&1 &
tail -f build-Dockerfile-centos7-py38-netutil.log
docker push harbor.my.org:1080/base/python:3.8-centos7-netutil
docker tag harbor.my.org:1080/base/python:3.8-centos7-netutil harbor.my.org:1080/basesec/python:3.8-centos7-netutil
docker push harbor.my.org:1080/basesec/python:3.8-centos7-netutil

nohup docker build ./ --progress=plain -f Dockerfile-ubuntu20 -t harbor.my.org:1080/base/ubuntu20 > build-Dockerfile-ubuntu20-base.log 2>&1 &
tail -f build-Dockerfile-ubuntu20.log
docker push harbor.my.org:1080/base/ubuntu20

nohup docker build ./ --progress=plain -f Dockerfile-ubuntu22-openjdk8 -t harbor.my.org:1080/base/ubuntu22-openjdk8 > build-Dockerfile-ubuntu22-openjdk8-base.log 2>&1 &
tail -f build-Dockerfile-ubuntu22-openjdk8.log
docker push harbor.my.org:1080/base/ubuntu22-openjdk8

nohup docker build ./ --progress=plain -f Dockerfile-centos7-py38-netutil-ccplus7 -t harbor.my.org:1080/base/python:3.8-centos7-netutil-ccplus7 > build-Dockerfile-centos7-py38-netutil-ccplus7.log 2>&1 &
tail -f build-Dockerfile-centos7-py38-netutil-ccplus7.log
docker push harbor.my.org:1080/base/python:3.8-centos7-netutil-ccplus7

nohup docker build ./ --progress=plain -f Dockerfile-centos7-py38-netutil-ccplus7-go -t harbor.my.org:1080/base/python:3.8-centos7-netutil-ccplus7-go > build-Dockerfile-centos7-py38-netutil-ccplus7-go.log 2>&1 &
tail -f build-Dockerfile-centos7-py38-netutil-ccplus7-go.log
docker push harbor.my.org:1080/base/python:3.8-centos7-netutil-ccplus7-go

nohup docker build ./ --progress=plain -f Dockerfile-centos7-py38-netutil-ccplus7-go-jdk -t harbor.my.org:1080/base/python:3.8-centos7-netutil-ccplus7-go-jdk > build-Dockerfile-centos7-py38-netutil-ccplus7-go-jdk.log 2>&1 &
tail -f build-Dockerfile-centos7-py38-netutil-ccplus7-go-jdk.log
docker push harbor.my.org:1080/base/python:3.8-centos7-netutil-ccplus7-go-jdk

nohup docker build ./ --progress=plain -f Dockerfile-debian11-ccplus-go-jdk -t harbor.my.org:1080/base/debian11:ccplus-go-jdk > build-Dockerfile-debian11-ccplus-go-jdk.log 2>&1 &
tail -f build-Dockerfile-debian11-ccplus-go-jdk.log
docker push harbor.my.org:1080/base/debian11:ccplus-go-jdk

nohup docker build ./ --progress=plain -f Dockerfile-ubuntu22-netutil-ccplus7-go-jdk -t harbor.my.org:1080/base/ubuntu22:netutil-ccplus7-go-jdk > build-Dockerfile-ubuntu22-netutil-ccplus7-go-jdk.log 2>&1 &
tail -f build-Dockerfile-ubuntu22-netutil-ccplus7-go-jdk.log
docker push harbor.my.org:1080/base/ubuntu22:netutil-ccplus7-go-jdk

nohup docker build ./ --progress=plain -f Dockerfile-ubuntu20-netutil-ccplus7-go-jdk -t harbor.my.org:1080/base/ubuntu20:netutil-ccplus7-go-jdk > build-Dockerfile-ubuntu20-netutil-ccplus7-go-jdk.log 2>&1 &
tail -f build-Dockerfile-ubuntu20-netutil-ccplus7-go-jdk.log
docker push harbor.my.org:1080/base/ubuntu20:netutil-ccplus7-go-jdk

nohup docker build ./ --progress=plain -f Dockerfile-centos7-py38-netutil-ccplus7-go-mpich -t harbor.my.org:1080/base/python:3.8-centos7-netutil-ccplus7-go-mpich > build-Dockerfile-centos7-py38-netutil-ccplus7-go-mpich.log 2>&1 &
tail -f build-Dockerfile-centos7-py38-netutil-ccplus7-go-mpich.log
docker push harbor.my.org:1080/base/python:3.8-centos7-netutil-ccplus7-go-mpich

nohup docker build ./ --progress=plain -f Dockerfile-centos7-py38-netutil-ccplus7-go-openmpi -t harbor.my.org:1080/base/python:3.8-centos7-netutil-ccplus7-go-openmpi > build-Dockerfile-centos7-py38-netutil-ccplus7-go-openmpi.log 2>&1 &
tail -f build-Dockerfile-centos7-py38-netutil-ccplus7-go-openmpi.log
docker push harbor.my.org:1080/base/python:3.8-centos7-netutil-ccplus7-go-openmpi

echo -n '' | base64
