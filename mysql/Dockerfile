ARG MYSQL_VERSION_2BUILD=?
FROM mysql:${MYSQL_VERSION_2BUILD} as production-stage

ARG MYSQL_VERSION_2BUILD=?
COPY docker-entrypoint-${MYSQL_VERSION_2BUILD}.sh /usr/local/bin/docker-entrypoint.sh