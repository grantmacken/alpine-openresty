SHELL=/bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
include .env
LAST_ALPINE_VER != grep -oP '^FROM alpine:\K[\d\.]+' Dockerfile | head -1
PROXY_IMAGE=docker.pkg.github.com/$(REPO_OWNER)/$(REPO_NAME)/$(PROXY_CONTAINER_NAME):$(PROXY_VER)

.PHONY: build
build: dev
	@docker buildx build -o type=docker \
  --tag $(DOCKER_IMAGE):$(OPENRESTY_VER) \
  --tag docker.pkg.github.com/$(REPO_OWNER)/$(REPO_NAME)/$(PROXY_CONTAINER_NAME):$(PROXY_VER) \
  --build-arg PREFIX='$(OPENRESTY_HOME)' \
  --build-arg OPENRESTY_VER='$(OPENRESTY_VER)' \
  --build-arg ZLIB_VER='$(ZLIB_VER)' \
  --build-arg PCRE_VER='$(PCRE_VER)' \
  --build-arg OPENSSL_VER='$(OPENSSL_VER)' \
  --build-arg CMARK_VER='$(CMARK_VER)' \
  --build-arg OPENSSL_PATCH_VER="$(OPENSSL_PATCH_VER)" \
 .

.PHONY: dev
dev: bld
	@docker buildx build -o type=docker \
  --target=dev \
  --build-arg PREFIX='$(OPENRESTY_HOME)' \
  --build-arg OPENRESTY_VER='$(OPENRESTY_VER)' \
  --build-arg ZLIB_VER='$(ZLIB_VER)' \
  --build-arg PCRE_VER='$(PCRE_VER)' \
  --build-arg OPENSSL_VER='$(OPENSSL_VER)' \
  --build-arg CMARK_VER='$(CMARK_VER)' \
  --build-arg OPENSSL_PATCH_VER="$(OPENSSL_PATCH_VER)" \
 .

.PHONY: bld
bld:
	@echo '$(DOCKER_IMAGE)'
	@echo 'LAST ALPINE VERSION: $(LAST_ALPINE_VER) '
	@if [[ '$(LAST_ALPINE_VER)' = '$(FROM_ALPINE_TAG)' ]] ; then \
 echo 'FROM_ALPINE_TAG: $(FROM_ALPINE_TAG) ' ; else \
 echo ' - updating Dockerfile to Alpine tag: $(FROM_ALPINE_TAG) ' && \
 sed -i 's/alpine:$(LAST_ALPINE_VER)/alpine:$(FROM_ALPINE_TAG)/g' Dockerfile && \
 docker pull alpine:$(FROM_ALPINE_TAG) ; fi
	@docker buildx build -o type=docker \
  --target=bld \
  --build-arg PREFIX='$(OPENRESTY_HOME)' \
  --build-arg OPENRESTY_VER='$(OPENRESTY_VER)' \
  --build-arg ZLIB_VER='$(ZLIB_VER)' \
  --build-arg PCRE_VER='$(PCRE_VER)' \
  --build-arg OPENSSL_VER='$(OPENSSL_VER)' \
  --build-arg CMARK_VER='$(CMARK_VER)' \
  --build-arg OPENSSL_PATCH_VER="$(OPENSSL_PATCH_VER)" \
 .

dkrNetworkInUse != docker network list --format '{{.Name}}' | grep -oP "$(NETWORK)"

.PHONY: run
run:
	@$(if $(dkrNetworkInUse),echo  '- NETWORK [ $(NETWORK) ] is available',docker network create $(NETWORK))
	@docker run \
  --name $(PROXY_CONTAINER_NAME) \
  --publish 80:80 \
  --network $(NETWORK) \
  --detach \
  docker.pkg.github.com/$(REPO_OWNER)/$(REPO_NAME)/$(PROXY_CONTAINER_NAME):$(PROXY_VER)
	@sleep 3
	@docker ps
	@docker logs $(PROXY_CONTAINER_NAME)

.PHONY: stop
stop:
	@docker stop $(PROXY_CONTAINER_NAME)
