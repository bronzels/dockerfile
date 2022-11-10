FROM chenseanxy/hadoop:3.2.1-nolib

COPY juicefs /usr/local/bin/
COPY juicefs-hadoop-1.0.2.jar /usr/local/hadoop/share/hadoop/common/lib/
RUN which juicefs
RUN juicefs

RUN mkdir -p /data/jfs
COPY core-site.xml /usr/local/hadoop/etc/hadoop/