
yum install -y devtoolset-10
scl enable devtoolset-10 bash
echo "source scl_source enable devtoolset-10" >> /root/.bashrc
yum install -y devtoolset-11
scl enable devtoolset-11 bash
echo "source scl_source enable devtoolset-11" >> /root/.bashrc

:<<EOF
wget -c https://cmake.org/files/v3.22/cmake-3.22.1.tar.gz
tar -zxvf cmake-3.22.1.tar.gz
cd cmake-3.22.1
yum install -y sudo
./bootstrap && make -j4 && sudo make install
cd ..
rm -rf cmake*
cmake_short_version=3.24
cmake_version=3.24.4
cmake_short_version=3.27
cmake_version=3.27.6
EOF
cmake_short_version=3.26
cmake_version=3.26.5
wget -c https://cmake.org/files/v${cmake_short_version}/cmake-${cmake_version}-linux-x86_64.tar.gz
tar xzvf cmake-${cmake_version}-linux-x86_64.tar.gz
ln -s /root/cmake-${cmake_version}-linux-x86_64/bin/* /usr/bin
cmake -version

yum install -y automake autoconf libtool

yum -y install epel-release

yum localinstall -y –nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm 
yum localinstall -y –nogpgcheck https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-7.noarch.rpm 
rpm –import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro 
rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-1.el7.nux.noarch.rpm

yum install -y gtk+-devel gimp-devel gimp-devel-tools gimp-help-browser zlib-devel libtiff-devel libjpeg-devel libpng-devel gstreamer-devel libavc1394-devel libraw1394-devel libdc1394-devel jasper-devel jasper-utils swig python libtool nasm libv4l-devel libv4l-devel  python-devel numpy gstreamer-plugins-base-devel gtk2-devel gtk2-devel-docs  libavcodec-devel libavformat-devel libswscale-devel libavutil-devel  libeigen3-devel libtbb-devel libtiff-dev libavformat-devel libpq-devel  libxine2-devel libglew-devel libtiff5-devel gstreamer-plugins-base-devel libjpeg-turbo-devel jasper-devel openexr-devel tbb-devel 

VTK_short_version=9.3
VTK_version=9.3.0.rc1
wget -c https://www.vtk.org/files/release/${VTK_short_version}/VTK-${VTK_version}.tar.gz
wget -c https://www.vtk.org/files/release/${VTK_short_version}/VTKData-${VTK_version}.tar.gz
tar xzvf VTK-${VTK_version}.tar.gz
tar xzvf VTKData-${VTK_version}.tar.gz
cd VTK-${VTK_version}
mkdir build
cd build
ccmake ..
:<EOF
    # 按照VTK tutorial要求，每设置完一项均按'c'进行一次configuration，直到所有项目设置完，     
    BUILD_SHARED_LIBS = ON        
    BUILD_TESTING = ON    # 默认OFF，如果打开的话，编译时会由于下载测试数据所用url过旧而报错，建议OFF     
    CMAKE_BUILD_TYPE = Release    # 默认Debug运行会较慢     
    CMAKE_INSTALL_PREFIX = /usr/local    # 这里用默认就行，或者改到想要安装的位置     
    # 以下为高级设置，需先在命令行按't'才可见
    VTK_FORBID_DOWNLOADS = ON    # 默认OFF，建议打开，否则编译会报错，理由同BUILD_TESTING    
    # 此时应已经出现'g' generating 的按键选项，按 'g' 即完成配置.
！！！多configure几次才会
EOF
cmake .
make && make install

eigen_version=3.3.9
wget -c https://gitlab.com/libeigen/eigen/-/archive/${eigen_version}/eigen-${eigen_version}.tar.gz
tar xzvf eigen-${eigen_version}.tar.gz
mkdir eigen-${eigen_version}/build && cd eigen-${eigen_version}/build
cmake ..
make install

leptonica_version=1.83.0
wget -c http://www.leptonica.org/source/leptonica-${leptonica_version}.tar.gz
tar -xvf leptonica-${leptonica_version}.tar.gz  
cd leptonica-${leptonica_version}
./configure && make && make install
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/lib" >> ~/.bashrc
echo "export LIBLEPT_HEADERSDIR=/usr/local/include" >> ~/.bashrc
echo "export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig" >> ~/.bashrc

tesseract_version=5.3.2
wget -c https://github.com/tesseract-ocr/tesseract/archive/refs/tags/${tesseract_version}.tar.gz
tar xzvf tesseract-${tesseract_version}.tar.gz
cd tesseract-${tesseract_version}
./autogen.sh
./configure --with-extra-includes=/usr/local/include --with-extra-libraries=/usr/local/lib
make && make install


yum install -y ccache

yum install -y http://repo.okay.com.mx/centos/7/x86_64/release/okay-release-1-1.noarch.rpm
yum install -y glog

gflags_version=2.2.2
wget -c https://github.com/gflags/gflags/archive/v${gflags_version}.tar.gz -O gflags-${gflags_version}.tar.gz  #下载源码
tar xzvf gflags-${gflags_version}.tar.gz
cd gflags-${gflags_version}
mkdir build && cd build  #建立编译文件夹，用于存放临时文件
cmake .. -DCMAKE_CXX_FLAGS="-fPIC" -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_SHARED_LIBS=ON -DGFLAGS_NAMESPACE=google -G "Unix Makefiles"  #使用 cmake 进行动态编译生成 Makefile 文件，安装路径为/usr
make # make 编译
make install # 安装库
#直接安装gflags，安装后python import cv2会提示flags.cc重复链接，可能glog已经链接了一样的静态库。
#如果不安装python里import cv2时提示ImportError: libopencv_sfm.so.405: cannot open shared object file: No such file or directory
#cmake提示找不到gflags，opencv_sfm不会被编译，-- Module opencv_sfm disabled because the following dependencies are not found: Glog/Gflags
#增加-DBUILD_SHARED_LIBS=ON解决以上2个问题

glog_version=0.6.0
wget -c https://github.com/google/glog/archive/refs/tags/v${glog_version}.zip glog-${glog_version}.zip
unzip glog-${glog_version}.zip
cd glog-${glog_version}
mkdir build && cd build  #建立编译文件夹，用于存放临时文件
cmake .. -DCMAKE_CXX_FLAGS="-fPIC" -DCMAKE_INSTALL_PREFIX=/usr  #使用 cmake 进行动态编译生成 Makefile 文件，安装路径为/usr
make # make 编译
make install # 安装库

:<<EOF
hdf5_short_version=1.14
hdf5_version=1.14.2
wget -c https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-${hdf5_short_version}/hdf5-${hdf5_version}/src/hdf5-${hdf5_version}.tar.gz
tar xzvf hdf5-${hdf5_version}.tar.gz
cd hdf5-${hdf5_version}
./configure --prefix=/usr/local/hdf5
make && make install
#3. 设置环境变量
export PATH=$HOME/.local/bin/hdf5-1.8.13/bin:$PATH
export LD_LIBRARY_PATH=$HOME/.local/bin/hdf5-1.8.13/lib:$LD_LIBRARY_PATH
-D HDF5_LIBRARIES=/usr/local/hdf5/lib \
-D HDF5_INCLUDE_DIRS=/usr/include \
EOF
yum -y install hdf5-devel


git clone https://github.com/ogre3d/OIS.git
mkdir OIS/build && cd OIS/build  #建立编译文件夹，用于存放临时文件
cmake ..
make
make install
cd ../../

SDL2_version=2.28.3
wget -c https://github.com/libsdl-org/SDL/archive/refs/tags/release-${SDL2_version}.tar.gz -O SDL-release-${SDL2_version}.zip
unzip SDL-release-${SDL2_version}.zip
cd SDL-release-${SDL2_version}
./configure
make && make install
cd ..

git clone https://github.com/OGRECave/ogre.git
mkdir ogre/build && cd ogre/build  #建立编译文件夹，用于存放临时文件
cmake ..
make
make install
cd ../../

install libogre-1.9-dev 

eigen_version=3.4.0
wget -c https://gitlab.com/libeigen/eigen/-/archive/${eigen_version}/eigen-${eigen_version}.zip -O eigen-${eigen_version}.zip
unzip eigen-${eigen_version}.zip
cd eigen-3.3.9 # 进入eigen解压的目录
mkdir build  # 新建一个build文件夹
cd build  # 进入build文件夹
cmake ..  # 用cmake生成Makefile
make
make install  # 安装

:<<EOF
gmp_version=6.3.0
wget -c https://gmplib.org/download/gmp/gmp-${gmp_version}.tar.gz
tar xzvf gmp-${gmp_version}.tar.gz
cd gmp-${gmp_version}
./configure
make
make install
EOF
yum install gmp gmp-devel -y

#mpfr>=4.0.2，不能yum安装版本不够高
mpfr_version=4.2.1
wget -c https://mpfr.loria.fr/mpfr-current/mpfr-${mpfr_version}.tar.gz
cd mpfr-${mpfr_version}
./configure
make
make install

:<<EOF
git clone https://github.com/TheFrenchLeaf/CXSparse
cd CXSparse
mkdir build  # 新建一个build文件夹
cd build  # 进入build文件夹
cmake ..  # 用cmake生成Makefile
make
cd /data0
mv CXSparse /usr/local/
EOF
#suitesparse里已经包括，源码编译出来是.a文件也无法安装

#suitesparse_version=7.2.0
suitesparse_version=6.0.3
#suitesparse_version=5.13.0
wget -c https://github.com/DrTimothyAldenDavis/SuiteSparse/archive/refs/tags/v${suitesparse_version}.tar.gz -O SuiteSparse-${suitesparse_version}.tar.gz
tar xzvf SuiteSparse-${suitesparse_version}.tar.gz
cd SuiteSparse-${suitesparse_version}
make
make install

metis_version=5.1.0
wget -c http://glaros.dtc.umn.edu/gkhome/fetch/sw/metis/metis-${metis_version}.tar.gz
tar xzvf metis-${metis_version}.tar.gz
cd metis-${metis_version}
make config
make
make install

ceres_solver_version=2.1.0
wget -c http://ceres-solver.org/ceres-solver-${ceres_solver_version}.tar.gz -O ceres-solver-${ceres_solver_version}.tar.gz
tar xzvf ceres-solver-${ceres_solver_version}.tar.gz
cd ceres-solver-2.1.0
#修改去掉4.0，find_package(SuiteSparse 4.0 COMPONENTS CHOLMOD SPQR)
mkdir build
cd build
#要注释掉openacc的hpc安装PATH设置，不然就错误的找到hpc路径下了
cmake总数找不到cxsparse和suitesparse，用ccmake手工配置这2个组件的目录
:<<EOF
cmake \
-D CUDA_cublas_LIBRARY=/usr/local/cuda/lib64/libcublas.so \
-D CUDA_cusolver_LIBRARY=/usr/local/cuda/lib64/libcusolver.so \
-D CUDA_cusparse_LIBRARY=/usr/local/cuda/lib64/libcusparse.so \
-D CXSparse_INCLUDE_DIR=/usr/local/CXSparse/Include \
-D SuiteSparse_DIR=/usr/local \
..
EOF
cmake ..
make -j8
make test
make install
cd ../../

yum remove libva.x86_64 libva-devel.x86_64 -y
libva_version=2.20.0
wget -c https://github.com/intel/libva/archive/refs/tags/${libva_version}.tar.gz -O libva-${libva_version}.tar.gz
tar xzvf libva-${libva_version}.tar.gz
yum install libdrm-devel.x86_64 xorg-x11-server-devel.x86_64 -y
cd libva-${libva_version}
#./configure --prefix=/usr --libdir=/usr/lib64 CFLAGS=-DNDEBUG
./autogen
make -j4
make install

vadriver_version=2.4.1
wget -c https://github.com/intel/intel-vaapi-driver/archive/refs/tags/${vadriver_version}.tar.gz -O intel-vaapi-driver-${vadriver_version}.tar.gz
tar xzvf intel-vaapi-driver-${vadriver_version}.tar.gz
cd intel-vaapi-driver-${vadriver_version}
./autogen
make -j4
make install

#ffmpeg依赖libva，会一起卸载
yum -y install ffmpeg ffmpeg-devel

yum list|grep tbb
yum remove -y tbb*
tbb_version=2021.11.0-rc1
wget -c https://github.com/oneapi-src/oneTBB/archive/refs/tags/v${tbb_version}.tar.gz -O tbb-${tbb_version}.tar.gz
cd oneTBB-${tbb_version}
mkdir build  # 新建一个build文件夹
cd build  # 进入build文件夹
cmake ..  # 用cmake生成Makefile
make
make install


#opencv_version=4.8.0
#opencv_version=4.7.0
opencv_version=4.6.0
opencv_version=4.5.5
wget -c https://github.com/opencv/opencv/archive/refs/tags/${opencv_version}.tar.gz -O opencv-${opencv_version}.tar.gz
wget -c https://github.com/opencv/opencv_contrib/archive/refs/tags/${opencv_version}.tar.gz -O opencv_contrib-${opencv_version}.tar.gz
tar xzvf opencv-${opencv_version}.tar.gz
tar xzvf opencv_contrib-${opencv_version}.tar.gz

mkdir opencv-${opencv_version}/build && cd opencv-${opencv_version}/build

#-D CMAKE_INSTALL_PREFIX=/usr/local \

#opencv_version=4.8.0
#opencv_version=4.7.0
opencv_version=4.6.0
opencv_version=4.5.5
cmake \
-D GLOG_INCLUDE_DIR=/usr/include/glog \
-D CMAKE_BUILD_TYPE=RELEASE \
-D CMAKE_INSTALL_PREFIX=/usr/local/opencv \
-D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib-${opencv_version}/modules \
-D OPENCV_ENABLE_NONFREE=ON \
-D WITH_CUDA=ON \
-D WITH_CUDNN=ON \
-D OPENCV_DNN_CUDA=ON \
-D ENABLE_FAST_MATH=1 \
-D CUDA_FAST_MATH=1 \
-D CUDA_ARCH_BIN=8.6 \
-D WITH_CUBLAS=1 \821
-D OPENCV_GENERATE_PKGCONFIG=YES \
-D BUILD_EXAMPLES=ON \
-D WITH_TBB=ON \
-D BUILD_PYTHON_SUPPORT=ON \
-D BUILD_NEW_PYTHON_SUPPORT=ON \
-D HAVE_opencv_python3=ON \
-D PYTHON3_EXECUTABLE=/data0/envs/deepspeed/bin/python3  \
-D PYTHON_DEFAULT_EXECUTABLE=/data0/envs/deepspeed/bin/python3  \
-D BUILD_opencv_python3=ON \
-D BUILD_opencv_python2=OFF \
-D PYTHON3_INCLUDE_DIR=/data0/envs/deepspeed/include/python3.9  \
-D PYTHON3_LIBRARY=/usr/local/miniconda3/pkgs/python-3.9.17-h955ad1f_0/lib  \
-D PYTHON3_NUMPY_INCLUDE_DIRS=/data0/envs/deepspeed/lib/python3.9/site-packages/numpy/core/include  \
-D PYTHON3_PACKAGES_PATH=/data0/envs/deepspeed/lib/python3.9/site-packages \
-D PYTHON3_EXECUTABLE=/data0/envs/deepspeed/bin/python3 \
-D PYTHON_EXECUTABLE=/data0/envs/deepspeed/bin/python3 \
-D OPENCV_GENERATE_PKGCONFIG=YES \
-D WITH_V4L=ON  \
-D CUDA_NVCC_FLAGS="-D_FORCE_INLINES"   \
.. 
make -j24
pip uninstall opencv-python -y
ccmake ..
#确认python2被关闭，python3被正确配置
make test
make install
rm -f /usr/share/pkgconfig/opencv4.pc
ln -s /usr/local/opencv/lib64/pkgconfig/opencv4.pc /usr/share/pkgconfig/
ldconfig
pkg-config --modversion opencv4
echo "LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/opencv/lib64" >> ~/.bashrc
#pip install opencv-python==4.5.5.64
#pip安装的不能调用cuda
find /usr/local/opencv -name "nonfree*"
python -c "import cv2; print(cv2.__version__)"
python -c "from cv2 import cuda; cuda.printCudaDeviceInfo(0)"

#yum install opencv opencv-devel opencv-python -y
#2.4.5
#not work on cuda

:<<EOF
4.8.0
[ 53%] Built target opencv_stitching
/data0/opencv-4.8.0/modules/imgcodecs/src/grfmt_exr.cpp:682:7: warning: "OPENEXR_VERSION_MAJOR" is not defined, evaluates to 0 [-Wundef]
  682 | #if ((OPENEXR_VERSION_MAJOR * 1000 + OPENEXR_VERSION_MINOR) >= (2 * 1000 + 2)) // available since version 2.2.0
      |       ^~~~~~~~~~~~~~~~~~~~~
/data0/opencv-4.8.0/modules/imgcodecs/src/grfmt_exr.cpp:682:38: warning: "OPENEXR_VERSION_MINOR" is not defined, evaluates to 0 [-Wundef]
  682 | #if ((OPENEXR_VERSION_MAJOR * 1000 + OPENEXR_VERSION_MINOR) >= (2 * 1000 + 2)) // available since version 2.2.0
      |                                      ^~~~~~~~~~~~~~~~~~~~~
/data0/opencv-4.8.0/modules/imgcodecs/src/grfmt_exr.cpp:696:5: warning: "OPENEXR_VERSION_MAJOR" is not defined, evaluates to 0 [-Wundef]
  696 | #if OPENEXR_VERSION_MAJOR >= 3
      |     ^~~~~~~~~~~~~~~~~~~~~
In file included from /data0/opencv-4.8.0/modules/imgcodecs/src/grfmt_exr.cpp:48:
/data0/opencv-4.8.0/modules/imgcodecs/src/grfmt_exr.cpp: In member function ‘virtual bool cv::ExrEncoder::write(const cv::Mat&, const std::vector<int>&)’:
/data0/opencv-4.8.0/modules/imgcodecs/src/grfmt_exr.cpp:699:136: error: ‘OPENEXR_VERSION_MAJOR’ was not declared in this scope; did you mean ‘OPENEXR_VERSION_STRING’?
  699 |             CV_LOG_ONCE_WARNING(NULL, "Setting `IMWRITE_EXR_DWA_COMPRESSION_LEVEL` not supported in OpenEXR version " + std::to_string(OPENEXR_VERSION_MAJOR) + " (version 3 is required)");
      |                                                                                                                                        ^~~~~~~~~~~~~~~~~~~~~
/data0/opencv-4.8.0/modules/core/include/opencv2/core/utils/logger.hpp:118:30: note: in definition of macro ‘CV_LOG_WITH_TAG’
  118 |         cv_temp_logstream << __VA_ARGS__; \
      |                              ^~~~~~~~~~~
/data0/opencv-4.8.0/modules/imgcodecs/src/grfmt_exr.cpp:699:13: note: in expansion of macro ‘CV_LOG_ONCE_WARNING’
  699 |             CV_LOG_ONCE_WARNING(NULL, "Setting `IMWRITE_EXR_DWA_COMPRESSION_LEVEL` not supported in OpenEXR version " + std::to_string(OPENEXR_VERSION_MAJOR) + " (version 3 is required)");
      |             ^~~~~~~~~~~~~~~~~~~
make[2]: *** [modules/imgcodecs/CMakeFiles/opencv_imgcodecs.dir/build.make:146: modules/imgcodecs/CMakeFiles/opencv_imgcodecs.dir/src/grfmt_exr.cpp.o] Error 1
make[1]: *** [CMakeFiles/Makefile2:6133: modules/imgcodecs/CMakeFiles/opencv_imgcodecs.dir/all] Error 2
make: *** [Makefile:166: all] Error 2


4.7.0
[ 55%] Generating opencv-470.jar
Buildfile: /data0/opencv-4.7.0/build/modules/java/jar/opencv/build.xml

jar:
    [javac] Compiling 288 source files to /data0/opencv-4.7.0/build/modules/java/jar/opencv/build/classes
/data0/opencv-4.7.0/modules/imgcodecs/src/grfmt_exr.cpp:682:7: warning: "OPENEXR_VERSION_MAJOR" is not defined, evaluates to 0 [-Wundef]
  682 | #if ((OPENEXR_VERSION_MAJOR * 1000 + OPENEXR_VERSION_MINOR) >= (2 * 1000 + 2)) // available since version 2.2.0
      |       ^~~~~~~~~~~~~~~~~~~~~
/data0/opencv-4.7.0/modules/imgcodecs/src/grfmt_exr.cpp:682:38: warning: "OPENEXR_VERSION_MINOR" is not defined, evaluates to 0 [-Wundef]
  682 | #if ((OPENEXR_VERSION_MAJOR * 1000 + OPENEXR_VERSION_MINOR) >= (2 * 1000 + 2)) // available since version 2.2.0
      |                                      ^~~~~~~~~~~~~~~~~~~~~
/data0/opencv-4.7.0/modules/imgcodecs/src/grfmt_exr.cpp:696:5: warning: "OPENEXR_VERSION_MAJOR" is not defined, evaluates to 0 [-Wundef]
  696 | #if OPENEXR_VERSION_MAJOR >= 3
      |     ^~~~~~~~~~~~~~~~~~~~~
In file included from /data0/opencv-4.7.0/modules/imgcodecs/src/grfmt_exr.cpp:48:
/data0/opencv-4.7.0/modules/imgcodecs/src/grfmt_exr.cpp: In member function ‘virtual bool cv::ExrEncoder::write(const cv::Mat&, const std::vector<int>&)’:
/data0/opencv-4.7.0/modules/imgcodecs/src/grfmt_exr.cpp:699:136: error: ‘OPENEXR_VERSION_MAJOR’ was not declared in this scope; did you mean ‘OPENEXR_VERSION_STRING’?
  699 |             CV_LOG_ONCE_WARNING(NULL, "Setting `IMWRITE_EXR_DWA_COMPRESSION_LEVEL` not supported in OpenEXR version " + std::to_string(OPENEXR_VERSION_MAJOR) + " (version 3 is required)");
      |                                                                                                                                        ^~~~~~~~~~~~~~~~~~~~~
/data0/opencv-4.7.0/modules/core/include/opencv2/core/utils/logger.hpp:118:30: note: in definition of macro ‘CV_LOG_WITH_TAG’
  118 |         cv_temp_logstream << __VA_ARGS__; \
      |                              ^~~~~~~~~~~
/data0/opencv-4.7.0/modules/imgcodecs/src/grfmt_exr.cpp:699:13: note: in expansion of macro ‘CV_LOG_ONCE_WARNING’
  699 |             CV_LOG_ONCE_WARNING(NULL, "Setting `IMWRITE_EXR_DWA_COMPRESSION_LEVEL` not supported in OpenEXR version " + std::to_string(OPENEXR_VERSION_MAJOR) + " (version 3 is required)");
      |             ^~~~~~~~~~~~~~~~~~~
make[2]: *** [modules/imgcodecs/CMakeFiles/opencv_imgcodecs.dir/build.make:132: modules/imgcodecs/CMakeFiles/opencv_imgcodecs.dir/src/grfmt_exr.cpp.o] Error 1
make[1]: *** [CMakeFiles/Makefile2:6170: modules/imgcodecs/CMakeFiles/opencv_imgcodecs.dir/all] Error 2
make[1]: *** Waiting for unfinished jobs....
      [jar] Building jar: /data0/opencv-4.7.0/build/bin/opencv-470.jar

BUILD SUCCESSFUL
Total time: 1 second
[ 55%] Built target opencv_java_jar
make: *** [Makefile:166: all] Error 2


EOF