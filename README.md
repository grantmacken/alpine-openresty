# alpine-openresty
[WIP] minimal docker image for openresty

[![](https://images.microbadger.com/badges/image/grantmacken/alpine-openresty.svg)](https://microbadger.com/images/grantmacken/alpine-openresty "Get your own image badge on microbadger.com")
[![Build Status](https://travis-ci.org/grantmacken/alpine-openresty.svg?branch=master)](https://travis-ci.org/grantmacken/alpine-openresty)

This is a base openresty slim container
to be used as the FROM basis for other containers
or for defining services in a docker-compose.yml file

This repo docker-compose.yml published port is 8282

```
docker-compose config
docker-compose up -d
w3m -dump http://localhost:8282
firefox  http://localhost:8282
docker-compose down
```
