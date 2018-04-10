# alpine-openresty
[WIP] minimal docker image for openresty

[![](https://images.microbadger.com/badges/image/grantmacken/alpine-openresty.svg)](https://microbadger.com/images/grantmacken/alpine-openresty "Get your own image badge on microbadger.com")
[![Build Status](https://travis-ci.org/grantmacken/alpine-openresty.svg?branch=master)](https://travis-ci.org/grantmacken/alpine-openresty)

This is a base openresty slim  docker image
to be used as the FROM basis for other images
or for defining services in a docker-compose.yml file

Clone  or Fork this repo

```
make build
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

