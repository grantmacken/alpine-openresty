# syntax=docker/dockerfile:experimental
# Dockerfile grantmacken/alpine-openresty
# https://github.com/grantmacken/alpine-openresty

FROM alpine:3.11 as bld
# LABEL maintainer="${GIT_USER_NAME} <${GIT_USER_EMAIL}>"
# https://github.com/ricardbejarano/nginx/blob/master/Dockerfile.musl

ARG PREFIX
ARG OPENRESTY_VER
ARG PCRE_VER
ARG ZLIB_VER
ARG OPENSSL_VER
ARG CMARK_VER
ARG PCRE_PREFIX="${PREFIX}/pcre"
ARG PCRE_LIB="${PCRE_PREFIX}/lib"
ARG PCRE_INC="${PCRE_PREFIX}/include"
ARG ZLIB_PREFIX="${PREFIX}/zlib"
ARG ZLIB_LIB="$ZLIB_PREFIX/lib"
ARG ZLIB_INC="$ZLIB_PREFIX/include"
ARG OPENSSL_PREFIX="${PREFIX}/openssl"
ARG OPENSSL_LIB="$OPENSSL_PREFIX/lib"
ARG OPENSSL_INC="$OPENSSL_PREFIX/include"
ARG CMARK_PREFIX="${PREFIX}/cmark"

# https://github.com/openresty/docker-openresty/blob/master/alpine/Dockerfile
# ARG RESTY_LUAJIT_OPTIONS="--with-luajit-xcflags='-DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT'"

RUN --mount=type=cache,target=/var/cache/apk \ 
    ln -vs /var/cache/apk /etc/apk/cache \
    && apk add --virtual .build-deps \
        build-base \
        linux-headers \
        gd-dev \
        geoip-dev \
        libxslt-dev \
        perl-dev \
        readline-dev \
        libgcc \
        perl-dev \
    && apk add --update perl curl

WORKDIR = /home
ADD https://zlib.net/zlib-${ZLIB_VER}.tar.gz ./zlib.tar.gz
RUN echo ' - install zlib' \
    && echo '   ------------' \
    &&  tar -C /tmp -xf ./zlib.tar.gz \
    && cd /tmp/zlib-${ZLIB_VER} \
    && ls . \
    && ./configure --prefix=${ZLIB_PREFIX} \
    && make \
    && make install \
    && cd ${ZLIB_PREFIX} \
    && rm -rf ./share \
    && rm -rf ./lib/pkgconfig \
    && cd /home \
    && rm -f ./zlib.tar.gz \
    && rm -r /tmp/zlib-${ZLIB_VER} \
    && echo '---------------------------' 

WORKDIR = /home
ADD https://ftp.pcre.org/pub/pcre/pcre-${PCRE_VER}.tar.gz ./pcre.tar.gz
RUN echo ' - install pcre' \
    &&  tar -C /tmp -xf ./pcre.tar.gz \
    && cd /tmp/pcre-${PCRE_VER} \
    && ./configure \
    --disable-cpp \
    --prefix=${PCRE_PREFIX} \
    --enable-jit \
    --enable-utf \
    --enable-unicode-properties \
    && make \
    && make install \
    && cd ${PCRE_PREFIX} \
    && rm -rf ./bin \
    && rm -rf ./share \
    && rm  -f ./lib/*.la \
    && rm  -f ./lib/*pcreposix* \
    && rm -rf ./lib/pkgconfig \
    && cd /home \
    && rm -f ./pcre.tar.gz \
    && rm -r /tmp/pcre-${PCRE_VER} \
    && echo '---------------------------' 

# https://github.com/openresty/openresty-packaging/blob/master/deb/openresty-openssl/debian/rules

WORKDIR = /home
ADD https://www.openssl.org/source/openssl-${OPENSSL_VER}.tar.gz ./openssl.tar.gz
RUN echo ' - install openssl' \
   && echo '   ------------' \
   &&  tar -C /tmp -xf ./openssl.tar.gz \
   && cd /tmp/openssl-${OPENSSL_VER} \
   && if [ $(echo ${OPENSSL_VER} | cut -c 1-5) = "1.1.1" ] ; then \
        echo 'patching OpenSSL 1.1.1 for OpenResty' \
        && curl -s https://raw.githubusercontent.com/openresty/openresty/master/patches/openssl-1.1.1c-sess_set_get_cb_yield.patch | patch -p1 ; \
   fi \
   && ./config no-threads shared enable-ssl3 enable-ssl3-method \
    --prefix=${OPENSSL_PREFIX} \
    --libdir=lib \
    shared zlib \
    -I${ZLIB_INC} \
    -L${ZLIB_LIB} \
    -Wl,-rpath,${ZLIB_LIB}:${OPENSSL_LIB} \
    && make \
    && make install_sw \
    && cd ${OPENSSL_PREFIX} \
    && rm -rf ./bin//bin/c_rehash \
    && rm -rf ./lib/pkgconfig \
    && cd /home \
    && rm -f ./openssl.tar.gz \
    && rm -r /tmp/openssl-${OPENSSL_VER} \
    && echo '---------------------------' 

WORKDIR = /home
ADD https://openresty.org/download/openresty-${OPENRESTY_VER}.tar.gz ./openresty.tar.gz
RUN echo    ' - install openresty' \
    && echo '   -----------------' \
    &&  tar -C /tmp -xf ./openresty.tar.gz \
    && mv /tmp/openresty-$OPENRESTY_VER /tmp/openresty \
    && cd /tmp/openresty \
    && ./configure \
    --prefix=${PREFIX} \
    --with-cc-opt="-DNGX_LUA_ABORT_AT_PANIC -I${OPENSSL_INC} -I${PCRE_INC} -I${ZLIB_INC}" \
    --with-ld-opt="-L${PCRE_LIB} -L${OPENSSL_LIB} -L${ZLIB_LIB} -Wl,-rpath,${PCRE_LIB}:${OPENSSL_LIB}:${ZLIB_LIB}" \
    --with-pcre \
    --with-pcre-jit \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-threads \
    --without-http_auth_basic_module \
    --without-http_empty_gif_module \
    --without-http_fastcgi_module \
    --without-http_memcached_module \
    --without-http_rds_csv_module \
    --without-http_rds_json_module \
    --without-http_redis_module \
    --without-http_scgi_module \
    --without-http_ssi_module \
    --without-http_uwsgi_module \
    --without-lua_rds_parser \
    --without-mail_imap_module \
    --without-mail_pop3_module \
    --without-mail_smtp_module \
    --http-log-path=/dev/stdout \
    --error-log-path=/dev/stderr \
    && make \
    && make install \
    && cd ${PREFIX}    && echo '   ---------------' \
    && rm -rf ./luajit/share/man \
    && rm -rf ./luajit/lib/libluajit-5.1.a \
    && cd /home \
    && rm -f ./openresty.tar.gz \
    && rm -r /tmp/openresty \
    && echo '---------------------------'  


WORKDIR = /home
ADD https://github.com/commonmark/cmark/archive/${CMARK_VER}.tar.gz ./cmark.tar.gz
RUN echo    ' - install cmark' \
    && echo '   ---------------' \
    && apk add --update cmake \
    && tar -C /tmp -xf ./cmark.tar.gz \
    && cd /tmp/cmark-${CMARK_VER} \
    && cmake \
    && make install \
    && cd /home \
    && rm -f ./cmark.tar.gz \
    && rm -r /tmp/cmark-${CMARK_VER} \
    && echo '---------------------------' \
    && echo ' -  FINISH ' \
    && echo '   --------' \
    && echo ' -  remove apk install deps' \
    && apk del .build-deps \
    && echo '---------------------------'  


FROM alpine:3.11 as dev

COPY --from=bld /usr/local /usr/local
RUN --mount=type=cache,target=/var/cache/apk \ 
    ln -s /var/cache/apk /etc/apk/cache \
    && apk add \
        gd \
        geoip \
        libgcc \
        libxslt \
        perl \
        curl \
    && echo ' - create special directories' \
    && mkdir -p /etc/letsencrypt/live \
    && mkdir -p /usr/local/openresty/nginx/html/.well-known/acme-challenge \
    && mkdir -p /usr/local/openresty/site/lualib/grantmacken \
    && mkdir -p /usr/local/openresty/site/t \
    && mkdir -p /usr/local/openresty/site/bin \
    && ln -s /usr/local/openresty/bin/* /usr/local/bin/ \
    && opm get ledgetech/lua-resty-http \
    && opm get SkyLothar/lua-resty-jwt \
    && opm get bungle/lua-resty-reqargs

ENV OPENRESTY_HOME /usr/local/openresty
ENV LANG C.UTF-8
WORKDIR /usr/local/openresty
EXPOSE 80 443
STOPSIGNAL SIGTERM
ENTRYPOINT ["bin/openresty", "-g", "daemon off;"]

FROM alpine:3.11 as min
COPY --from=dev /usr/local/openresty /usr/local/openresty
RUN --mount=type=cache,target=/var/cache/apk \ 
    ln -vs /var/cache/apk /etc/apk/cache \
    && apk add --update libgcc gd geoip libxslt \
    && mkdir -p /etc/letsencrypt/live

ENV OPENRESTY_HOME /usr/local/openresty
ENV LANG C.UTF-8
WORKDIR /usr/local/openresty
EXPOSE 80 443
STOPSIGNAL SIGTERM
ENTRYPOINT ["bin/openresty", "-g", "daemon off;"]
