wget -c https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
ansible nvidia -m copy -a"src=Miniconda3-latest-Linux-x86_64.sh dest=/root/"
bash /root/Miniconda3-latest-Linux-x86_64.sh -b -p /usr/local/miniconda3
echo "eval \"\$(/usr/local/miniconda3/bin/conda shell.bash hook)\"" >> /root/.bashrc
#ansible nvidia -m shell -a'echo "eval \"\$(/usr/local/miniconda3/bin/conda shell.bash hook)\"" >> /root/.bashrc'
tail -2 /root/.bashrc
conda init
#使用以下命令查看源channel：
conda config --show-sources
conda config --show
conda config --set show_channel_urls yes

conda config --remove-key channels

conda config --add channels http://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/msys2/
conda config --add channels http://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge/
conda config --add channels http://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/
conda config --add channels http://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
conda config --add channels http://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/bioconda/

conda update --all -y

#rm -f ~/.condarc exit

:<<EOF
conda config --add channels https://mirrors.ustc.edu.cn/anaconda/cloud/conda-forge/
conda config --add channels https://mirrors.ustc.edu.cn/anaconda/pkgs/main/
conda config --add channels https://mirrors.ustc.edu.cn/anaconda/pkgs/free/

conda config --add channels https://mirrors.aliyun.com/anaconda/cloud/conda-forge/
conda config --add channels https://mirrors.aliyun.com/anaconda/pkgs/main/
conda config --add channels https://mirrors.aliyun.com/anaconda/pkgs/free/

conda config --add channels https://mirrors.douban.com/anaconda/cloud/conda-forge/
conda config --add channels https://mirrors.douban.com/anaconda/pkgs/main/
conda config --add channels https://mirrors.douban.com/anaconda/pkgs/free/
EOF

cat << \EOF >> ~/.condarc
envs_dirs:
  - /data0/envs
EOF

#nvidia节点
mkdir /data0/envs
conda create -n diveintodl python=3.9
ls /data0/envs/diveintodl

pip install tensorflow==2.8.0
pip install tensorflow-probability==0.16.0
#pip install torch==1.12.0
#pip install torchvision==0.13.0
wget -c https://download.pytorch.org/whl/cu113/torch-1.12.0%2Bcu113-cp39-cp39-linux_x86_64.whl
wget -c https://download.pytorch.org/whl/cu113/torchvision-0.13.0%2Bcu113-cp39-cp39-linux_x86_64.whl
wget -c https://download.pytorch.org/whl/torchtext-0.13.0-cp39-cp39-linux_x86_64.whl
pip install torch-1.12.0+cu113-cp39-cp39-linux_x86_64.whl
pip install torchvision-0.13.0+cu113-cp39-cp39-linux_x86_64.whl
pip install torchtext-0.13.0-cp39-cp39-linux_x86_64.whl

pip uninstall protobuf
pip install protobuf==3.19.0
