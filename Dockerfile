# Dockerfile grantmacken/alpine-openresty
# https://github.com/grantmacken/alpine-openresty
ARG FROM_IMAGE="alpine"
ARG FROM_TAG="3.9"

FROM ${FROM_IMAGE}:${FROM_TAG} as pack
# LABEL maintainer="${GIT_USER_NAME} <${GIT_USER_EMAIL}>"
WORKDIR /home
# build-base like build-essentials
# contains make
# First Stage:
# this installs openresty from sources into /usr/local/openresty
# the install build dependencies are the remove

RUN apk add --no-cache --virtual .build-deps \
  build-base \
  curl \
  cmake \
  gd-dev \
  geoip-dev \
  libxslt-dev \
  linux-headers \
  zlib-dev \
  zlib \
  readline-dev \
  tar \
  wget \
  perl-dev \
  perl-utils \
  perl-app-cpanminus

COPY Makefile Makefile
COPY .env .env

RUN echo 'openresty install' \
    && make install \
    && make perl-modules \
    && make cmark-build \
    && rm -r /home/* \
    && apk del .build-deps

# https://github.com/openresty/docker-openresty/blob/master/alpine/Dockerfile
# https://github.com/openresty/openresty-packaging/blob/master/deb/Makefile
#  Second Stage:  dev
FROM ${FROM_IMAGE}:${FROM_TAG} as base
ENV OPENRESTY_HOME "/usr/local/openresty"
ENV LETSENCRYPT "/etc/letsencrypt"
COPY --from=pack /usr/local /usr/local
RUN apk add --no-cache \
    gd \
    geoip \
    libgcc \
    libxslt \
    zlib \
    perl \
    curl \
    && mkdir -p ${LETSENCRYPT}/live \
    && mkdir -p ${OPENRESTY_HOME}/nginx/html/.well-known/acme-challenge \
    && mkdir -p ${OPENRESTY_HOME}/site/lualib/${GIT_USER_NAME} \
    && mkdir -p $OPENRESTY_HOME/t \
    && mkdir -p $OPENRESTY_HOME/site/bin \
    && ln -s ${OPENRESTY_HOME}/bin/* /usr/local/bin \
    && ln -s $OPENRESTY_BIN/openresty /usr/local/bin/nginx \
    && ln -sf /dev/stdout $OPENRESTY_HOME/nginx/logs/access.log \
    && ln -sf /dev/stderr $OPENRESTY_HOME/nginx/logs/error.log \
    && opm get ledgetech/lua-resty-http \
    && opm get SkyLothar/lua-resty-jwt \
    && opm get bungle/lua-resty-reqargs

WORKDIR /usr/local/openresty
# ENV LANG C.UTF-8
# EXPOSE 80 443
# STOPSIGNAL SIGTERM
# ENTRYPOINT ["bin/openresty", "-g", "daemon off;"]
# # Third Stage: prod
# FROM base as dev
# ENV OPENRESTY_HOME /usr/local/openresty
# # use opm to get 
# # create letsencrypt wellknown dir

# WORKDIR /home
# COPY .env .env

# RUN source .env \
#   && mkdir -p  $OPENRESTY_HOME/nginx/html/.well-known/acme-challenge \
#   && mkdir -p $OPENRESTY_HOME/site/lualib/grantmacken \
#   && mkdir -p $OPENRESTY_HOME/t \
#   && mkdir -p $OPENRESTY_HOME/site/bin \
#   && mv $OPENRESTY_HOME/nginx/conf/mime.types ./ \
#   && rm $OPENRESTY_HOME/nginx/conf/* \
#   && echo ${DOREX} \
#   && curl -SL https://github.com/grantmacken/dorex/archive/${DOREX}.tar.gz | tar -xz \
#   && mv dorex-* dorex \
#   && ls dorex \
#   && cp dorex/proxy/conf/* $OPENRESTY_HOME/nginx/conf \
#   && mv mime.types $OPENRESTY_HOME/nginx/conf \
#   && ls $OPENRESTY_HOME/nginx/conf \
#   && cp dorex/proxy/lualib/* $OPENRESTY_HOME/site/lualib/grantmacken \
#   && cp dorex/bin/* $OPENRESTY_HOME/site/bin \
#   && ls $OPENRESTY_HOME/site/lualib/grantmacken \
#   && rm -r /home/*

# WORKDIR $OPENRESTY_HOME
# ENV LANG C.UTF-8
# EXPOSE 80 443
# STOPSIGNAL SIGTERM
# ENTRYPOINT ["bin/openresty", "-g", "daemon off;"]

