SHELL=/bin/bash
include .env


.PHONY: bld
bld:
	@echo '$(DOCKER_IMAGE)'
	@export DOCKER_BUILDKIT=1;
	@docker buildx build -o type=docker \
  --target=bld \
  --tag='$(DOCKER_IMAGE):bld' \
  --build-arg PREFIX='$(OPENRESTY_HOME)' \
  --build-arg OPENRESTY_VER='$(OPENRESTY_VER)' \
  --build-arg ZLIB_VER='$(ZLIB_VER)' \
  --build-arg PCRE_VER='$(PCRE_VER)' \
  --build-arg OPENSSL_VER='$(OPENSSL_VER)' \
  --build-arg CMARK_VER='$(CMARK_VER)' \
 .


.PHONY: dev
dev:
	@echo '$(DOCKER_IMAGE)'
	@export DOCKER_BUILDKIT=1;
	@docker buildx build -o type=docker \
  --target=dev \
  --tag='$(DOCKER_IMAGE):dev-$(OPENRESTY_VER)' \
  --tag='$(DOCKER_IMAGE):dev' \
  --build-arg PREFIX='$(OPENRESTY_HOME)' \
  --build-arg OPENRESTY_VER='$(OPENRESTY_VER)' \
  --build-arg ZLIB_VER='$(ZLIB_VER)' \
  --build-arg PCRE_VER='$(PCRE_VER)' \
  --build-arg OPENSSL_VER='$(OPENSSL_VER)' \
  --build-arg CMARK_VER='$(CMARK_VER)' \
 .

.PHONY: min
min:
	@export DOCKER_BUILDKIT=1;
	@docker buildx build -o type=docker \
  --target=min \
  --tag=$(DOCKER_IMAGE):min-$(OPENRESTY_VER) \
  --tag=$(DOCKER_IMAGE):min \
  --build-arg PREFIX='$(OPENRESTY_HOME)' \
  --build-arg OPENRESTY_VER='$(OPENRESTY_VER)' \
  --build-arg ZLIB_VER='$(ZLIB_VER)' \
  --build-arg PCRE_VER='$(PCRE_VER)' \
  --build-arg OPENSSL_VER='$(OPENSSL_VER)' \
  --build-arg CMARK_VER='$(CMARK_VER)' \
 .


.PHONY: build
build: clean-build build/conf/gidday.conf build/Dockerfile build/docker-compose.yml
	@docker build \
 --tag='$(OPENRESTY_IMAGE):gidday' \
 .
	@docker images | grep -oP 'gidday'
	@docker-compose up -d
	@sleep 1
	@docker-compose logs
	@curl -s http://localhost
	@docker-compose down

.PHONY: clean-build
clean-build:
	@rm -rf build

define dkGidday
FROM $(OPENRESTY_IMAGE):min as proxy
RUN rm nginx/conf/*
COPY ./conf/gidday.conf  $(OPENRESTY_HOME)/nginx/conf/nginx.conf
endef

define ngxConfGidday
worker_processes 1;
pcre_jit on;
events {
  multi_accept       on;
  worker_connections 1024;
  use                epoll;
}
http {
  lua_code_cache off;
  server {
    listen 80;
    server_name or;
    location / {
      content_by_lua_block {
        ngx.say('gidday from OpenResty lua content block')
      }
    }
 }
}
endef

define dcGidday
version: '3.7'
services:
  openresty:
    image: ${OPENRESTY_IMAGE}:gidday
    ports:
        - 80:80
        - 443:443
endef

build/conf/gidday.conf: export ngxConfGidday:=$(ngxConfGidday)
conf/gidday.conf:
	@mkdir -p $@
	@echo "$${mkGiddayConf}" > $@

build/Dockerfile: export dkGidday:=$(dkGidday)
Dockerfile:
	@echo "$${dkGidday}" > $@

build/docker-compose.yml: export dcGidday:=$(dcGidday)
docker-compose.yml:
	@echo "$${dcGidday}" > $@


