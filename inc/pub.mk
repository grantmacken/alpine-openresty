
push: 
	$(MAKE) push-prod
	$(MAKE) push-dev

push-prod: export RESTY_VERSION := $(shell \
 curl -sSL https://openresty.org/en/download.html |\
 grep -oE 'openresty-([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)' |\
 sed 's/openresty-//' |\
 head -1)
push-prod:
	@echo "## $@ ##"
	@docker push $(DOCKER_IMAGE):latest
	@docker push $(DOCKER_IMAGE):prod
	@docker push $(DOCKER_IMAGE):v$$RESTY_VERSION

push-dev: export RESTY_VERSION := $(shell \
 curl -sSL https://openresty.org/en/download.html |\
 grep -oE 'openresty-([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)' |\
 sed 's/openresty-//' |\
 head -1)
push-dev:
	@echo "## $@ ##"
	@docker push $(DOCKER_IMAGE):dev
	@docker push $(DOCKER_IMAGE):dev:v$$RESTY_VERSION

pull:
	@echo "## $@ ##"
	@docker pull $(DOCKER_IMAGE):latest

