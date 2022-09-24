docker run -d --name jenkins --restart unless-stopped -p 28080:8080 -p 50000:50000 -v /var/run/docker.sock:/var/run/docker.sock -v /cdhdata1/bigopera/jenkins/data:/var/jenkins_home harbor.my.org:1080/library/ci/jenkins_jenkins_2.263.1-lts-centos7
docker exec -it jenkins /bin/sh
	cat /var/jenkins_home/secrets/initialAdminPassword
cp /var/jenkins_home/updates/default.json /var/jenkins_home/updates/default.json.bk
sed -i 's/updates.jenkins-ci.org\/download/mirrors.tuna.tsinghua.edu.cn\/jenkins/g'	/var/jenkins_home/updates/default.json
sed -i 's/www.google.com/www.baidu.com/g' /var/jenkins_home/updates/default.json
