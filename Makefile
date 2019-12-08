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

dkrStatus != docker ps --filter name=orMin --format 'status: {{.Status}}'
dkrPortInUse != docker ps --format '{{.Ports}}' | grep -oP '^(.+):\K(\d{4})' | grep -oP "80"
dkrNetworkInUse != docker network list --format '{{.Name}}' | grep -oP "$(NETWORK)"

.PHONY: run
run: | network
	@$(if $(dkrNetworkInUse),echo  '- NETWORK [ $(NETWORK) ] is available',docker network create $(NETWORK))
	@$(if $(dkrPortInUse), echo '- PORT [ 80 ] is already taken';false , echo  '- PORT [ 80 ] is available')
	@docker run \
  -it --rm \
  --name orMin \
  --network www \
  --publish 80:80 \
  --detach \
 $(DOCKER_IMAGE):$(DOCKER_TAG)
	@sleep 1
	@curl -s http://localhost/ 

.PHONY: stop
stop:
	@docker stop orMin 

define msgPort
    echo " - PORT [ $(XQERL_PORT) ] is already in use .. "
    echo " - Change .env PORT number"
    echo " - exiting ... "
    exit 1
endef





.PHONY: network 
network:
	$(if $(shell docker network list --format '{{.Name}}' | grep -oP "$(NETWORK)"),true,\
     docker network create $(NETWORK))

.PHONY: build
build: clean-build build/conf/gidday.conf build/Dockerfile build/docker-compose.yml
	@cd build; docker build \
 --tag='$(DOCKER_IMAGE):gidday' \
 .
	@docker images | grep -oP 'gidday'
	@cd build; docker-compose up -d
	@sleep 1
	@cd build; docker-compose logs
	@curl -s http://localhost
	@cd build; docker-compose down

.PHONY: clean-build
clean-build:
	@rm -rf build

define dkGidday
FROM $(DOCKER_IMAGE):min as proxy
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
    container_name: orGidday
    image: ${DOCKER_IMAGE}:gidday
    ports:
        - 80:80
        - 443:443
endef

build/conf/gidday.conf: export ngxConfGidday:=$(ngxConfGidday)
build/conf/gidday.conf:
	@mkdir -p $(dir $@)
	@echo "$${ngxConfGidday}" > $@

build/Dockerfile: export dkGidday:=$(dkGidday)
build/Dockerfile:
	@mkdir -p $(dir $@)
	@echo "$${dkGidday}" > $@

build/docker-compose.yml: export dcGidday:=$(dcGidday)
build/docker-compose.yml:
	@mkdir -p $(dir $@)
	@echo "$${dcGidday}" > $@


