SHELL=/bin/bash
include ../../.env
include .env
T := .tmp
B := .build
COMMA := ,
EMPTY :=
SPACE := $(EMPTY) $(EMPTY)
DELIMIT := $(COMMA)$(EMPTY)
PROXY_IMAGE := docker.pkg.github.com/$(REPO_OWNER)/$(REPO_NAME)/$(PROXY_CONTAINER_NAME):$(PROXY_VER)

.PHONY: build
build: clean \
 $(B)/Dockerfile \
 $(B)/nginx/conf/certs.conf \
 $(patsubst %,$(B)/nginx/%, $(wildcard conf/*))
	@echo '## $(@) ##'
	@cd $(B); docker build --tag=$(PROXY_IMAGE) .
	@docker images | grep '$(PROXY_CONTAINER_NAME)'

.PHONY: push
push:
	echo $${{ secrets.GITHUB_TOKEN }} | docker login docker.pkg.github.com --username $${{ secrets.DOCKER_USERNAME }} --password-stdin
	docker push $(PROXY_IMAGE)

.PHONY: rebuild
rebuild:
	@echo '## $(@)  ##'
	cd $(B) && docker build --tag=$(PROXY_IMAGE) .

.PHONY: run
run:
	@$(if $(dkrPortInUse), echo '- PORT [ 80 ] is already taken';false , echo  '- PORT [ 80 ] is available')
	@docker run --rm --name orTest --publish 80:80 --detach $(PROXY_IMAGE)

.PHONY: stop
stop:
	@docker stop orTest

.PHONY: clean
clean:
	@echo '## $(@)  $(B) ##'
	@rm -rf $(B)

.PHONY: clean-volume
clean-volume:
	@echo '## $(@)  ##'
	@echo 'remove previous nginx config volume'
	@docker volume remove nginx-configuration

.PHONY: clean-images
clean-images:
	@echo '## $(@) ##'
	@#docker ps -a
	@#docker images -a | grep "dev" | awk '{print $$3}' | xargs docker rmi
	@#$(if docker images -f 'dangling=true' -q,docker image prune,true)
	@$(if docker images -a | grep '15.8',docker images -a | grep '15.8' |  awk '{print $$3}' | xargs docker rmi,)  
	@#$(if docker images -a | grep 'none',docker images -a | grep 'none' |  awk '{print $$3}' | xargs docker rmi,)  

define mkDockerfile
FROM  $(PROXY_IMAGE_FROM) as proxy
RUN  rm $(OPENRESTY_HOME)/nginx/conf/*
COPY ./nginx/conf  $(OPENRESTY_HOME)/nginx/conf
# add env vars
ENV PROXY_CONTAINER_NAME $(PROXY_CONTAINER_NAME)
ENV XQERL_CONTAINER_NAME $(XQERL_CONTAINER_NAME)
ENV XQERL_PORT $(XQERL_PORT)
endef

define mkCertsConf
ssl_certificate         $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/fullchain.pem;
ssl_certificate_key     $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/privkey.pem;
ssl_trusted_certificate $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/chain.pem;
endef

$(B)/Dockerfile: export mkDockerfile:=$(mkDockerfile)
$(B)/Dockerfile:
	@echo '## $(@) ##'
	@mkdir -p $(dir $@)
	@echo "$${mkDockerfile}" > $@

$(B)/nginx/conf/certs.conf: export mkCertsConf:=$(mkCertsConf)
$(B)/nginx/conf/certs.conf:
	@echo '## $(@) ##'
	@mkdir -p $(dir $@)
	@echo "$${mkCertsConf}" > $@

$(B)/nginx/conf/%: conf/%
	@echo '## $(@) ##'
	@mkdir -p $(dir $@)
	@cp $< $@

PHONY: docker-lint
docker-lint: Dockerfile
	@docker run --rm -i hadolint/hadolint < $<


