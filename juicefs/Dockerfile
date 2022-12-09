#FROM chenseanxy/hadoop:3.2.1-nolib
FROM harbor.my.org:1080/chenseanxy/hadoop-ubussh:3.2.1-nolib

COPY minio /usr/local/bin/
COPY mc /usr/local/bin/

COPY miniogw /usr/local/hadoop/miniogw
WORKDIR /usr/local/hadoop/miniogw
RUN make build
RUN cp /usr/local/hadoop/miniogw/minio /usr/local/bin/miniogw
WORKDIR /usr/local/hadoop

COPY juicefs /usr/local/bin/
RUN juicefs
COPY juicefs-hadoop-1.0.2.jar /usr/local/hadoop/share/hadoop/common/lib/
RUN mkdir /jfscache
COPY core-site.xml /usr/local/hadoop/etc/hadoop/

