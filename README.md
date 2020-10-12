# [alpine-openresty](https://github.com/grantmacken/alpine-openresty)

[![](https://github.com/grantmacken/alpine-xqerl/workflows/CI/badge.svg)](https://github.com/grantmacken/alpine-openresty/actions)

This repo provides a base image from which I create my *development* and *production* images

It has some minor adjustments to [official openresty alpine image](https://github.com/openresty/docker-openresty/blob/master/alpine/Dockerfile)

As well as building openresty, the image contains some stuff I find useful 
 - additional packages I use via OPM the openresty package manager 
    1. [ledgetech/lua-resty-http](https://github.com/ledgetech/lua-resty-http)
    2. [cdbattags/lua-resty-jwt](https://github.com/cdbattags/lua-resty-jwt)
    3. [bungle/lua-resty-reqargs](https://github.com/bungle/lua-resty-reqargs)
<!--  - Nginx::Test the openresty data driven test framework. -->
 - a [commonmark](https://github.com/commonmark/CommonMark) implementaion: [cmark](https://github.com/commonmark/cmark)

Available on [dockerhub](https://hub.docker.com/r/grantmacken/alpine-openresty)

[![dockeri.co](https://dockeri.co/image/grantmacken/alpine-openresty)](https://hub.docker.com/r/grantmacken/alpine-openresty)

Note: The provided docker versions of openresty compile luajit with the [SSE_4.2 instruction set](https://en.wikipedia.org/wiki/SSE4)

```
grep flags  /proc/cpuinfo | grep -o sse4_2
```

 - [Github Actions](https://github.com/grantmacken/alpine-openresty/actions) compiles and runs OK! 
 - My [Google Compute Engine](https://cloud.google.com/compute) which uses [Container-Optimized OS](https://cloud.google.com/container-optimized-os) also runs the openresty container OK!

 However if you pull and try to run on an older computer openresty without the [SSE_4.2 instruction set](https://en.wikipedia.org/wiki/SSE4) which is the case in my local dev machine which has AMD's Barcelona CPU.  So to run the openresty container locally, I have build the image locally and get the compiler using AMD's Barcelona *SSE4a* instruction set, when it compiles luajit. 

When I run make, if *GITHUB_ACTION* is not defined, I set `LUAJIT_OPT :='-msse4a'` to pass as a docker ARG.

```
ifndef GITHUB_ACTION
LUAJIT_OPT :='-msse4a'
endif
```

If you have your computer CPU has [SEE4.2](https://en.wikipedia.org/wiki/SSE4) 
and you want to run `make` locally, just erase the above 3 lines from the Makefile 

<!--
# DOCKER_PKG_GITHUB=docker.pkg.github.com/$(REPO_OWNER)/$(REPO_NAME)/min:$(OPENRESTY_VER)
# Release links
# https://github.com/openresty/docker-openresty/blob/master/alpine/Dockerfile
# https://github.com/openssl/openssl/releases
# https://www.pcre.org/  - always uses 8.3
# https://www.zlib.net/
# https://github.com/commonmark/cmark/releases
# https://help.github.com/en/actions/automating-your-workflow-with-github-actions/using-environment-variables#default-environment-variables

 build-base \
       gd-dev \
       geoip-dev \
       libmaxminddb-dev \
       libxml2-dev \
       libxslt-dev \
       linux-headers \
       luajit-dev \
       openssl-dev \
       paxmark \
        pcre-dev \
       perl-dev \
       pkgconf \
       zlib-dev \
       gd \
       perl \
       perl-fcgi \
       perl-io-socket-ssl \
       perl-net-ssleay \
       perl-protocol-websocket \


-->


