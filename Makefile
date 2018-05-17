DOCKER_IMAGE := grantmacken/alpine-openresty
T := tmp
TAR_SUF := s/\(\.tar\.gz\)*$$//

OR_LATEST := $(T)/openresty-latest.version

define hOR
# openresty docker install

Multi stage docker build
 1: download source
 2: install from sources
 3: from base alpine copy over openresty

make targets

endef

.SECONDARY:

.PHONY: perlModules cmark

# TARGETS

orHelp: export HOR := $(hOR)
orHelp:
	@echo "$${HOR}"

default: orHelp

install: $(T)/install.log
	@$(MAKE) perlModules
	@$(MAKE) cmark

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
 --tag="$(DOCKER_IMAGE)-prod" \
 --tag="$(DOCKER_IMAGE)-prod:v$$RESTY_VERSION" \
 .

build-dev: export RESTY_VERSION := $(shell \
 curl -sSL https://openresty.org/en/download.html |\
 grep -oE 'openresty-([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)' |\
 sed 's/openresty-//' |\
 head -1)
build-dev:
	@docker build \
 --target="dev" \
 --tag="$(DOCKER_IMAGE)-dev" \
 --tag="$(DOCKER_IMAGE)-dev:v$$RESTY_VERSION" \
 .

push-prod: export RESTY_VERSION := $(shell \
 curl -sSL https://openresty.org/en/download.html |\
 grep -oE 'openresty-([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)' |\
 sed 's/openresty-//' |\
 head -1)
push-prod:
	@echo "## $@ ##"
	@docker push $(DOCKER_IMAGE):v$$RESTY_VERSION

push-dev: export RESTY_VERSION := $(shell \
 curl -sSL https://openresty.org/en/download.html |\
 grep -oE 'openresty-([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)' |\
 sed 's/openresty-//' |\
 head -1)
push-dev:
	@echo "## $@ ##"
	@docker push $(DOCKER_IMAGE)-dev
	@docker push $(DOCKER_IMAGE)-dev:v$$RESTY_VERSION

pull:
	@echo "## $@ ##"
	@docker pull $(DOCKER_IMAGE):latest

perlModules:
	@echo "# $(notdir $@) #"
	@wget -O - https://cpanmin.us | perl - App::cpanminus \
  &&  cpanm --skip-installed -n Test::Base IPC::Run Test::Nginx App::Prove

cmark:
	@echo "# $(notdir $@) #"
	@echo 'Task: download  [ https://github.com/commonmark/cmark/archive/0.28.3.tar.gz ]'
	@curl -sSL https://github.com/commonmark/cmark/archive/0.28.3.tar.gz | \
 tar xz --directory $(T)
	@cd $(T)/cmark-0.28.3; make && make install

$(OR_LATEST):
	@echo "# $(notdir $@) #"
	@echo 'Task: fetch the latest openresty version'
	@curl -sSL https://openresty.org/en/download.html |\
 grep -oE 'openresty-([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)' |\
 head -1 > $(@)
	@if [ -n "$$( cat $@ )" ] ; then echo " - obtained version [ $$( cat $@ ) ] "; else false;fi;
	@echo '------------------------------------------------'

downloadOpenresty: $(OR_LATEST)
	@echo "# $(notdir $@) #"
	@echo 'Task: download  [ https://openresty.org/download/$(shell cat $<).tar.gz ]'
	@curl -sSL https://openresty.org/download/$(shell cat $<).tar.gz | \
 tar xz --directory $(T)
	@cd $(T);if [ -d $(shell cat $<) ] ; then echo " - downloaded [ $(shell cat $<) ] "; else false;fi;
	@echo '------------------------------------------------'

$(T)/openssl-latest.version:
	@echo " $(notdir $@) "
	@echo 'TASK:  fetch the latest openssl version'
	@curl -sSL https://www.openssl.org/source/ | \
 grep -oE 'openssl-1.0.2[a-z]{1}\.tar\.gz' | \
 head -1 | sed -e '$(TAR_SUF)'  > $(@)
	@if [ -s $@ ] ; then echo " - obtained version [ $$( cat $@ ) ] "; else false;fi;
	@echo '----------------------------'

#note the prefix 'openssl-'

downloadOpenssl: $(T)/openssl-latest.version
	@echo "# $(notdir $@) #"
	@echo 'Task: download: [ https://www.openssl.org/source/$(shell cat $<).tar.gz ] '
	@curl -sSL https://www.openssl.org/source/$(shell cat $<).tar.gz | \
 tar xz --directory $(T)
	@cd $(T);if [ -d $(shell cat $<) ] ; then echo " - downloaded [ $(shell cat $<) ] "; else false;fi;
	@echo '------------------------------------------------'

$(T)/zlib-latest.version:
	@echo "# $(notdir $@) #"
	@echo 'Task: fetch the latest zlib version'
	@curl -sSL http://zlib.net/ |\
 grep -oE 'zlib-[0-9\.]+\.tar\.gz' |\
 head -1 | sed -e '$(TAR_SUF)' > $(@)
	@if [ -n "$$( cat $@ )" ] ; then echo " - obtained version [ $$( cat $@ ) ] "; else false;fi;
	@echo '------------------------------------------------'

downloadZlib: $(T)/zlib-latest.version
	@echo "# $(notdir $@) #"
	@echo 'Task:  download [ http://zlib.net/$(shell cat $<).tar.gz ] '
	@curl -sSL http://zlib.net/$(shell cat $<).tar.gz | tar xz --directory $(T)
	@cd $(T);if [ -d $(shell cat $<) ] ; then echo " - downloaded [ $(shell cat $<) ] "; else false;fi;
	@echo '------------------------------------------------'

# note: travis having difficulty with ftp try http
# note: for pcre source use tail

$(T)/pcre-latest.version:
	@echo "# $(notdir $@) #"
	@echo 'Task: fetch the latest pcre version'
	@curl -sSL https://ftp.pcre.org/pub/pcre/ |\
 grep -oE 'pcre-[0-9\.]+\.tar\.gz' |\
 tail -1 | sed -e '$(TAR_SUF)' > $(@)
	@if [ -n "$$( cat $@ )" ] ; then echo " - obtained version [ $$( cat $@ ) ] "; else false;fi;
	@echo '------------------------------------------------'

downloadPcre: $(T)/pcre-latest.version
	@echo "# $(notdir $@) #"
	@echo 'Task: download [ https://ftp.pcre.org/pub/pcre/$(shell cat $<).tar.gz ] '
	@curl -f -sSL https://ftp.pcre.org/pub/pcre/$(shell cat $<).tar.gz | \
 tar xz --directory $(T)
	@cd $(T);if [ -d $(shell cat $<) ] ; then echo " - downloaded [ $(shell cat $<) ] "; else false;fi;
	@echo '------------------------------------------------'

$(T)/configure.log: downloadOpenresty downloadOpenssl downloadZlib downloadPcre
	@echo "$(notdir $@) "
	@echo " - sanity checks "
	@[ -d $(T)/$(shell cat $(OR_LATEST)) ]
	@[ -d $(T)/$(shell cat $(T)/zlib-latest.version) ]
	@[ -d $(T)/$(shell cat $(T)/pcre-latest.version) ]
	@[ -d $(T)/$(shell cat $(T)/openssl-latest.version) ]
	@echo " - configure and install "
	@cd $(T)/$(shell cat $(OR_LATEST));\
 ./configure \
 --with-pcre="../$(shell cat $(T)/pcre-latest.version)" \
 --with-pcre-jit \
 --with-zlib="../$(shell cat $(T)/zlib-latest.version)" \
 --with-openssl="../$(shell cat $(T)/openssl-latest.version)" \
 --with-http_v2_module \
 --with-http_ssl_module \
 --with-http_gzip_static_module \
 --with-http_gunzip_module \
 --without-http_empty_gif_module \
 --without-http_memcached_module \
 --without-http_auth_basic_module \
 --without-http_fastcgi_module \
 --without-http_uwsgi_module \
 --without-http_ssi_module \
 --without-http_scgi_module >> configure.log 2>&1
	@echo '------------------------------------------------'

$(T)/make.log: $(T)/configure.log
	@echo "$(notdir $@) " &> $(@)
	@cd $(T)/$(shell cat $(OR_LATEST));\
 make -j$(shell grep ^proces /proc/cpuinfo | wc -l ) >> make.log 2>&1
	@echo '------------------------------------------------'

$(T)/install.log: $(T)/make.log
	@echo "$(notdir $@) " &> $(@)
	@cd $(T)/$(shell cat $(OR_LATEST)); make install | tee -a install.log
	@echo '------------------------------------------------'


