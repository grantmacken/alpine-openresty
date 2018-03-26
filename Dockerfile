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

RUN apk add --no-cache --virtual .build-deps \
  build-base \
  linux-headers \
  curl \
  perl-dev \
  gd-dev \
  readline-dev \
  && mkdir tmp \
  && make && \
  rm -rf tmp

ENV LANG C.UTF-81
EXPOSE 8282
# # #  VOLUME $EXIST_DATA_DIR
STOPSIGNAL SIGTERM
ENTRYPOINT ["bin/openresty", "-g", "daemon off;"]
