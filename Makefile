DOCKER_IMAGE := grantmacken/alpine-openresty
GH_PRE := ^git@github\.com:
GH_SUB := https://github.com/
GH_SUF := \.git$
TAR_SUF := s/\(\.tar\.gz\)*$$//
T := tmp
SUDO_USER := $(shell echo "$${SUDO_USER}")
WHOAMI    := $(shell whoami)
INSTALLER := $(if $(SUDO_USER),$(SUDO_USER),$(WHOAMI))
.SECONDARY:

# TARGETS

default: orInstall


build: VERSION
	@echo "## $@ ##"
	@echo 'TASK: build the docker image'
	@docker build \
 --tag="$(DOCKER_IMAGE)" \
 .

push:
	@docker push $(DOCKER_IMAGE):latest


$(T)/openresty-latest.version:
	@echo "# $(notdir $@) #"
	@echo 'Task: fetch the latest openresty version'
	@curl -sSL https://openresty.org/en/download.html |\
 grep -oE 'openresty-([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)' |\
 head -1 > $(T)/openresty-latest.version
	@cat $@
	@echo '----------------------------'

downloadOpenresty: $(T)/openresty-latest.version
	@echo "# $(notdir $@) #"
	@echo 'Task: download latest openresty version'
	@curl -sSL https://openresty.org/download/$(shell cat $<).tar.gz | \
 tar xz --directory $(T)
	@echo '----------------------------'

$(T)/openssl-latest.version:
	@echo " $(notdir $@) "
	@echo 'TASK:  fetch the latest openssl version'
	@curl -sSL https://github.com/openssl/openssl/releases | \
 grep -oE 'OpenSSL_(\d_\d_[2-9]{1}[a-z]{1})\.tar\.gz' | \
 head -1 | sed -e '$(TAR_SUF)' > $(@)
	@cat $@
	@echo '----------------------------'

#note the prefix 'openssl-'

downloadOpenssl: $(T)/openssl-latest.version
	@echo "# $(notdir $@) #"
	@echo 'Task: download latest openssl version'
	@curl -sSL https://github.com/openssl/openssl/archive/$(shell cat $<).tar.gz | \
 tar xz --directory $(T)

$(T)/pcre-latest.version:
	@echo "$(notdir $@) "
	@echo 'Task: fetch the latest pcre version'
	@curl -sSL ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/ |\
 grep -oE 'pcre-[0-9\.]+\.tar\.gz' |\
 head -1 | sed -e '$(TAR_SUF)' > $(@)
	@cat $@
	@echo '------------------------------------------------'

downloadPcre: $(T)/pcre-latest.version
	@echo "$(notdir $@) "
	@echo 'Task: download latest pcre version'
	@curl -sSL ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/$(shell cat $<).tar.gz | \
 tar xz --directory $(T)
	@echo '------------------------------------------------'

$(T)/zlib-latest.version:
	@echo "$(notdir $@) "
	@echo 'Task: fetch the latest zlib version'
	@ curl -sSL http://zlib.net/ |\
 grep -oE 'zlib-[0-9\.]+\.tar\.gz' |\
 head -1 | sed -e '$(TAR_SUF)' > $(@)
	@cat $@
	@echo '------------------------------------------------'

downloadZlib: $(T)/zlib-latest.version
	@echo "$(notdir $@) "
	@echo 'Task: download the latest zlib version'
	@curl -sSL http://zlib.net/$(shell cat $<).tar.gz | \
 tar xz --directory $(T)
	@echo '------------------------------------------------'

orInstallDownloads:
	@echo "$(notdir $@) "
	@$(MAKE) -j$(shell grep ^proces /proc/cpuinfo | wc -l ) --silent \
 downloadOpenresty downloadOpenssl downloadPcre downloadZlib
	@echo '================================================'

orInstall: orInstallDownloads
orInstall:
	@echo "$(notdir $@) "
	@echo "configure and install $(shell cat $(T)/openresty-latest.version) "
	@cd $(T)/$(shell cat $(T)/openresty-latest.version);\
 ./configure \
 --user=$(INSTALLER) \
 --group=$(INSTALLER) \
 --with-pcre="../$(shell cat $(T)/pcre-latest.version)" \
 --with-pcre-jit \
 --with-zlib="../$(shell cat $(T)/zlib-latest.version)" \
 --with-openssl="../openssl-$(shell cat $(T)/openssl-latest.version)" \
 --with-file-aio \
 --with-http_v2_module \
 --with-http_ssl_module \
 --without-http_empty_gif_module \
 --without-http_fastcgi_module \
 --without-http_uwsgi_module \
 --without-http_scgi_module  > configure.log 2>&1
	@cd $(T)/$(shell cat $(T)/openresty-latest.version);\
 make -j$(shell grep ^proces /proc/cpuinfo | wc -l ) > make.log 2>&1
	@cd $(T)/$(shell cat $(T)/openresty-latest.version); make install
