#on nvidia working node
cd /data0/shouxieai/deepspeed

cat << \EOF >> hostfile
dtpct slots=1
mdubu slots=1
EOF

wget https://github.com/chaos/pdsh/releases/download/pdsh-2.34/pdsh-2.34.tar.gz
tar -zxvf pdsh-2.34.tar.gz
cd pdsh-2.34
./configure
make
make install
yum install dnf
dnf install pdsh-rcmd-ssh

conda create -n deepspeed python=3.9
cat << \EOF >> /root/.bashrc
conda activate deepspeed
EOF

CUDA_VISIBLE_DEVICES=0 python -c "import torch; print(torch.cuda.get_device_capability())"
#(8, 6)
tar xzvf DeepSpeed-0.10.0.tar.zip
cd DeepSpeed-0.10.0
rm -rf build
wget -c https://github.com/Kitware/ninja/archive/v1.11.1.g95dee.kitware.jobserver-1.tar.gz
pip install psutil
TORCH_CUDA_ARCH_LIST="8.6" DS_BUILD_CPU_ADAM=1 DS_BUILD_UTILS=1 pip install . \
--global-option="build_ext" --global-option="-j8" --no-cache -v \
--disable-pip-version-check 2>&1 | tee build.log

export CUDA_VISIBLE_DEVICES="0"
deepspeed test.py --deepspeed_config config.json
deepspeed --hostfile=/data0/shouxieai/deepspeed/hostfile  --include="dtpct:0@mdubu:0"  test.py --deepspeed_config=config.json

#设置免密
git clone https://github.com/microsoft/DeepSpeedExamples.git
cd DeepSpeedExamples-master/training/pipeline_parallelism
# 单卡训练任务
#./run.sh
deepspeed train.py --deepspeed_config=ds_config.json -p 1 --steps=200
# 多卡训练任务
# 创建hostfile指定所有gpu资源，填写host的相应gpu数量（slots=4代表有4个gpu）
# host1 slots=4
# host2 slots=4
# 执行训练任务,通过include参数指定本次训练用到的gpu资源
deepspeed --hostfile=/data0/shouxieai/deepspeed/hostfile  --include="dtpct:0@mdubu:0"  train.py -p 2 --steps=200  --deepspeed_config=ds_config.json
