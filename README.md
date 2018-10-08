# alpine-openresty
[WIP] alpine docker image for openresty

[![](https://images.microbadger.com/badges/image/grantmacken/alpine-openresty.svg)](https://microbadger.com/images/grantmacken/alpine-openresty "Get your own image badge on microbadger.com")
[![Build Status](https://travis-ci.org/grantmacken/alpine-openresty.svg?branch=master)](https://travis-ci.org/grantmacken/alpine-openresty)

openresty alpine docker images built from source


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

## pack

As well as building openresty it contains 
the tools required to running
 - OPM the openresty package manager 
 - Nginx::Test the openresty data driven test framework.


## base

This adds some OPM modules

## dev

This creates my WIP development environment from my dorex repo

It adds my own WIP lua modules that used when working with the eXist data store




 





