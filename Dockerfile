# Dockerfile grantmacken/alpine-openresty
# https://github.com/grantmacken/alpine-openresty

FROM alpine:3.8 as pack
LABEL maintainer="Grant Mackenzie <grantmacken@gmail.com>"
WORKDIR /home
# build-base like build-essentials
# contains make
# First Stage:
# this installs openresty from sources into /usr/local/openresty
# the install build dependencies are the remove
COPY Makefile Makefile
COPY .env .env
RUN apk add --no-cache --virtual .build-deps \
  build-base \
  curl \
  gd-dev \
  geoip-dev \
  libxslt-dev \
  linux-headers \
  readline-dev \
  tar \
  wget \
  perl-dev \
  perl-utils \
  perl-app-cpanminus \
  && export MAKEFLAGS="-j4" \
  && echo 'openresty install' \
  && make install \
  && make perl-modules \
  && rm -r /home/* \
  && apk del .build-deps


# https://github.com/openresty/docker-openresty/blob/master/alpine/Dockerfile
# https://github.com/openresty/openresty-packaging/blob/master/deb/Makefile
#  Second Stage:  dev

FROM alpine:3.8 as base
ENV OPENRESTY_HOME /usr/local/openresty
ENV OPENRESTY_BIN /usr/local/openresty/bin
WORKDIR $OPENRESTY_HOME
COPY --from=pack /usr/local /usr/local
RUN apk add --no-cache \
    gd \
    geoip \
    libgcc \
    libxslt \
    perl \
    curl \
    && mkdir -p /etc/letsencrypt/live \
    && ln -s $OPENRESTY_BIN/openresty /usr/local/bin \
    && ln -s $OPENRESTY_BIN/openresty /usr/local/bin/nginx \
    && ln -s $OPENRESTY_BIN/resty /usr/local/bin \
    && ln -s $OPENRESTY_BIN/opm /usr/local/bin \
    && ln -sf /dev/stdout $OPENRESTY_HOME/nginx/logs/access.log \
    && ln -sf /dev/stderr $OPENRESTY_HOME/nginx/logs/error.log \
    && opm get pintsized/lua-resty-http \
    && opm get SkyLothar/lua-resty-jwt \
    && opm get bungle/lua-resty-reqargs

ENV LANG C.UTF-8
EXPOSE 80 443
STOPSIGNAL SIGTERM
ENTRYPOINT ["bin/openresty", "-g", "daemon off;"]

# Third Stage: prod
FROM base as dev
ENV OPENRESTY_HOME /usr/local/openresty
# use opm to get 
# create letsencrypt wellknown dir

WORKDIR /home
COPY .env .env

RUN export DOREX=v0.0.4 \
  && mkdir -p  $OPENRESTY_HOME/nginx/html/.well-known/acme-challenge \
  && mkdir -p $OPENRESTY_HOME/site/lualib/grantmacken \
  && mkdir -p $OPENRESTY_HOME/t \
  && mkdir -p $OPENRESTY_HOME/site/bin \
  && mv $OPENRESTY_HOME/nginx/conf/mime.types ./ \
  && rm $OPENRESTY_HOME/nginx/conf/* \
  && echo ${DOREX} \
  && curl -SL https://github.com/grantmacken/dorex/archive/${DOREX}.tar.gz | tar -xz \
  && mv dorex-* dorex \
  && ls dorex \
  && cp dorex/proxy/conf/* $OPENRESTY_HOME/nginx/conf \
  && mv mime.types $OPENRESTY_HOME/nginx/conf \
  && ls $OPENRESTY_HOME/nginx/conf \
  && cp dorex/proxy/lualib/* $OPENRESTY_HOME/site/lualib/grantmacken \
  && cp dorex/bin/* $OPENRESTY_HOME/site/bin \
  && ls $OPENRESTY_HOME/site/lualib/grantmacken \
  && rm -r /home/*

WORKDIR $OPENRESTY_HOME
ENV LANG C.UTF-8
EXPOSE 80 443
STOPSIGNAL SIGTERM
ENTRYPOINT ["bin/openresty", "-g", "daemon off;"]

