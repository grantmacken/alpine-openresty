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
  grep \
  wget \
  curl \
  tar \
  perl-dev \
  gd-dev \
  readline-dev \
  &&  wget -O - https://cpanmin.us | perl - App::cpanminus \
  &&  cpanm --skip-installed -n Test::Base IPC::Run Test::Nginx\
  && mkdir tmp \
  && make -j$(grep ^proces /proc/cpuinfo | wc -l) install-from-sources \
  && rm -rf tmp \
  && apk del .build-deps

# /usr/local/lib/perl5/site_perl/5.26.2
# Second Stage:
# Copy over openresty directory
# Then install only the run dependencies 
FROM alpine:3.7 as dev
ENV OPENRESTY_HOME /usr/local/openresty
ENV OPENRESTY_BIN /usr/local/openresty/bin
COPY --from=packager $OPENRESTY_HOME $OPENRESTY_HOME
WORKDIR $OPENRESTY_HOME
RUN apk add --no-cache \
    gd \
    geoip \
    libgcc \
    libxslt \
    perl \
    && mkdir -p /etc/letsencrypt/live \
    && ln -s $OPENRESTY_BIN/openresty /usr/local/bin \
    && ln -s $OPENRESTY_BIN/resty /usr/local/bin \
    && ln -sf /dev/stdout $OPENRESTY_HOME/nginx/logs/access.log \
    && ln -sf /dev/stderr $OPENRESTY_HOME/nginx/logs/error.log

COPY --from=packager /usr/local/lib/perl5/site_perl /usr/local/lib/perl5/site_perl
# not sure about keeping 
# libxslt \
# geoip \
ENV LANG C.UTF-8
EXPOSE 80 443
# # # #  VOLUME $EXIST_DATA_DIR
STOPSIGNAL SIGTERM
ENTRYPOINT ["bin/openresty", "-g", "daemon off;"]
