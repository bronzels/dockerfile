:<<EOF
git clone https://github.com/sameersbn/docker-gitlab.git
#下载zip
unzip docker-gitlab-master.zip
#替换docker-compose.yml
EOF

docker network create cicd
docker-compose up -d

#root/xbxlXB12#$

docker exec -it gitlab_gitlab_1 /bin/bash

#docker-compose down