# [alpine-openresty](https://github.com/grantmacken/alpine-openresty)



[![](https://github.com/grantmacken/alpine-xqerl/workflows/CI/badge.svg)](https://github.com/grantmacken/alpine-openresty/actions)

This repo provides a base image from which I create my *development* and *production* images

It has some minor adjustments to [official openresty alpine image](https://github.com/openresty/docker-openresty/blob/master/alpine/Dockerfile)

As well as building openresty, the image contains some stuff I find useful 
 - additional packages I use via OPM the openresty package manager 
    1. ledgetech/lua-resty-http
    2. SkyLothar/lua-resty-jwt
    3. bungle/lua-resty-reqargs
<!--  - Nginx::Test the openresty data driven test framework. -->
 - a [commonmark](https://github.com/commonmark/CommonMark) implementaion: [cmark](https://github.com/commonmark/cmark)


Available on [dockerhub](https://hub.docker.com/r/grantmacken/alpine-openresty)

[![dockeri.co](https://dockeri.co/image/grantmacken/alpine-openresty)](https://hub.docker.com/r/grantmacken/alpine-openresty)


