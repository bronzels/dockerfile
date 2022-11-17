wget -c https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
ansible nvidia -m copy -a"src=Miniconda3-latest-Linux-x86_64.sh dest=/root/"
bash /root/Miniconda3-latest-Linux-x86_64.sh -b -p /usr/local/miniconda3
ansible nvidia -m shell -a'echo "eval \"\$(/usr/local/miniconda3/bin/conda shell.bash hook)\"" >> /root/.bashrc'
tail -2 /root/.bashrc
conda init
#使用以下命令查看源channel：
conda config --show-sources
conda config --show
conda config --set show_channel_urls yes

conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge/
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/

conda config --add channels https://mirrors.ustc.edu.cn/anaconda/cloud/conda-forge/
conda config --add channels https://mirrors.ustc.edu.cn/anaconda/pkgs/main/
conda config --add channels https://mirrors.ustc.edu.cn/anaconda/pkgs/free/

conda config --add channels https://mirrors.aliyun.com/anaconda/cloud/conda-forge/
conda config --add channels https://mirrors.aliyun.com/anaconda/pkgs/main/
conda config --add channels https://mirrors.aliyun.com/anaconda/pkgs/free/

conda config --add channels https://mirrors.douban.com/anaconda/cloud/conda-forge/
conda config --add channels https://mirrors.douban.com/anaconda/pkgs/main/
conda config --add channels https://mirrors.douban.com/anaconda/pkgs/free/

