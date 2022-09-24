git clone https://github.com/codekoala/docker-pypi.git
exec /usr/bin/pypi-server \
    --fallback-url https://pypi.doubanio.com/simple/ \
    --port ${PYPI_PORT} \
    --passwords "${PYPI_PASSWD_FILE}" \
    --authenticate "${PYPI_AUTHENTICATE}" \
    ${_extra} \
    "${PYPI_ROOT}"
#修改entrypoint.sh
docker build ./ -t harbor.my.org:1080/library/ci/codekoala/pypi
docker push harbor.my.org:1080/library/ci/codekoala/pypi
#rmpack.sh放在本地映射仓库目录
#在仓库目录创建密码文件
sudo touch .htpasswd
sudo chown bigopera:bigopera .htpasswd
htpasswd -s .htpasswd pypiadmin
docker run -itd --restart unless-stopped \
    -h pypi.my.org \
    -v /cdhdata1/bigopera/pypi/codekoala:/srv/pypi:rw \
    -p 18080:80 \
    --name pypi.my.org \
    harbor.my.org:1080/library/ci/codekoala/pypi

docker run -itd --restart unless-stopped \
    -h pypi-dev.my.org \
    -v /cdhdata1/bigopera/pypi/codekoala-dev:/srv/pypi:rw \
    -p 18180:80 \
    --name pypi-dev.my.org \
    harbor.my.org:1080/library/ci/codekoala/pypi	

#开发pc
#创建仓库目录，放入服务器密码文件
#本地windows启动pypiserver要把docker engine的Use the WSL 2 based engine给uncheck，不然报告403错误
docker run -itd --restart unless-stopped -h pypi-local.my.org -v e:\pypirepo:/srv/pypi:rw -p 9090:80 --name pypi-local.my.org harbor.my.org:1080/library/ci/codekoala/pypi

#3个ini文件放到C:\Users\xbli06\pip，xbli06换成你的计算机账号