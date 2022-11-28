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
drvrev=515.57
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
https://developer.nvidia.com/cuda-11-2-2-download-archive
#下载cudnn
wget -c https://developer.download.nvidia.com/compute/cuda/11.2.2/local_installers/cuda_11.2.2_460.32.03_linux.run
chmod a+x cuda_11.2.2_460.32.03_linux.run
#ncurses图形界面安装，逐个主机
sh cuda_11.2.2_460.32.03_linux.run
#会安装460.32.03版驱动覆盖原来驱动，要取消
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
echo "export PATH=\$PATH:/usr/local/cuda-11.2/bin" >> /root/.bashrc
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/cuda-11.2/lib64" >> /root/.bashrc
tail -4 /root/.bashrc
head -5 /usr/local/cuda/version.json
#重新登陆终端
nvcc -V
cat /proc/driver/nvidia/version
nvidia-smi
#如果无显示，重新安装driver
nvidia-smi
cudapath=/usr/local/cuda
#卸载cuda
nvidia-uninstall
cuda-uninstaller
#安装cudnn
tar -xzvf cudnn-11.2-linux-x64-v8.1.1.33.tgz
cp -r /usr/local/cuda/include /usr/local/cuda/include.bk4-cudnn-setup
cp cuda/include/cudnn*.h /usr/local/cuda/include
cp -r /usr/local/cuda/lib64 /usr/local/cuda/lib64.bk4-cudnn-setup
cp -P cuda/lib64/libcudnn* /usr/local/cuda/lib64
chmod a+r /usr/local/cuda/include/cudnn*.h /usr/local/cuda/lib64/libcudnn*

#安装python 3.7

#miniconda
