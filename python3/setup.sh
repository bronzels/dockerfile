#安装python 3.7
yum install -y zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel
yum install -y libffi-devel
#control point
wget -c https://www.python.org/ftp/python/3.7.4/Python-3.7.4.tar.xz
ansible slave -m copy -a"src=Python-3.7.4.tar.xz dest=/root/"
xz -d Python-3.7.4.tar.xz
tar -xvf Python-3.7.4.tar

#进入解压后的目录，依次执行下面命令进行手动编译
cd /root/Python-3.7.4;./configure prefix=/usr/local/python-3.7.4;make;make install;rm -f /usr/local/python3;ln -s /usr/local/python-3.7.4 /usr/local/python-3
#将 python3 进行环境变量配置
echo "export PATH=\$PATH:/usr/local/python-3/bin" >> /root/.bashrc
python3 --version
#安装pip3
ansible slave -m copy -a"src=get-pip.py dest=/root/"
mkdir /root/.pip
ansible slave -m copy -a"src=pip.conf dest=/root/.pip/"
python3 get-pip.py
pip3 --version