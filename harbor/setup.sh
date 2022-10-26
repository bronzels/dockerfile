#https://github.com/goharbor/harbor/releases/tag/v2.1.2
rev=2.6.1
tar xzvf harbor-offline-installer-v$rev.tgz
cd harbor
cp harbor.yml.tmpl harbor.yml
vim harbor.yml
#修改harbor.yml主机名和登录密码
./prepare
./install.sh
#generate secret for k8s
docker login harbor.my.org:1080
#admin密码Harbor12345

#sudo lsof -nP -p 32239 | grep LISTEN
sudo lsof -nP | grep LISTEN