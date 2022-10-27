nerdctl build ./ -f Dockerfile-ubuntu20 -t harbor.my.org:1080/base/ubuntu20-netutil
nerdctl images

nerdctl login -uadmin -pHarbor12345 --insecure-registry harbor.my.org:1080
nerdctl push harbor.my.org:1080/base/ubuntu20-netutil
nerdctl tag harbor.my.org:1080/base/ubuntu20-netutil harbor.my.org:1080/basesec/ubuntu20-netutil
nerdctl push harbor.my.org:1080/basesec/ubuntu20-netutil

nerdctl run -d harbor.my.org:1080/base/ubuntu20-netutil ping qq.com
nerdctl exec -it  ubuntu-c5a5f bash