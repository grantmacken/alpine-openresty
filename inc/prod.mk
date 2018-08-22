build-prod: export RESTY_VERSION := $(shell \
 curl -sSL https://openresty.org/en/download.html |\
 grep -oE 'openresty-([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)' |\
 sed 's/openresty-//' |\
 head -1)
build-prod:
	@echo "## $@ ##"
	@echo "TASK: build the docker production image[ v$$RESTY_VERSION ] "
	@docker build \
 --target="prod" \
 --tag="$(DOCKER_IMAGE)" \
 --tag="$(DOCKER_IMAGE):v$$RESTY_VERSION" \
 --tag="$(DOCKER_IMAGE):prod" \
 --tag="$(DOCKER_IMAGE):prod:v$$RESTY_VERSION" \
 .
