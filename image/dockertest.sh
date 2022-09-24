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

echo -n '' | base64
