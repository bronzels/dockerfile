#https://github.com/goharbor/harbor/releases/tag/v2.1.2
tar xzvf harbor-offline-installer-v2.1.2.tgz
cd harbor
cp harbor.yml.tmpl harbor.yml
vim harbor.yml
#修改harbor.yml主机名和登录密码
./prepare
./install.sh
#generate secret for k8s
docker login harbor.my.org:1080
#admin密码Harbor12345

