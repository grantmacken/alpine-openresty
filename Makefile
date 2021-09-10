SHELL=/bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
include .env
LAST_ALPINE_VER != grep -oP '^FROM docker.io/alpine:\K[\d\.]+' Dockerfile | head -1
PROXY_IMAGE=$(GHPKG_REGISTRY)/$(REPO_OWNER)/$(REPO_NAME):$(GHPKG_VER)
RESTY_IMAGE=$(GHPKG_REGISTRY)/$(REPO_OWNER)/$(REPO_NAME):resty-$(GHPKG_VER)
OPM_IMAGE=$(GHPKG_REGISTRY)/$(REPO_OWNER)/$(REPO_NAME):opm-$(GHPKG_VER)

# default
.PHONY: proxy
proxy: opm ## proxy version is without resty-cli opm and associated curl lib
	@podman build \
  --target=proxy \
  --tag docker.io/$(REPO_OWNER)/$(REPO_NAME):$(OPENRESTY_VER) \
	--tag $(PROXY_IMAGE) \
  --build-arg PREFIX='$(OPENRESTY_HOME)' \
  --build-arg OPENRESTY_VER='$(OPENRESTY_VER)' \
  --build-arg ZLIB_VER='$(ZLIB_VER)' \
  --build-arg PCRE_VER='$(PCRE_VER)' \
  --build-arg OPENSSL_VER='$(OPENSSL_VER)' \
  --build-arg OPENSSL_PATCH_VER="$(OPENSSL_PATCH_VER)" \
  --build-arg CMARK_VER='$(CMARK_VER)' \
 .

.PHONY: opm
opm: resty ## fat version with resty-cli associated curl lib
	@podman build \
	--tag $(OPM_IMAGE) \
  --target=opm \
  --build-arg PREFIX='$(OPENRESTY_HOME)' \
  --build-arg OPENRESTY_VER='$(OPENRESTY_VER)' \
  --build-arg ZLIB_VER='$(ZLIB_VER)' \
  --build-arg PCRE_VER='$(PCRE_VER)' \
  --build-arg OPENSSL_VER='$(OPENSSL_VER)' \
  --build-arg OPENSSL_PATCH_VER="$(OPENSSL_PATCH_VER)" \
  --build-arg CMARK_VER='$(CMARK_VER)' \
 .

.PHONY: resty
resty: bld ## fat version with resty-cli associated curl lib
	@podman build \
	--tag $(RESTY_IMAGE) \
  --target=resty \
  --build-arg PREFIX='$(OPENRESTY_HOME)' \
  --build-arg OPENRESTY_VER='$(OPENRESTY_VER)' \
  --build-arg ZLIB_VER='$(ZLIB_VER)' \
  --build-arg PCRE_VER='$(PCRE_VER)' \
  --build-arg OPENSSL_VER='$(OPENSSL_VER)' \
  --build-arg OPENSSL_PATCH_VER="$(OPENSSL_PATCH_VER)" \
  --build-arg CMARK_VER='$(CMARK_VER)' \
 .

.PHONY: bld
bld:
	@podman build \
  --target=bld \
  --build-arg PREFIX='$(OPENRESTY_HOME)' \
  --build-arg OPENRESTY_VER='$(OPENRESTY_VER)' \
  --build-arg ZLIB_VER='$(ZLIB_VER)' \
  --build-arg PCRE_VER='$(PCRE_VER)' \
  --build-arg OPENSSL_VER='$(OPENSSL_VER)' \
  --build-arg CMARK_VER='$(CMARK_VER)' \
  --build-arg OPENSSL_PATCH_VER="$(OPENSSL_PATCH_VER)" \
 .

.PHONY: alpine-version
alpine-version:
	@echo 'LAST ALPINE VERSION: $(LAST_ALPINE_VER)'
	@if [[ '$(LAST_ALPINE_VER)' = '$(FROM_ALPINE_TAG)' ]]
	then
	echo 'FROM_ALPINE_TAG: $(FROM_ALPINE_TAG)'
	else
	echo ' - updating Dockerfile to Alpine tag: $(FROM_ALPINE_TAG)'
	sed -i 's/alpine:$(LAST_ALPINE_VER)/alpine:$(FROM_ALPINE_TAG)/g' Dockerfile
	fi

 # podman run -i --rm $(RESTY_IMAGE)
.PHONY: run-resty 
run-resty:
	@podman run --interactive --rm $(RESTY_IMAGE) --help
	@podman run --interactive --rm $(RESTY_IMAGE) -e $$(cat <<EOF
	print('$(PROXY_IMAGE)')
	EOF
	)

.PHONY: run-opm 
run-opm:
	@podman run --interactive --rm $(OPM_IMAGE) --help
