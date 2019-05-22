include .env

default: install

.PHONY: perl-modules
perl-modules:
	@echo "# $(notdir $@) #"
	@cpanm --skip-installed -n Test::Base IPC::Run Test::Nginx \
 Term::ANSIColor Term::Encoding \
 TAP::Formatter::Base TAP::Formatter::HTML \
 App::Prove App::Prove::Plugin::HTML App::Prove::Plugin::retty

source/cmark/archive/$(CMARK).tar.gz:
	@echo "# $(notdir $@) #"
	@echo 'Task: download  [ https://github.com/commonmark/cmark/archive/$(CMARK).tar.gz ]'
	@wget -nH --cut-dirs=1 -P source --quiet --show-progress  --progress=bar:force:noscroll \
 --mirror 'https://github.com/commonmark/cmark/archive/$(CMARK).tar.gz'
	@#curl -sSL https://github.com/commonmark/cmark/archive/0.28.3.tar.gz tar xz --directory $(T)
	@#cd $(T)/cmark-0.28.3; make && make install

.PHONY: cmark-build
cmark-build: source/cmark/archive/$(CMARK).tar.gz
	@echo "# $(notdir $@) #"
	@mkdir -p cmark
	@tar xf $< --strip-components=1 -C cmark
	@cd cmark; make && make install
	@echo '------------------------------------------------'

source/zlib-$(ZLIB_VER).tar.gz:
	@echo "# $(notdir $@) #"
	@wget -nH --cut-dirs=1 -P source --quiet --show-progress  --progress=bar:force:noscroll \
 --mirror 'http://www.zlib.net/fossils/zlib-$(ZLIB_VER).tar.gz'
	@echo '------------------------------------------------'

.PHONY: zlib-build
zlib-build: source/zlib-$(ZLIB_VER).tar.gz
	@echo "# $(notdir $@) #"
	@mkdir -p openresty-zlib
	@tar xf $< --strip-components=1 -C openresty-zlib
	@echo '------------------------------------------------'

source/pcre-$(PCRE_VER).tar.bz2:
	@echo "# $(notdir $@) #"
	@wget -nH --cut-dirs=2 -P source --quiet --show-progress  --progress=bar:force:noscroll \
 --mirror 'https://ftp.pcre.org/pub/pcre/pcre-$(PCRE_VER).tar.bz2'
	@echo '------------------------------------------------'

.PHONY: pcre-build
pcre-build: source/pcre-$(PCRE_VER).tar.bz2
	@echo "# $(notdir $@) #"
	@mkdir -p openresty-pcre
	@tar xf $< --strip-components=1 -C openresty-pcre
	@echo '------------------------------------------------'

source/openssl-$(SSL_VER).tar.gz:
	@echo "# $(notdir $@) #"
	wget -nH --quiet --show-progress  --progress=bar:force:noscroll  \
 --mirror 'https://www.openssl.org/source/openssl-$(SSL_VER).tar.gz'
	@echo '------------------------------------------------'

.PHONY: openssl-build
openssl-build: source/openssl-$(SSL_VER).tar.gz
	@echo "# $(notdir $@) #"
	@mkdir -p openresty-openssl
	tar xf $< --strip-components=1 -C openresty-openssl
	@echo '------------------------------------------------'

# https://openresty.org/en/

download/openresty-$(OR_VER).tar.gz:
	@echo "# $(notdir $@) #"
	@wget -nH --quiet --show-progress  --progress=bar:force:noscroll \
 --mirror 'https://openresty.org/download/openresty-$(OR_VER).tar.gz'
	@echo '------------------------------------------------'

.PHONY: openresty-build
openresty-build: download/openresty-$(OR_VER).tar.gz
	@echo "# $@ #"
	@echo "# $< #"
	@mkdir -p openresty
	tar xf $< --strip-components=1 -C openresty
	@echo '------------------------------------------------'

# note: travis having difficulty with ftp try http
# note: for pcre source use tail
.PHONY: install
install:  pcre-build openssl-build openresty-build
	@echo "$(notdir $@) "
	@rm -f *.orig.tar.*
	@echo " - sanity checks "
	@ls -al .
	@[ -d /home/openresty-openssl ]
	@[ -d /home/openresty-pcre ]
	@[ -d /home/openresty ]
	@echo " - configure and install "
	@cd openresty;\
 ./configure \
 --with-pcre="/home/openresty-pcre" \
 --with-pcre-jit \
 --with-http_v2_module \
 --with-http_ssl_module \
 --with-openssl="/home/openresty-openssl" \
 --with-http_gzip_static_module \
 --with-http_gunzip_module \
 --without-http_empty_gif_module \
 --without-http_memcached_module \
 --without-http_auth_basic_module \
 --without-http_fastcgi_module \
 --without-http_uwsgi_module \
 --without-http_ssi_module \
 --without-http_scgi_module
	@cd openresty && make
	@cd openresty && make install

#with-openssl='/home/openresty-openssl' \

# .PHONY: build-base
# build-base:
# 	@echo $(OR_VER)
# 	@docker build \
#   --target="base" \
#   --tag="$(DOCKER_IMAGE):base-v$(OR_VER)" \
 .

# .PHONY: build
# build:
# 	@echo $(OR_VER)
# 	@docker build \
#   --target="dev" \
#   --tag="$(DOCKER_IMAGE):v$(OR_VER)" \
#   --tag="$(DOCKER_IMAGE):$(DOCKER_TAG)" \
#  .

.PHONY: pack
pack:
	@echo $(OR_VER)
	@docker build \
  --target="pack" \
  --tag="$(DOCKER_IMAGE):pack" \
 .

.PHONY: build
build:
	@echo $(OR_VER)
	@docker build \
  --target="base" \
  --tag="$(DOCKER_IMAGE):$(DOCKER_TAG)" \
  --tag="$(DOCKER_IMAGE):v$(OR_VER)" \
  --tag="$(DOCKER_IMAGE):2019-05-23" \
 .


.PHONY: push
push:
	@echo '## $@ ##'
	@docker push $(DOCKER_IMAGE):v$(OR_VER)
	@docker push $(DOCKER_IMAGE):$(DOCKER_TAG)

.PHONY: clean
clean:
	@docker images -a | grep "grantmacken" | awk '{print $3}' | xargs docker rmi

.PHONY: travis
travis: 
	@travis env set DOCKER_USERNAME $(shell git config --get user.name)
