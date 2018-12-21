# alpine-openresty
[WIP] alpine docker image for openresty

[![](https://images.microbadger.com/badges/image/grantmacken/alpine-openresty.svg)](https://microbadger.com/images/grantmacken/alpine-openresty "Get your own image badge on microbadger.com")
[![Build Status](https://travis-ci.org/grantmacken/alpine-openresty.svg?branch=master)](https://travis-ci.org/grantmacken/alpine-openresty)

openresty alpine docker images built from source

This repo represents is my current working environment,
and as such, it is not the smallest possible image.



Clone or Fork this repo

```
docker build --target=pack .
docker build --target=base .
docker build --target=dev .
```

You might want to change some openresty 
 [ --with --without ]
configure options in the Makefile to fit your requirement.

From the base alpine image, 
the latest versions for 
- openresty, 
- pcre, 
- zlib, 
- openssl 

are obtained then source tar.gz files are downloaded. 
Openresty is then configured and made from these sources.

In this repo the docker-compose.yml published port is 80 443

```
docker-compose config
docker-compose up -d
w3m -dump http://localhost:80
firefox  http://localhost:80
docker-compose down
```

## Build Targets

The image can be run as a container service in a desktop dev 
environment or in a cloud server environment.

The docker image build has three stages

1. pack: 
2. base
3. dev

## pack

As well as building openresty, the image contains 
the tools required to run
 - OPM the openresty package manager 
 - Nginx::Test the openresty data driven test framework.
 - a [commonmark](https://github.com/commonmark/CommonMark) implementaion [cmark](https://github.com/commonmark/cmark)

## base

This target adds some OPM modules

1. pintsized/lua-resty-http
2. SkyLothar/lua-resty-jwt
3. bungle/lua-resty-reqargs

## dev

This target creates my WIP development environment from my dorex repo

1. In `./nginx/conf`  my own nginx conf files are added
1. In `./site/lualib/`  adds directory based on my git.user handle
  In this own WIP lua modules that I use when working with the eXist database are added.
2. In `./site/`  adds bin directory. My WIP cli resty cli scripts are added here.
   e.g.  `docker exec or site/bin/xQinfo` will print out my eXist docker enviroment 
2. In `./`  adds t directory.  My tests are contained in this directory. 
   e.g. `docker exec or prove t/proxy/lualib/req.t` will run tests for my req lualib

 





