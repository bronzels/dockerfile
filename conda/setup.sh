wget -c https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
ansible nvidia -m copy -a"src=Miniconda3-latest-Linux-x86_64.sh dest=/data0/"
bash Miniconda3-latest-Linux-x86_64.sh -b -p /usr/local/miniconda3
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
conda create -n diveintodl python=3.9 -y
#conda remove -n diveintodl --all -y
ls /data0/envs/diveintodl

pip install tensorflow==2.8.0
pip install tensorflow-probability==0.16.0
#pip install torch==1.12.0
#pip install torchvision==0.13.0
:<<EOF
wget -c https://download.pytorch.org/whl/cu113/torch-1.12.0%2Bcu113-cp39-cp39-linux_x86_64.whl
wget -c https://download.pytorch.org/whl/cu113/torchvision-0.13.0%2Bcu113-cp39-cp39-linux_x86_64.whl
pip install torch-1.12.0+cu113-cp39-cp39-linux_x86_64.whl
pip install torchvision-0.13.0+cu113-cp39-cp39-linux_x86_64.whl
EOF
wget -c https://download.pytorch.org/whl/cu116/torch-1.12.0%2Bcu116-cp39-cp39-linux_x86_64.whl
wget -c https://download.pytorch.org/whl/cu116/torchvision-0.13.0%2Bcu116-cp39-cp39-linux_x86_64.whl
pip install torch-1.12.0+cu116-cp39-cp39-linux_x86_64.whl
pip install torchvision-0.13.0+cu116-cp39-cp39-linux_x86_64.whl
wget -c https://download.pytorch.org/whl/torchtext-0.13.0-cp39-cp39-linux_x86_64.whl
pip install torchtext-0.13.0-cp39-cp39-linux_x86_64.whl

pip uninstall protobuf -y
#tensorflow import出错，版本要低于3.20.x，但是pytorch必须高于3.20.x
pip install protobuf==3.20.2

pip install d2l==0.17.6

#https://blog.csdn.net/qq_18256855/article/details/125439096
#step 1
pip install jupyter notebook
#step 2
jupyter notebook --generate-config
:<<EOF
#step 3
接下来键盘输入ipython
输入from notebook.auth import passwd
输入passwd()，Enter password: 输入你要设定的密码，Verify password: 验证密码

#step 4
在~/.jupyter/jupyter_notebook_config.py末尾添加
c.NotebookApp.ip = '*'                     # 允许访问此服务器的 IP，星号表示任意 IP
c.NotebookApp.password = 'argon2:$argon2id$v=19$m=10240,t=10,p=8$QplvWXtYUtp4TlXS1T1urQ$xulqNxrIqlJmCPrBHd7nGA' # 之前生成的密码 hash 字串, 粘贴进去
c.NotebookApp.open_browser = False         # 运行时不打开本机浏览器
c.NotebookApp.port = 8890                  # 使用的端口，随意设置，但是要记得你设定的这个端口
c.NotebookApp.enable_mathjax = True        # 启用 MathJax
c.NotebookApp.allow_remote_access = True   #允许远程访问
c.NotebookApp.allow_root = True       

#step 5
在pycharm同步的目录运行jupyter notebook

#step 6
在远程图形界面浏览器上输入http://dtpct:8890
EOF


pip install /root/TensorRT-8.6.1.6/python/tensorrt-8.6.1-cp39-none-linux_x86_64.whl
"""
pip install /root/trt/uff/uff-0.6.9-py2.py3-none-any.whl
pip install /root/trt/graphsurgeon/graphsurgeon-0.4.6-py2.py3-none-any.whl
转uff只支持到tf 1.5
"""
pip install tf2onnx
python -c "import tensorrt;print(tensorrt.__version__)"
