# Dockerfile grantmacken/alpine-openresty
# https://github.com/grantmacken/alpine-openresty
FROM alpine:3.7 as packager

LABEL maintainer="Grant Mackenzie <grantmacken@gmail.com>"

ENV OPENRESTY_HOME /usr/local/openresty
ENV INSTALL_PATH /grantmacken
RUN mkdir -p $INSTALL_PATH
WORKDIR $INSTALL_PATH
COPY Makefile Makefile
# build-base like build-essentials 
# contains make
# First Stage:
# this installs openresty from sources into /usr/local/openresty
# the install build dependencies are the remove

RUN apk add --no-cache --virtual .build-deps \
  build-base \
  linux-headers \
  curl \
  perl-dev \
  gd-dev \
  readline-dev \
  && mkdir tmp \
  && make -j$(grep ^proces /proc/cpuinfo | wc -l) && \
  rm -rf tmp && \
  apk del .build-deps

# Second Stage:
# Copy over openresty directory
# Then install only the or run dependencies 
FROM alpine:3.7 as slim
COPY --from=packager /usr/local/openresty /usr/local/openresty
RUN apk add --no-cache \
  gd \
  geoip \
  libgcc \
  libxslt \

# not sure about keeping 
# libxslt \
# geoip \

# alpine fat
# linux-headers \
# build-base \
# gd \
# libgcc \-
# geoip \
# libxslt \
# perl \
# curl \
# unzip \
# zlib \

ENV OPENRESTY_HOME /usr/local/openresty
WORKDIR $OPENRESTY_HOME
ENV LANG C.UTF-81
EXPOSE 80 443
# # #  VOLUME $EXIST_DATA_DIR
STOPSIGNAL SIGTERM
# WORKDIR $OPENRESTY_HOME
ENTRYPOINT ["bin/openresty", "-g", "daemon off;"]
