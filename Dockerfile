# Dockerfile grantmacken/alpine-openresty
# https://github.com/grantmacken/alpine-openresty
FROM alpine:3.10.2 as pack
# LABEL maintainer="${GIT_USER_NAME} <${GIT_USER_EMAIL}>"
WORKDIR /home
# build-base like build-essentials
# contains make
# First Stage:
# this installs openresty from sources into /usr/local/openresty'

COPY Makefile Makefile
COPY .env .env

RUN apk add --no-cache --virtual .build-deps \
  build-base \
  linux-headers \
  cmake \
  perl-dev \
  perl-app-cpanminus \
  perl-dev \
  readline-dev \
  zlib-dev \
  gd-dev \
  geoip-dev \
  libxslt-dev \
  wget \
  && apk add --no-cache \
  libgcc \
  curl \
  && make \
  && ln -sf /dev/stdout /usr/local/openresty/nginx/logs/access.log \
  && ln -sf /dev/stderr /usr/local/openresty/nginx/logs/error.log \
  && apk del .build-deps

WORKDIR /usr/local/openresty
ENV LANG C.UTF-8
EXPOSE 80 443
# Use SIGQUIT instead of default SIGTERM to cleanly drain requests
# See https://github.com/openresty/docker-openresty/blob/master/README.md#tips--pitfalls
STOPSIGNAL SIGQUIT
ENTRYPOINT ["bin/openresty", "-g", "daemon off;"]

# https://github.com/openresty/docker-openresty/blob/master/alpine/Dockerfile
# https://github.com/openresty/openresty-packaging/blob/master/deb/Makefile
#  Second Stage:  dev
FROM alpine:3.10.2 as base
COPY --from=pack /usr/local /usr/local
RUN apk add --no-cache \
    libgcc \
    gd \
    geoip \
    perl \
    curl \
    libxslt \
    zlib \
    && mkdir -p /etc/letsencrypt/live \
    && mkdir -p /usr/local/openresty/nginx/html/.well-known/acme-challenge \
    && mkdir -p /usr/local/openresty/site/lualib/grantmacken \
    && mkdir -p /usr/local/openresty/site/t \
    && mkdir -p /usr/local/openresty/site/bin \
    && ln -s /usr/local/openresty/bin/* /usr/local/bin \
    && ln -s /usr/local/openresty/bin/openresty /usr/local/bin/nginx \
    && ln -sf /dev/stdout /usr/local/openresty/nginx/logs/access.log \
    && ln -sf /dev/stderr /usr/local/openresty/nginx/logs/error.log \
    && opm get ledgetech/lua-resty-http \
    && opm get SkyLothar/lua-resty-jwt \
    && opm get bungle/lua-resty-reqargs

WORKDIR /usr/local/openresty
ENV OPENRESTY_HOME "/usr/local/openresty"
ENV LANG C.UTF-8
EXPOSE 80 443
STOPSIGNAL SIGTERM
ENTRYPOINT ["bin/openresty", "-g", "daemon off;"]

