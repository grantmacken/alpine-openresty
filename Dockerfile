# Dockerfile grantmacken/alpine-openresty
# https://github.com/grantmacken/alpine-openresty
FROM alpine:3.7 as packager

LABEL maintainer="Grant Mackenzie <grantmacken@gmail.com>"

ENV OPENRESTY_HOME /usr/local/openresty
ENV OPENRESTY_BIN /usr/local/openresty/bin
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
  wget \
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
ENV OPENRESTY_HOME /usr/local/openresty
ENV OPENRESTY_BIN /usr/local/openresty/bin
COPY --from=packager /usr/local/openresty /usr/local/openresty
RUN apk add --no-cache \
    gd \
    geoip \
    libgcc \
    libxslt \
    && ln -s $OPENRESTY_BIN/openresty /usr/local/bin \
    && ln -s $OPENRESTY_BIN/resty /usr/local/bin

# not sure about keeping 
# libxslt \
# geoip \

ENV LANG C.UTF-81
EXPOSE 80 443
# # # #  VOLUME $EXIST_DATA_DIR
STOPSIGNAL SIGTERM
WORKDIR $OPENRESTY_HOME
ENTRYPOINT ["bin/openresty", "-g", "daemon off;"]
