#openvino
:<<EOF
wget -c https://storage.openvinotoolkit.org/repositories/openvino/packages/2023.1/linux/l_openvino_toolkit_centos7_2023.1.0.12185.47b736f63ed_x86_64.tgz
tar xzvf l_openvino_toolkit_centos7_2023.1.0.12185.47b736f63ed_x86_64.tgz
ln -s l_openvino_toolkit_centos7_2023.1.0.12185.47b736f63ed_x86_64 openvino
EOF
wget -c https://storage.openvinotoolkit.org/repositories/openvino/packages/2023.0/linux/l_openvino_toolkit_centos7_2023.0.0.10926.b4452d56304_x86_64.tgz
tar xzvf l_openvino_toolkit_centos7_2023.0.0.10926.b4452d56304_x86_64.tgz
ln -s l_openvino_toolkit_centos7_2023.0.0.10926.b4452d56304_x86_64 openvino
#echo "source /data0/openvino/setupvars.sh" >> ~/.bashrc
source /data0/openvino/setupvars.sh
./install_dependencies/install_openvino_dependencies.sh
pip install openvino
python -c "from openvino.runtime import Core"
python -m pip install openvino-dev
cd samples/python/hello_classification
omz_downloader --name alexnet
omz_converter --name alexnet
python hello_classification.py alexnet.xml banana.jpg GPU
