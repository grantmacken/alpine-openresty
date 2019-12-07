# alpine-openresty
alpine docker image for openresty

openresty alpine docker image built from source

This repo represents is my current working environment,
and as such, it is not the smallest possible image. 

It provides a base image from which I create my *development*
and *production* images

As well as building openresty, the image contains 
 - additional packages I use via OPM the openresty package manager 
    1. ledgetech/lua-resty-http
    2. SkyLothar/lua-resty-jwt
    3. bungle/lua-resty-reqargs
<!--  - Nginx::Test the openresty data driven test framework. -->
 - a [commonmark](https://github.com/commonmark/CommonMark) implementaion [cmark](https://github.com/commonmark/cmark)






