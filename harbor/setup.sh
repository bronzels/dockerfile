if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Mac detected."
    #mac
    DATAHOME=/Volumes/data/Applications
    os=darwin
    SED=gsed
else
    echo "Assuming linux by default."
    #linux
    DATAHOME=~
    os=linux
    SED=sed
fi
HARBORDATA=${DATAHOME}/harbor

#https://github.com/goharbor/harbor/releases/tag/v2.1.2
#https://github.com/goharbor/harbor/releases/download/v2.6.2/harbor-offline-installer-v2.6.2.tgz
rev=2.1.2
#rev=2.6.2
tar xzvf harbor-offline-installer-v$rev.tgz
cd harbor
cp harbor.yml.tmpl harbor.yml
#修改harbor.yml主机名和登录密码，注释掉https
$SED -i "s@hostname: reg.mydomain.com@hostname: harbor.my.org@g" harbor.yml
$SED -i "s@port: 80@port: 1080@g" harbor.yml
$SED -i "s@https:@#https:@g" harbor.yml
$SED -i "s@port: 443@#port: 443@g" harbor.yml
$SED -i "s@certificate: /your/certificate/path@#certificate: /your/certificate/path@g" harbor.yml
$SED -i "s@private_key: /your/private/key/path@#private_key: /your/private/key/path@g" harbor.yml
#修改数据目录
$SED -i "s@data_volume: /data@data_volume: $HARBORDATA@g" harbor.yml
$SED -i "s@location: /var/log/harbor@location: $HARBORDATA/log@g" harbor.yml
#cp prepare prepare.bk
#$SED -i "s@docker run --rm@sudo docker run --rm@g" prepare
#$SED -i "s@@@g" prepare
./prepare
./install.sh
docker-compose down
#generate secret for k8s
docker login harbor.my.org:1080
#admin密码Harbor12345

#sudo lsof -nP -p 32239 | grep LISTEN
sudo lsof -nP | grep LISTEN