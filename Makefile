SHELL=/bin/bash
include .env

# DOCKER_PKG_GITHUB=docker.pkg.github.com/$(REPO_OWNER)/$(REPO_NAME)/min:$(OPENRESTY_VER)
# Release links
# https://github.com/openresty/docker-openresty/blob/master/alpine/Dockerfile
# https://github.com/openssl/openssl/releases
# https://www.pcre.org/  - always uses 8.3
# https://www.zlib.net/
# https://github.com/commonmark/cmark/releases
# https://help.github.com/en/actions/automating-your-workflow-with-github-actions/using-environment-variables#default-environment-variables
ifndef GITHUB_ACTION
LUAJIT_OPT :='-msse4a'
endif
LAST_ALPINE_VER != grep -oP '^FROM alpine:\K[\d\.]+' Dockerfile | head -1

.PHONY: build
build: dev
	@export DOCKER_BUILDKIT=1;
	@docker buildx build -o type=docker \
  --tag $(DOCKER_IMAGE):min-$(OPENRESTY_VER) \
  --tag docker.pkg.github.com/$(REPO_OWNER)/$(REPO_NAME)/$(PROXY_CONTAINER_NAME):$(PROXY_VER) \
  --build-arg PREFIX='$(OPENRESTY_HOME)' \
  --build-arg OPENRESTY_VER='$(OPENRESTY_VER)' \
  --build-arg ZLIB_VER='$(ZLIB_VER)' \
  --build-arg PCRE_VER='$(PCRE_VER)' \
  --build-arg OPENSSL_VER='$(OPENSSL_VER)' \
  --build-arg CMARK_VER='$(CMARK_VER)' \
  --build-arg LUAJIT_OPT="$(LUAJIT_OPT)" \
 .

.PHONY: dev
dev:
	@export DOCKER_BUILDKIT=1;
	@echo '$(DOCKER_IMAGE)'
	@export DOCKER_BUILDKIT=1;
	@echo 'LAST ALPINE VERSION: $(LAST_ALPINE_VER) '
	@if [[ '$(LAST_ALPINE_VER)' = '$(FROM_ALPINE_TAG)' ]] ; then \
 echo 'FROM_ALPINE_TAG: $(FROM_ALPINE_TAG) ' ; else \
 echo ' - updating Dockerfile to Alpine tag: $(FROM_ALPINE_TAG) ' && \
 sed -i 's/alpine:$(LAST_ALPINE_VER)/alpine:$(FROM_ALPINE_TAG)/g' Dockerfile && \
 docker pull alpine:$(FROM_ALPINE_TAG) ; fi
	@docker buildx build -o type=docker \
  --target=dev \
  --tag='$(DOCKER_IMAGE):dev-$(OPENRESTY_VER)' \
  --build-arg PREFIX='$(OPENRESTY_HOME)' \
  --build-arg OPENRESTY_VER='$(OPENRESTY_VER)' \
  --build-arg ZLIB_VER='$(ZLIB_VER)' \
  --build-arg PCRE_VER='$(PCRE_VER)' \
  --build-arg OPENSSL_VER='$(OPENSSL_VER)' \
  --build-arg CMARK_VER='$(CMARK_VER)' \
  --build-arg LUAJIT_OPT="$(LUAJIT_OPT)" \
 .

# .PHONY: bld
# bld:
# 	@echo '$(DOCKER_IMAGE)'
# 	@export DOCKER_BUILDKIT=1;
# 	@echo 'LAST ALPINE VERSION: $(LAST_ALPINE_VER) '
# 	@if [[ '$(LAST_ALPINE_VER)' = '$(FROM_ALPINE_TAG)' ]] ; then \
#  echo 'FROM_ALPINE_TAG: $(FROM_ALPINE_TAG) ' ; else \
#  echo ' - updating Dockerfile to Alpine tag: $(FROM_ALPINE_TAG) ' && \
#  sed -i 's/alpine:$(LAST_ALPINE_VER)/alpine:$(FROM_ALPINE_TAG)/g' Dockerfile && \
#  docker pull alpine:$(FROM_ALPINE_TAG) ; fi
# 	@docker buildx build -o type=docker \
#   --target=bld \
#   --tag='$(DOCKER_IMAGE):bld' \
#   --build-arg PREFIX='$(OPENRESTY_HOME)' \
#   --build-arg OPENRESTY_VER='$(OPENRESTY_VER)' \
#   --build-arg ZLIB_VER='$(ZLIB_VER)' \
#   --build-arg PCRE_VER='$(PCRE_VER)' \
#   --build-arg OPENSSL_VER='$(OPENSSL_VER)' \
#   --build-arg CMARK_VER='$(CMARK_VER)' \
#   --build-arg LUAJIT_OPT="$(LUAJIT_OPT)" \
#  .




dkrStatus != docker ps --filter name=orMin --format 'status: {{.Status}}'
dkrPortInUse != docker ps --format '{{.Ports}}' | grep -oP '^(.+):\K(\d{4})' | grep -oP "80"
dkrNetworkInUse != docker network list --format '{{.Name}}' | grep -oP "$(NETWORK)"

.PHONY: run
run:
	@$(if $(dkrNetworkInUse),echo  '- NETWORK [ $(NETWORK) ] is available',docker network create $(NETWORK))
	@$(if $(dkrPortInUse), echo '- PORT [ 80 ] is already taken';false , echo  '- PORT [ 80 ] is available')
	@docker run \
  --name min \
  --publish 80:80 \
  --network $(NETWORK) \
  --detach \
  docker.pkg.github.com/$(REPO_OWNER)/$(REPO_NAME)/$(PROXY_CONTAINER_NAME):$(PROXY_VER)
	@sleep 3
	@docker ps
	@docker logs min



.PHONY: stop
stop:
	@docker stop min
