include .env

# DOWNLOADS := downloadOpenresty downloadOpenssl downloadZlib downloadPcre
# .PHONY: perlModules cmark
# TARGETS

default: install

.PHONY: perl-modules
perl-modules:
	@echo "# $(notdir $@) #"
	@cpanm --skip-installed -n Test::Base IPC::Run Test::Nginx \
 Term::ANSIColor Term::Encoding \
 TAP::Formatter::Base TAP::Formatter::HTML \
 App::Prove App::Prove::Plugin::HTML App::Prove::Plugin::retty

cmark:
	@echo "# $(notdir $@) #"
	@echo 'Task: download  [ https://github.com/commonmark/cmark/archive/0.28.3.tar.gz ]'
	@curl -sSL https://github.com/commonmark/cmark/archive/0.28.3.tar.gz | \
 tar xz --directory $(T)
	@cd $(T)/cmark-0.28.3; make && make install

.PHONY: zlib-download
zlib-download:
	@echo "# $(notdir $@) #"
	@wget -nH --cut-dirs=100 --quiet --show-progress  --progress=bar:force:noscroll \
 --mirror 'http://www.zlib.net/fossils/zlib-$(ZLIB_VER).tar.gz'
	@cp zlib-$(ZLIB_VER).tar.gz openresty-zlib_$(ZLIB_VER).orig.tar.gz
	@echo '------------------------------------------------'

.PHONY: zlib-build
zlib-build: | zlib-download
	@echo "# $(notdir $@) #"
	@mkdir openresty-zlib
	@tar xf openresty-zlib_$(ZLIB_VER).orig.tar.gz --strip-components=1 -C openresty-zlib
	@echo '------------------------------------------------'

.PHONY: pcre-download
pcre-download:
	@echo "# $(notdir $@) #"
	@wget -nH --cut-dirs=100 --quiet --show-progress  --progress=bar:force:noscroll \
 --mirror 'https://ftp.pcre.org/pub/pcre/pcre-$(PCRE_VER).tar.bz2'
	@cp pcre-$(PCRE_VER).tar.bz2 openresty-pcre_$(PCRE_VER).orig.tar.bz2
	@echo '------------------------------------------------'

.PHONY: pcre-build
pcre-build: | pcre-download
	@echo "# $(notdir $@) #"
	@mkdir openresty-pcre
	@tar xf openresty-pcre_$(PCRE_VER).orig.tar.bz2 --strip-components=1 -C openresty-pcre
	@echo '------------------------------------------------'

.PHONY: openssl-download
openssl-download:
	@echo "# $(notdir $@) #"
	wget -nH --cut-dirs=100 --quiet --show-progress  --progress=bar:force:noscroll  \
 --mirror 'https://www.openssl.org/source/openssl-$(SSL_VER).tar.gz'
	cp openssl-$(SSL_VER).tar.gz openresty-openssl_$(SSL_VER).orig.tar.gz
	@echo '------------------------------------------------'

.PHONY: openssl-build
openssl-build: |  openssl-download
	@echo "# $(notdir $@) #"
	@mkdir openresty-openssl
	tar xf openresty-openssl_$(SSL_VER).orig.tar.gz --strip-components=1 -C openresty-openssl
	@echo '------------------------------------------------'

.PHONY: openresty-download
openresty-download:
	@echo "# $(notdir $@) #"
	@wget -nH --cut-dirs=100  --quiet --show-progress  --progress=bar:force:noscroll \
 --mirror 'https://openresty.org/download/openresty-$(OR_VER).tar.gz'
	@cp openresty-$(OR_VER).tar.gz openresty_$(OR_VER).orig.tar.gz
	@echo '------------------------------------------------'

.PHONY: openresty-build
openresty-build: | openresty-download
	@echo "# $(notdir $@) #"
	@mkdir openresty
	tar xf openresty_$(OR_VER).orig.tar.gz --strip-components=1 -C openresty
	@echo '------------------------------------------------'

# note: travis having difficulty with ftp try http
# note: for pcre source use tail
.PHONY: install
install: zlib-build pcre-build openssl-build openresty-build
	@echo "$(notdir $@) "
	@rm -f *.orig.tar.*
	@echo " - sanity checks "
	@ls -al .
	@[ -d /home/openresty ]
	@[ -d /home/openresty-zlib ]
	@[ -d /home/openresty-openssl ]
	@[ -d /home/openresty-pcre ]
	@echo " - configure and install "
	@cd openresty;\
 ./configure \
 --with-pcre="/home/openresty-pcre" \
 --with-pcre-jit \
 --with-zlib='/home/openresty-zlib' \
 --with-openssl='/home/openresty-openssl' \
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
 && make && make install
	@echo '------------------------------------------------'

#with-openssl='/home/openresty-openssl' \

.PHONY: base
base:
	@echo $(OR_VER)
	@docker build \
  --target="base" \
  --tag="$(DOCKER_IMAGE):v$(OR_VER)" \
 .

.PHONY: dev
dev:
	@echo $(OR_VER)
	@docker build \
  --target="dev" \
  --tag="$(DOCKER_IMAGE):dev" \
 .


