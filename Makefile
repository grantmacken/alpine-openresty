T := tmp
TAR_SUF := s/\(\.tar\.gz\)*$$//
OR_LATEST := $(T)/openresty-latest.version

define hOR
# openresty docker install
 docker build --t=

Multi stage docker build
 1: download source
 2: install from sources
 3: from base alpine copy over openresty

make targets

endef

.SECONDARY:

DOWNLOADS := downloadOpenresty downloadOpenssl downloadZlib downloadPcre

.PHONY: perlModules cmark

# TARGETS

default: install

orHelp: export HOR := $(hOR)
orHelp:
	@echo "$${HOR}"

ifneq ($(INC),)
include inc/*.mk
endif

install: $(T)/install.log
	@echo 'additions'
	@$(MAKE) perlModules
	@$(MAKE) cmark

perlModules:
	@echo "# $(notdir $@) #"
	@wget -O - https://cpanmin.us | perl - App::cpanminus \
  &&  cpanm --skip-installed -n Test::Base IPC::Run Test::Nginx \
 Term::ANSIColor Term::Encoding \
 TAP::Formatter::Base TAP::Formatter::HTML \
 App::Prove App::Prove::Plugin::HTML App::Prove::Plugin::retty

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

$(T)/install.log: $(DOWNLOADS)
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
 --without-http_scgi_module \
 && make  >/dev/null 2>&1 \
 && make install | tee -a install.log
	@echo '------------------------------------------------'
