DOCKER_IMAGE := grantmacken/alpine-openresty
GH_PRE := ^git@github\.com:
GH_SUB := https://github.com/
GH_SUF := \.git$
TAR_SUF := s/\(\.tar\.gz\)*$$//
T := tmp
SUDO_USER := $(shell echo "$${SUDO_USER}")
WHOAMI    := $(shell whoami)
INSTALLER := $(if $(SUDO_USER),$(SUDO_USER),$(WHOAMI))
OR_LATEST := $(T)/openresty-latest.version

.SECONDARY:

# TARGETS

default: $(T)/install.log

build: VERSION
	@echo "## $@ ##"
	@echo 'TASK: build the docker image'
	@docker build \
 --tag="$(DOCKER_IMAGE)" \
 .

push:
	@docker push $(DOCKER_IMAGE):latest

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
	@echo 'Task: download latest openresty version'
	@curl -sSL https://openresty.org/download/$(shell cat $<).tar.gz | \
 tar xz --directory $(T)
	@cd $(T);if [ -d $(shell cat $<) ] ; then echo " - downloaded [ $(shell cat $<) ] "; else false;fi;
	@echo '------------------------------------------------'

$(T)/openssl-latest.version:
	@echo " $(notdir $@) "
	@echo 'TASK:  fetch the latest openssl version'
	@curl -sSL https://www.openssl.org/source/ | \
 grep -oE 'openssl-(\d\.\d\.[2-9]{1}[a-z]{1})\.tar\.gz' | \
 head -1 | sed -e '$(TAR_SUF)'  > $(@)
	@if [ -n "$$( cat $@ )" ] ; then echo " - obtained version [ $$( cat $@ ) ] "; else false;fi;
	@echo '----------------------------'

#note the prefix 'openssl-'

downloadOpenssl: $(T)/openssl-latest.version
	@echo "# $(notdir $@) #"
	@echo 'Task: download: [ https://www.openssl.org/source/$(shell cat $<).tar.gz ] '
	@curl -sSL https://www.openssl.org/source/$(shell cat $<).tar.gz | \
 tar xz --directory $(T)
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
	@echo "$(notdir $@) "
	@echo 'Task: download latest pcre version'
	@curl -sSL https://ftp.pcre.org/pub/pcre/$(shell cat $<).tar.gz | \
 tar xz --directory $(T)
	@cd $(T);if [ -d $(shell cat $<) ] ; then echo " - downloaded [ $(shell cat $<) ] "; else false;fi;
	@echo '------------------------------------------------'

$(T)/zlib-latest.version:
	@echo "$(notdir $@) "
	@echo 'Task: fetch the latest zlib version'
	@ curl -sSL http://zlib.net/ |\
 grep -oE 'zlib-[0-9\.]+\.tar\.gz' |\
 head -1 | sed -e '$(TAR_SUF)' > $(@)
	@if [ -n "$$( cat $@ )" ] ; then echo " - obtained version [ $$( cat $@ ) ] "; else false;fi;
	@echo '------------------------------------------------'

downloadZlib: $(T)/zlib-latest.version
	@echo "$(notdir $@) "
	@echo 'Task: download the latest zlib version'
	@curl -sSL http://zlib.net/$(shell cat $<).tar.gz | \
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
 --with-file-aio \
 --with-http_v2_module \
 --with-http_ssl_module \
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


