ansible nvidia -m shell -a""

#参考这篇文章
#https://blog.csdn.net/shiner_chen/article/details/125857553

#centos
yum install -y pciutils lshw

lspci | grep VGA
#根据product id 查询
# 3050
# http://pci-ids.ucw.cz/read/PC/10de/2507
# 3060
# http://pci-ids.ucw.cz/read/PC/10de/2487
lshw -numeric -C display

#centos
yum -y install https://www.elrepo.org/elrepo-release-7.0-4.el7.elrepo.noarch.rpm
yum install nvidia-detect -y
#检测显卡驱动
nvidia-detect -v
#This device requires the current 515.57 NVIDIA driver kmod-nvidia
#This device requires the current 525.85.05 NVIDIA driver kmod-nvidia
#drvrev=515.57
drvrev=525.85.05
:<<EOF
英伟达显卡算力
CUDA Toolkit	Toolkit Driver Version Linux()
CUDA 11.7 Update 1	>=515.65.01
CUDA 11.7 GA	>=515.43.04
EOF
#这个版本驱动可以支持cuda 11.7 GA
#cuda高版本是向下兼容的，驱动支持cuda高版本也支持高版以下的低版本
#卸载
yum remove nvidia-detect -y

lsmod | grep nouveau
#禁用nouveau
file=/lib/modprobe.d/dist-blacklist.conf
cp ${file} ${file}.bk
ansible nvidia -m shell -a"cat << \EOF >> ${file}
# disable nouveau for nvida driver
blacklist nouveau
options nouveau modeset=0
EOF
"
mv /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r).img.bak
dracut -v /boot/initramfs-$(uname -r).img $(uname -r)
sync;reboot now
lsmod | grep nouveau

ls
#编译工具devtoolset gcc/gcc-c++/make, tar已安装
yum install -y gcc gcc-c++ make
gcc -v
yum install -y kernel-devel-$(uname -r) kernel-headers-$(uname -r)
rpm -qa|grep kernel

ansible nvidia -m copy -a"src= dest=/root/"

#下载驱动
#！！！要根据detect结果在nvidia网站搜索下载完全符合的版本，以下网页下载的最新版本装上cuda以后nvidia-smi死机
:<<EOF
英伟达显卡算力
CUDA Toolkit	Toolkit Driver Version Linux()
CUDA 11.7 Update 1	>=515.65.01
CUDA 11.7 GA	>=515.43.04
CUDA 11.6 Update 2	>=510.47.03
CUDA 11.6 Update 1	>=510.47.03
CUDA 11.6 GA	>=510.39.01
CUDA 11.5 Update 2	>=495.29.05
CUDA 11.5 Update 1	>=495.29.05
CUDA 11.5 GA	>=495.29.05
CUDA 11.4 Update 4	>=470.82.01
CUDA 11.4 Update 3	>=470.82.01
CUDA 11.4 Update 2	>=470.57.02
CUDA 11.4 Update 1	>=470.57.02
CUDA 11.4.0 GA	>=470.42.01
CUDA 11.3.1 Update 1	>=465.19.01
CUDA 11.3.0 GA	>=465.19.01
CUDA 11.2.2 Update 2	>=460.32.03
CUDA 11.2.1 Update 1	>=460.32.03
CUDA 11.2.0 GA	>=460.27.03
CUDA 11.1.1 Update 1	>=455.32
CUDA 11.1 GA	>=455.23
CUDA 11.0.3 Update 1	>= 450.51.06
CUDA 11.0.2 GA	>= 450.51.05
CUDA 11.0.1 RC	>= 450.36.06
CUDA 10.2.89	>= 440.33
CUDA 10.1 (10.1.105 general release, and updates)	>= 418.39
CUDA 10.0.130	>= 410.48
CUDA 9.2 (9.2.148 Update 1)	>= 396.37
CUDA 9.2 (9.2.88)	>= 396.26
CUDA 9.1 (9.1.85)	>= 390.46
CUDA 9.0 (9.0.76)	>= 384.81
EOF
#https://www.nvidia.cn/Download/index.aspx?lang=cn
#drvrev=515.76
drvrev=525.85.05
chmod a+x NVIDIA-Linux-x86_64-${drvrev}.run
#ncurses图形界面安装，逐个主机，可以用--ui=none转命令行，用expect自动化
./NVIDIA-Linux-x86_64-${drvrev}.run
#Install NVIDIA's 32-bit compatibility libraries?
#no
nvidia-smi
#卸载nvidia驱动
sh NVIDIA-Linux-x86_64-515.76.run --uninstall


#！！！
#cuda/cudnn版本关键看tf的版本配套，pytorch自带cuda包，不需要手工安装的cuda一致，只需要nvidia驱动能够向上兼容pytorch要求的cuda版本
#安装cuda
:<<EOF
tensorflow
https://tensorflow.google.cn/install/source_windows?hl=en#gpu
Version	Python version	Compiler	Build tools	cuDNN	CUDA
----------------------------------------------------------------
tensorflow_gpu-2.10.0	3.7-3.10	MSVC 2019	Bazel 5.1.1	8.1	11.2
tensorflow_gpu-2.9.0	3.7-3.10	MSVC 2019	Bazel 5.0.0	8.1	11.2
tensorflow_gpu-2.8.0	3.7-3.10	MSVC 2019	Bazel 4.2.1	8.1	11.2
tensorflow_gpu-2.7.0	3.7-3.9	MSVC 2019	Bazel 3.7.2	8.1	11.2
tensorflow_gpu-2.6.0	3.6-3.9	MSVC 2019	Bazel 3.7.2	8.1	11.2
tensorflow_gpu-2.5.0	3.6-3.9	MSVC 2019	Bazel 3.7.2	8.1	11.2
tensorflow_gpu-2.4.0	3.6-3.8	MSVC 2019	Bazel 3.1.0	8.0	11.0
tensorflow_gpu-2.3.0	3.5-3.8	MSVC 2019	Bazel 3.1.0	7.6	10.1
tensorflow_gpu-2.2.0	3.5-3.8	MSVC 2019	Bazel 2.0.0	7.6	10.1
tensorflow_gpu-2.1.0	3.5-3.7	MSVC 2019	Bazel 0.27.1-0.29.1	7.6	10.1
tensorflow_gpu-2.0.0	3.5-3.7	MSVC 2017	Bazel 0.26.1	7.4	10
https://pytorch.org/get-started/previous-versions/
pytorch CUDA9.2 CUDA10.0 CUDA10.1 CUDA10.2 CUDA11.3 CUDA11.6
---------------------------------------------------
v1.12.1                           y        y        y
v1.12.0                           y        y        y
v1.11.0                           y        y
v1.10.1                           y        y
v1.10.0                           y        y
v1.9.1                            y        y
v1.9.0                            y        y
v1.8.1                            y        y
v1.8.0                            y        y
v1.7.1   y               y        y        y
v1.7.0   y               y        y        y
v1.6.0   y               y        y
v1.5.1   y               y        y
v1.5.0   y               y        y
v1.4.0   y               y
v1.2.0   y       y
v1.1.0   y       y
EOF

#下载cuda
https://developer.nvidia.com/cuda-toolkit-archive
https://developer.nvidia.com/cuda-11-2-2-download-archive
#下载cudnn
#wget -c https://developer.download.nvidia.com/compute/cuda/11.2.2/local_installers/cuda_11.2.2_460.32.03_linux.run
#wget -c https://developer.download.nvidia.com/compute/cuda/11.3.1/local_installers/cuda_11.3.1_465.19.01_linux.run 
wget -c https://developer.download.nvidia.com/compute/cuda/11.6.2/local_installers/cuda_11.6.2_510.47.03_linux.run
#训练pytorch的LSTM是，提示但是下载不到cu113对应的8.3.2的cudnn，升级到cu116后不再提示错误，RuntimeError: cuDNN version incompatibility: PyTorch was compiled against (8, 3, 2) but linked against (8, 2, 1)
#chmod a+x cuda_11.2.2_460.32.03_linux.run
#chmod a+x cuda_11.3.1_465.19.01_linux.run
chmod a+x cuda_11.6.2_510.47.03_linux.run
#卸载旧版本
#ncurses图形界面卸载，逐个主机
cd /usr/local/cuda
bin/cuda-uninstaller 
cd
#ncurses图形界面安装，逐个主机
#sh cuda_11.2.2_460.32.03_linux.run
#sh cuda_11.3.1_465.19.01_linux.run
sh cuda_11.6.2_510.47.03_linux.run
#会安装460.32.03版驱动覆盖原来驱动，要取消，其他都保持选择尤其是Toolkit/Samples，CUDA编程需要
:<<EOF
 CUDA Installer                                                               │
│ - [ ] Driver                                                                 │
│      [ ] 460.32.03

===========
= Summary =
===========

Driver:   Installed
Toolkit:  Installed in /usr/local/cuda-11.2/
Samples:  Installed in /root/, but missing recommended libraries

Please make sure that
 -   PATH includes /usr/local/cuda-11.2/bin
 -   LD_LIBRARY_PATH includes /usr/local/cuda-11.2/lib64, or, add /usr/local/cuda-11.2/lib64 to /etc/ld.so.conf and run ldconfig as root

To uninstall the CUDA Toolkit, run cuda-uninstaller in /usr/local/cuda-11.2/bin
To uninstall the NVIDIA Driver, run nvidia-uninstall
Logfile is /var/log/cuda-installer.log
EOF
echo "export PATH=\$PATH:/usr/local/cuda/bin" >> /root/.bashrc
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/cuda/lib64" >> /root/.bashrc
tail -4 /root/.bashrc
head -5 /usr/local/cuda/version.json
#重新登陆终端
nvcc -V
cat /proc/driver/nvidia/version
nvidia-smi
#如果无显示，重新安装driver
nvidia-smi
cudapath=/usr/local/cuda
ls -l /usr/local
cd /usr/local/cuda
#卸载一起安装的driver
#./nvidia-uninstall
#卸载cuda
./cuda-uninstaller
#下载cudnn
#https://developer.nvidia.com/rdp/cudnn-archive
#选择cuDNN Libarary for Linux(x86_64)版本
#wget -c https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.2.1.32/11.3_06072021/cudnn-11.3-linux-x64-v8.2.1.32.tgz
#Download cuDNN v8.6.0 (October 3rd, 2022), for CUDA 11.x
#安装cudnn
#tar -xzvf cudnn-11.2-linux-x64-v8.1.1.33.tgz
#tar -xzvf cudnn-11.3-linux-x64-v8.2.1.32.tgz
xz -d cudnn-linux-x86_64-8.6.0.163_cuda11-archive.tar.xz
tar -xvf cudnn-linux-x86_64-8.6.0.163_cuda11-archive.tar
ln -s cudnn-linux-x86_64-8.6.0.163_cuda11-archive cuda
mv cuda/lib cuda/lib64
#cp -r /usr/local/cuda/include /usr/local/cuda/include.bk4-cudnn-setup
\cp cuda/include/cudnn*.h /usr/local/cuda/include
#cp -r /usr/local/cuda/lib64 /usr/local/cuda/lib64.bk4-cudnn-setup
\cp -P cuda/lib64/libcudnn* /usr/local/cuda/lib64
chmod a+r /usr/local/cuda/include/cudnn*.h /usr/local/cuda/lib64/libcudnn*
#occupancy计算器
sudo scp dtpct:/usr/local/cuda/tools/CUDA_Occupancy_Calculator.xls ./
sudo chown apple:wheel CUDA_Occupancy_Calculator.xls
#java应该mac不给运行
sudo spctl --master-disable
#sudo spctl --master-enable
#mac上运行nvvp.dmp安装包，把nvvp目录拉或者copy到安装位置
wget -c https://cdn.azul.com/zulu/bin/zulu8.23.0.3-jdk8.0.144-macosx_x64.zip
#/Volumes/data/nvvp/bin/nvvp -vm /Library/Java/JavaVirtualMachines/jdk1.8.0_351.jdk/Contents/Home/bin/java
#oracle dmg安装的vm，nvvp启动图形界面没法点击都是灰的
cd /Volumes/data/
unzip ~/dl/zulu8.23.0.3-jdk8.0.144-macosx_x64.zip
ln -s zulu8.23.0.3-jdk8.0.144-macosx_x64 zulu8
/Volumes/data/nvvp/bin/nvvp -vm /Volumes/data/zulu8/bin/java
#arch 8.0以上不支持，只能用nsight system/compute

#11.6版本之前的CUDA安装时会附带安装CUDA Samples
#11.6版本之后安装脚本选了samples也不会安装
cd /usr/local/cuda/samples
:<<EOF
git clone https://github.com/nvidia/cuda-samples
#最新版本无法直接编译
cp -r cuda-samples cuda-samples.bk
find . -name "Makefile"|xargs grep " 89 90"
find . -name "Makefile"|xargs sed -i 's/ 89 90//g'
find . -name "Makefile"|xargs grep " 89 90"
#helper头文件可以使用，但是最新版本samples无法在11.6上编译
EOF
wget -c https://github.com/nvidia/release/download/cuda-samples-11.6.tar.gz
tar xzvf cuda-samples-11.6.tar.gz
cd cuda-samples
make

yum install perl-Env -y
sh NsightSystems-linux-public-2023.3.1.92-3314722.run
ln -s /opt/nvidia/nsight-systems/2023.3.1 /opt/nvidia/nsight-systems/systems
#/opt/nvidia/nsight-systems/2023.3.1
#/opt/nvidia/nsight-systems/systems
echo "export PATH=/opt/nvidia/nsight-systems/systems/bin:\$PATH" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/opt/nvidia/nsight-systems/systems/target-linux-x64" >> ~/.bashrc
sh nsight-compute-linux-2023.2.1.3-33050884.run
#/usr/local/NVIDIA-Nsight-Compute-2023.2
#/usr/local/NVIDIA-Nsight-Compute
echo "export PATH=/usr/local/NVIDIA-Nsight-Compute:\$PATH" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/NVIDIA-Nsight-Compute/target/linux-desktop-glibc_2_11_3-x64" >> ~/.bashrc
#for tensorflow
pip install nvtx-plugins
:<<EOF
      /opt/rh/devtoolset-10/root/usr/bin/gcc -Wno-unused-result -Wsign-compare -O2 -Wall -fPIC -O2 -isystem /data0/envs/deepspeed/include -I/data0/envs/deepspeed/include -fPIC -O2 -isystem /data0/envs/deepspeed/include -fPIC -DHAVE_CUDA=1 -UNDEBUG -I/usr/local/cuda/include -I/data0/envs/deepspeed/include/python3.9 -c nvtx_plugins/cc/nvtx_kernels.cc -o build/temp.linux-x86_64-cpython-39/nvtx_plugins/cc/nvtx_kernels.o -std=c++11 -fPIC -O2 -Wall -I/data0/envs/deepspeed/lib/python3.9/site-packages/tensorflow/include -D_GLIBCXX_USE_CXX11_ABI=0 -DEIGEN_MAX_ALIGN_BYTES=64 -lnvToolsExt
      In file included from /data0/envs/deepspeed/lib/python3.9/site-packages/tensorflow/include/tensorflow/core/framework/tensor.h:25,
                       from /data0/envs/deepspeed/lib/python3.9/site-packages/tensorflow/include/tensorflow/core/framework/device_base.h:26,
                       from /data0/envs/deepspeed/lib/python3.9/site-packages/tensorflow/include/tensorflow/core/framework/op_kernel.h:29,
                       from nvtx_plugins/cc/nvtx_kernels.cc:19:
      /data0/envs/deepspeed/lib/python3.9/site-packages/tensorflow/include/tensorflow/core/framework/tensor_types.h: In member function ‘void tensorflow::internal::MaybeWith32BitIndexingImpl<Eigen::GpuDevice>::operator()(Func, Args&& ...) const’:
      /data0/envs/deepspeed/lib/python3.9/site-packages/tensorflow/include/tensorflow/core/framework/tensor_types.h:176:25: error: use of ‘auto’ in lambda parameter declaration only available with ‘-std=c++14’ or ‘-std=gnu++14’
...      
       distutils.errors.CompileError: command '/opt/rh/devtoolset-10/root/usr/bin/gcc' failed with exit code 1
EOF
#/data0/shouxiecuda
nsys profile --stats=true master_warp_divergency.out
#/data0/examples/mnist
nsys profile -t cuda,osrt,nvtx -o baseline -w true python main.py

#cuda自带opencv的c++开发以来opengl
yum install mesa-libGL-devel mesa-libGLU-devel freeglut-devel

#openacc
wget -c https://developer.download.nvidia.com/hpc-sdk/23.7/nvhpc_2023_237_Linux_x86_64_cuda_multi.tar.gz
tar xpzf nvhpc_2023_237_Linux_x86_64_cuda_multi.tar.gz
nvhpc_2023_237_Linux_x86_64_cuda_multi/install
echo "export PATH=/opt/nvidia/hpc_sdk/Linux_x86_64/23.7/compilers/bin:/opt/nvidia/hpc_sdk/Linux_x86_64/23.7/comm_libs/mpi/bin:\$PATH" >> ~/.bashrc
echo "export MANPATH=\$MANPATH:/opt/nvidia/hpc_sdk/Linux_x86_64/23.7/comm_libs/mpi/man" >> ~/.bashrc


distribution=$(. /etc/os-release;echo $ID$VERSION_ID) && \
curl -s -L https://nvidia.github.io/nvidia-container-runtime/$distribution/nvidia-container-runtime.repo | \
 tee /etc/yum.repos.d/nvidia-container-runtime.repo
yum -y install nvidia-container-runtime
which nvidia-container-runtime
    /bin/nvidia-container-runtime
:<<EOF
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.repo | \
 tee /etc/yum.repos.d/nvidia-docker.repo
yum -y install nvidia-container-toolkit --nogpgcheck
EOF
which nvidia-container-toolkit

#https://github.com/NVIDIA/k8s-device-plugin/blob/main/nvidia-device-plugin.yml
cat << \EOF > nvidia-device-plugin.yml
# Copyright (c) 2019, NVIDIA CORPORATION.  All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: nvidia-device-plugin-daemonset
  namespace: kube-system
spec:
  selector:
    matchLabels:
      name: nvidia-device-plugin-ds
  updateStrategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        name: nvidia-device-plugin-ds
    spec:
      tolerations:
      - key: nvidia.com/gpu
        operator: Exists
        effect: NoSchedule
      # Mark this pod as a critical add-on; when enabled, the critical add-on
      # scheduler reserves resources for critical add-on pods so that they can
      # be rescheduled after a failure.
      # See https://kubernetes.io/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/
      priorityClassName: "system-node-critical"
      containers:
      - image: nvcr.io/nvidia/k8s-device-plugin:v0.14.0
        name: nvidia-device-plugin-ctr
        env:
          - name: FAIL_ON_INIT_ERROR
            value: "false"
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop: ["ALL"]
        volumeMounts:
        - name: device-plugin
          mountPath: /var/lib/kubelet/device-plugins
      volumes:
      - name: device-plugin
        hostPath:
          path: /var/lib/kubelet/device-plugins
EOF
kubectl apply -f nvidia-device-plugin.yml

kubectl delete -f nvidia-device-plugin.yml

#安装tensorRT
#https://developer.nvidia.com/nvidia-tensorrt-8x-download
#https://developer.nvidia.com/nvidia-tensorrt-8x-download#:~:text=TensorRT%208.6%20GA%20for%20Linux%20x86_64%20and%20CUDA%2011.0%2C%2011.1%2C%2011.2%2C%2011.3%2C%2011.4%2C%2011.5%2C%2011.6%2C%2011.7%20and%2011.8%20TAR%20Package
TensorRT-8.6.1.6.Linux.x86_64-gnu.cuda-11.8.tar.gz
#cp to nvidia cp
tar xzvf TensorRT-8.6.1.6.Linux.x86_64-gnu.cuda-11.8.tar.gz
ln -s TensorRT-8.6.1.6 trt
rm -f /data0/TensorRT-8.6.1.6.Linux.x86_64-gnu.cuda-11.8.tar.gz
echo 'export TENSORRT_DIR=/root/trt' >> /root/.bashrc
echo 'export PATH=\$PATH:\$TENSORRT_DIR/bin' >> /root/.bashrc
echo 'export LD_LIBRARY_PATH=\$TENSORRT_DIR/lib:\$LD_LIBRARY_PATH' >> /root/.bashrc
pip3 install /data0/TensorRT-8.6.1.6/python/tensorrt-8.6.1-cp39-none-linux_x86_64.whl
pip install datasets
pip install evaluate
pip install colored polygraphy --extra-index-url https://pypi.ngc.nvidia.com
pip install calibrator --extra-index-url https://pypi.ngc.nvidia.com
pip install nvidia-pyindex
pip install onnx-graphsurgeon
pip install pytorch-quantization 
#安装tensorRT c++编译环境
yum install -y epel-release centos-release-scl scl-utils
yum install -y devtoolset-10
scl enable devtoolset-10 bash
echo "source scl_source enable devtoolset-10" >> /root/.bashrc
#python setup.py develop
#https://cmake.org/files
unzip cmake-3.24.4.zip
cd cmake-3.24.4
yum install -y openssl openssl-devel
./bootstrap --prefix=/usr/local --datadir=share/cmake --docdir=doc/cmake && make && make install
echo 'export PATH=/usr/local/bin:$PATH' >> /root/.bashrc
cmake --version
yum install -y rsync


#在centos上编译失败，因为re2和absl的版本配套关系（re2似乎是Protobuf需要）总是失败，这2个都调整到2023年初的版本后解决
#triton
#git clone https://github.com/Microsoft/vcpkg.git
#cd vcpkg
#./bootstrap-vcpkg.sh
#echo "export PATH=\$PATH:/data0/vcpkg" >> ~/.bashrc
#./vcpkg integrate install
#vcpkg install rapidjson
git clone https://github.com/Tencent/rapidjson.git
cd rapidjson
mkdir build
cd build
cmake ..
make install
boost_version=1.83.0
boost_version_file=1_83_0
wget -c https://boostorg.jfrog.io/artifactory/main/release/${boost_version}/source/boost_${boost_version_file}.tar.gz
tar xzvf boost_${boost_version_file}.tar.gz
cd boost_${boost_version_file}
./bootstrap
./b2
./b2 install  
absl_version=20230125.3
wget -c https://github.com/abseil/abseil-cpp/archive/refs/tags/${absl_version}.tar.gz
tar xzvf abseil-cpp-${absl_version}.tar.gz
cd abseil-cpp-${absl_version}
mkdir build
cd build
cmake ..
make install
:<<EOF
rm -f /usr/local/lib64/pkgconfig/libabsl_*
rm -f /usr/local/lib64/pkgconfig/absl_*
rm -rf /usr/local/include/absl
rm -rf /usr/local/lib64/cmake/absl
EOF
re2_version=2023-02-01
https://github.com/google/re2/archive/refs/tags/${re2_version}.tar.gz
tar xzvf re2-${re2_version}.tar.gz
cd re2-${re2_version}
mkdir build
cd build
cmake ..
make install
:<<EOF
rm -f /usr/local/lib64/libre2.a
rm -f /usr/local/lib64/pkgconfig/re2.pc
rm -rf /usr/local/include/re2
rm -rf /usr/local/lib64/cmake/re2
EOF
#yum install re2-devel
#只有.so没有.a，还是没法编译triton
dnf install dnf-plugin-config-manager -y
dnf config-manager \
    --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo
dnf clean expire-cache \
    && dnf install -y datacenter-gpu-manager
yum install numactl-devel*x86_64 -y
git clone https://github.com/BuLogics/libb64.git
cd libb64
cp -r include/b64 /usr/local/include/
cd src
make
cp libb64.a /usr/local/lib/
:<<EOF
rm -f /usr/local/lib/libb64.a
rm -rf /usr/local/include/b64
EOF
triton_version=2.39.0
wget -c https://github.com/triton-inference-server/server/archive/refs/tags/v${triton_version}.tar.gz
tar xzvf server-${triton_version}.tar.gz
cd server-${triton_version}
#git clone --recursive https://github.com/triton-inference-server/server.git
#cd server
#mkdir build
#cd build
#cmake -DCMAKE_INSTALL_PREFIX:PATH=/data0/triton ..
#cmake -DCMAKE_INSTALL_PREFIX:PATH=`pwd`/install -DRapidJSON_DIR=/data0/rapidjson ..
#make install
./build.py -v --no-container-build --build-dir=/data0/triton --enable-all
#

git clone --recursive https://github.com/triton-inference-server/backends.git
cd backends
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX:PATH=/data0/triton ..
make install
cd examples/backends
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX:PATH=/data0/triton ..
make install
#

git clone --recursive https://github.com/triton-inference-server/client.git
cd client
mkdir build
cd build
file=/data0/client/src/c++/perf_analyzer/client_backend/torchserve/../../client_backend/client_backend.h
cp ${file} ${file}.bk
sed -i "/#include <vector>/a\#include <unordered_map>" ${file}
#sourceforge/github上下载的libb64都是需要手工copy的include/b64和libb64.a，编译时会提示BUFFERSIZE常量未定义错误
wget -c http://www6.atomicorp.com/channels/atomic/centos/7/x86_64/RPMS/libb64-libs-1.2.1-2.1.el7.art.x86_64.rpm
rpm -Uvh libb64-libs-1.2.1-2.1.el7.art.x86_64.rpm
wget -c http://www6.atomicorp.com/channels/atomic/centos/7/x86_64/RPMS/libb64-1.2.1-2.1.el7.art.x86_64.rpm
rpm -Uvh libb64-1.2.1-2.1.el7.art.x86_64.rpm
wget -c http://www6.atomicorp.com/channels/atomic/centos/7/x86_64/RPMS/libb64-devel-1.2.1-2.1.el7.art.x86_64.rpm
rpm -Uvh libb64-devel-1.2.1-2.1.el7.art.x86_64.rpm
file=/data0/client/src/c++/CMakeLists.txt
cp ${file} ${file}.bk
sed -i '/project(cc-clients LANGUAGES C CXX)/a\set(CMAKE_CXX_STANDARD 17)' ${file}
pip install grpcio
pip install grpcio-tools
echo "export PATH=\$PATH:/data0/maven/bin" >> ~/.bashrc
make cc-clients python-clients java-clients
#

yum install libarchive-devel -y
onnxruntime_version=1.16.1
wget -c https://github.com/microsoft/onnxruntime/releases/download/v${onnxruntime_version}/onnxruntime-linux-x64-gpu-${onnxruntime_version}.tgz
tar xzvf onnxruntime-linux-x64-gpu-${onnxruntime_version}.tgz
ln -s onnxruntime-linux-x64-gpu-${onnxruntime_version} onnxruntime
arr=(python pytorch tensorrt onnxruntime openvino tensorflow stateful)
for be in ${arr[*]}
do
  echo "DEBUG >>>>>> be:${be}"
  bename=${be}_backend
  echo "DEBUG >>>>>> bename:${bename}"
  git clone --recursive https://github.com/triton-inference-server/${bename}.git
  cd ${bename}
  mkdir build
  cd build
  if [[ "${be}" == "python" ]]; then
    cmake -DTRITON_ENABLE_GPU=ON \
    -DTRITON_BACKEND_REPO_TAG=r23.10 \
    -DTRITON_COMMON_REPO_TAG=r23.10 \
    -DTRITON_CORE_REPO_TAG=r23.10 \
    -DCMAKE_INSTALL_PREFIX:PATH=/data/triton \
     ..
  fi
  #done

  if [[ "${be}" == "pytorch" ]]; then
    yum install -y patchelf
    file=../CMakeLists.txt
    cp ${file} ${file}.bk
    sed -i "s/cxx_std_11/cxx_std_17/g" ${file}
    cmake -DCMAKE_INSTALL_PREFIX:PATH=/data0/triton -DTRITON_PYTORCH_DOCKER_IMAGE="nvcr.io/nvidia/pytorch:23.10-py3" ..
    #cmake -DCMAKE_INSTALL_PREFIX:PATH=/data0/triton -DTRITON_PYTORCH_INCLUDE_PATHS="<PATH_PREFIX>/torch;<PATH_PREFIX>/torch/torch/csrc/api/include;<PATH_PREFIX>/torchvision" -DTRITON_PYTORCH_LIB_PATHS="<LIB_PATH_PREFIX>" ..
  fi
  #done

  if [[ "${be}" == "tensorrt" ]]; then
    file=../CMakeLists.txt
    cp ${file} ${file}.bk
    #sed -i "s/c++11/c++17/g" ${file}
    sed -i "s/ -Werror//g" ${file}
    cmake -DCMAKE_INSTALL_PREFIX:PATH=/data0/triton -DTRITON_ENABLE_CC_HTTP=ON -DTRITON_ENABLE_CC_GRPC=ON -DTRITON_ENABLE_PERF_ANALYZER=ON -DTRITON_ENABLE_PERF_ANALYZER_C_API=ON -DTRITON_ENABLE_PERF_ANALYZER_TFS=ON -DTRITON_ENABLE_PERF_ANALYZER_TS=ON -DTRITON_ENABLE_PYTHON_HTTP=ON -DTRITON_ENABLE_PYTHON_GRPC=ON -DTRITON_ENABLE_JAVA_HTTP=ON -DTRITON_ENABLE_GPU=ON -DTRITON_ENABLE_EXAMPLES=ON -DTRITON_ENABLE_TESTS=ON \
    -DTRITON_TENSORRT_LIB_PATHS=/data0/trt/lib \
    -DTRITON_TENSORRT_INCLUDE_PATHS=/data0/trt/include \
    -DNVINFER_LIBRARY=/data0/trt/lib/libnvinfer_static.a \
    -DNVINFER_PLUGIN_LIBRARY=/data0/trt/lib/libnvinfer_plugin_static.a \
    ..
  fi
  #done

  if [[ "${be}" == "onnxruntime" ]]; then
    cmake -DCMAKE_INSTALL_PREFIX:PATH=/data0/triton -DTRITON_ENABLE_ONNXRUNTIME_TENSORRT=ON -DTRITON_ENABLE_ONNXRUNTIME_OPENVINO=ON \
    -DTRITON_BUILD_ONNXRUNTIME_VERSION=1.16.0 \
    -DTRITON_BUILD_CONTAINER_VERSION=23.10 \
    -DTRITON_BUILD_ONNXRUNTIME_OPENVINO_VERSION=2023.0.0 \
    -DCUDA_SDK_ROOT_DIR=/usr/local/cuda \
    -DTRITON_ONNXRUNTIME_INCLUDE_PATHS=/data0/onnxruntime/include \
    -DTRITON_ONNXRUNTIME_LIB_PATHS=/data0/onnxruntime/lib \
    -DOV_LIBRARY=/data0/openvino/runtime/lib/intel64 \
    -DTRITON_BUILD_CONTAINER=OFF \
    ..
  fi
  #done

  if [[ "${be}" == "openvino" ]]; then
    cmake -DCMAKE_INSTALL_PREFIX:PATH=/data0/triton \
    -DTRITON_BUILD_CONTAINER_VERSION=23.10 \
    -DTRITON_BUILD_OPENVINO_VERSION=2023.0.0 \
    ..
  fi
  #make install

  if [[ "${be}" == "tensorflow" ]]; then
    cmake -DCMAKE_INSTALL_PREFIX:PATH=/data0/triton -DTRITON_TENSORFLOW_DOCKER_IMAGE="nvcr.io/nvidia/tensorflow:23.10-tf2-py3" ..
  fi
  #done

  if [[ "${be}" == "stateful" ]]; then
    cd ..
    file=NGC_VERSION
    cp ${file} ${file}.bk
    echo "23.10" > ${file}
    python3 ./build.py
  fi
  #

  if [[ "${be}" != "stateful" ]]; then
    make install
    cd ../../
  fi
done
ln -s /data0/triton /opt/triton
echo "export PATH=\$PATH:/opt/triton/bin" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/opt/triton/lib64" >> ~/.bashrc


#安装python 3.7

#miniconda
