#一、下载需要安装的版本号
wget https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.24.0.tar.gz
#二、安装需求
yum install curl-devel expat-devel gettext-devel openssl-devel zlib-devel
#三、卸载Centos自带的git:
yum remove git
git --version
#四、安装
tar -zxf git-2.24.0.tar.gz
cd git-2.24.0
make prefix=/usr/local/git all
make prefix=/usr/local/git install
#五、添加环境变量
vim /etc/profile
#export PATH=$PATH:/usr/local/git/bin
source /etc/profile
#六、查看版本号
git --version
#2.24.0
