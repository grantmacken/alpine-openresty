build-dev: export RESTY_VERSION := $(shell \
 curl -sSL https://openresty.org/en/download.html |\
 grep -oE 'openresty-([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)' |\
 sed 's/openresty-//' |\
 head -1)
build-dev:
	@docker build \
 --target="dev" \
 --tag="$(DOCKER_IMAGE):dev" \
 --tag="$(DOCKER_IMAGE):dev-v$$RESTY_VERSION" \
 .
