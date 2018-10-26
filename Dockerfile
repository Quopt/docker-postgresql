FROM postgres:10.5-alpine
LABEL server="Postgresql"

#install pg_cron into the container
ENV PG_CRON_VERSION=1.0.2
RUN apk update && apk add --no-cache --virtual .build-deps build-base ca-certificates openssl tar \
    && wget -O /pg_cron.tgz https://github.com/citusdata/pg_cron/archive/v$PG_CRON_VERSION.tar.gz \
    && tar xvzf /pg_cron.tgz && cd pg_cron-$PG_CRON_VERSION \
    && sed -i.bak -e 's/-Werror//g' Makefile \
    && sed -i.bak -e 's/-Wno-implicit-fallthrough//g' Makefile \
    && make && make install \
    && cd .. && rm -rf pg_cron.tgz && rm -rf pg_cron-*

COPY startMe.sh /tmp/startMe.sh
COPY postgresql.conf /tmp/postgresql.conf
RUN chmod +x /tmp/startMe.sh

CMD ["sh","-c","./tmp/startMe.sh"]
