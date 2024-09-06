#engine=trino
engine=presto
#engine=presto-velox
if [[ ${engine} == "trino" ]]; then
  CONTAINER_HOME_PATH=/usr/lib/trino
else
  CONTAINER_HOME_PATH=/home/presto
fi
maxmem=24
maxmem_pernode=8
heapmem=24
workers=3
      ts=ds
      SCALE=10
