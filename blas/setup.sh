OPENBLAS_VERSION=0.3.24
wget -c https://github.com/xianyi/OpenBLAS/archive/refs/tags/v${OPENBLAS_VERSION}.tar.gz
tar xzvf v${OPENBLAS_VERSION}.tar.gz
cd OpenBLAS-${OPENBLAS_VERSION}
make DYNAMIC_ARCH=0 USE_THREAD=1 USE_OPENMP=1 NOFORTRAN=1
make -j4 PREFIX=/usr NO_STATIC=1 install
cc -o test_openblas test_openblas.c -I /usr/include/ -L/usr/lib -lopenblas -lpthread
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/lib" >> ~/.bashrc
./test_openblas

NUMPY_VERSION=1.25.2
wget -c https://github.com/numpy/numpy/archive/refs/tags/v${NUMPY_VERSION}.tar.gz
tar xzvf v${NUMPY_VERSION}.tar.gz
cd numpy-${NUMPY_VERSION}
cp site.cfg.example site.cfg
cat << \EOF >> site.cfg
[default]
include_dirs = /usr/include
library_dirs = /usr/lib

[openblas]
openblas_libs = openblas
include_dirs = /usr/include
library_dirs = /usr/lib

[lapack]
lapack_libs = openblas

[atlas]
atlas_libs = openblas
libraries = openblas
EOF
python setup.py config
:<<EOF
输出应如下所示：
openblas_info:
  FOUND:
    libraries = ['openblas', 'openblas']
    library_dirs = ['/opt/OpenBLAS/lib']
    language = c
    define_macros = [('HAVE_CBLAS', None)]

  FOUND:
    libraries = ['openblas', 'openblas']
    library_dirs = ['/opt/OpenBLAS/lib']
    language = c
    define_macros = [('HAVE_CBLAS', None)]
EOF
#python setup.py install
#与安装pip比较，因为pip将跟踪包的元数据，让你轻松卸载或将来升级numpy的。
pip install .
