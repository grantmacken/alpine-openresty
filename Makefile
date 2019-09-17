include .env
PREFIX := $(OPENRESTY_HOME)
#https://github.com/openresty/docker-openresty/blob/340771ce0c59cbb9b94a245bb92cf4bf569c3bce/alpine/Dockerfile
RESTY_LUAJIT_OPTIONS := --with-luajit-xcflags='-DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT'
# These are not intended to be user-specified
WITH-CC-OPT := --with-cc-opt='-DNGX_LUA_ABORT_AT_PANIC -I/usr/local/openresty/pcre/include -I/usr/local/openresty/openssl/include' 
WITH-LD-OPT := --with-ld-opt='-L/usr/local/openresty/pcre/lib -L/usr/local/openresty/openssl/lib -Wl,-rpath,/usr/local/openresty/pcre/lib:/usr/local/openresty/openssl/lib' 
RESTY_CONFIG_DEPS := --with-pcre $(WITH-CC-OPT) $(WITH-LD-OPT)
RESTY_CONFIG_OPTIONS := --with-stream \
 --with-stream_ssl_module \
 --with-stream_ssl_preread_module \
 --with-http_v2_module \
 --with-http_gzip_static_module \
 --with-http_gunzip_module \
 --with-threads \
 --without-http_auth_basic_module \
 --without-http_empty_gif_module \
 --without-http_fastcgi_module \
 --without-http_memcached_module \
 --without-http_rds_csv_module \
 --without-http_rds_json_module \
 --without-http_redis_module \
 --without-http_scgi_module \
 --without-http_ssi_module \
 --without-http_uwsgi_module \
 --without-lua_rds_parser \
 --without-mail_imap_module \
 --without-mail_pop3_module \
 --without-mail_smtp_module




default: openresty-build perl-modules cmark-build
	@echo 'Task: cleanup'
	@rm -rf /usr/lib/pkgconfig
	@rm -rf /home/*
	@rm -rf /usr/local/lib/lib64/*
	@rm -f /usr/local/bin/cmark 
	@rm -f /usr/local/bin/lwp-*
	@rm -fr /usr/local/share/man/*

 # Term::ANSIColor Term::Encoding \
 # TAP::Formatter::Base TAP::Formatter::HTML \
 # App::Prove App::Prove::Plugin::HTML App::Prove::Plugin::retty


.PHONY: perl-modules
perl-modules:
	@echo "# $(notdir $@) #"
	@cpanm --skip-installed -n \
 Test::Base \
 Test::LongString \
 Text::Diff \
 List::MoreUtils \
 IPC::Run \
 Test::Nginx \
 App::Prove

/home/$(CMARK).tar.gz:
	@echo "# $(notdir $@) #"
	@echo 'Task: download  [ https://github.com/commonmark/cmark/archive/$(CMARK).tar.gz ]'
	@wget -nH --quiet --show-progress  --progress=bar:force:noscroll \
 'https://github.com/commonmark/cmark/archive/$(CMARK).tar.gz'

.PHONY: cmark-build
cmark-build: /home/$(CMARK).tar.gz
	@echo "# $(notdir $@) #"
	@mkdir -p cmark
	@tar xf $< --strip-components=1 -C cmark
	@cd cmark && make && make install
	@echo '------------------------------------------------'

# /home/zlib-$(ZLIB_VER).tar.gz:
# 	@echo "# $(notdir $@) #"
# 	@wget -nH --quiet --show-progress  --progress=bar:force:noscroll \
#  'http://www.zlib.net/fossils/zlib-$(ZLIB_VER).tar.gz'
# 	@echo '------------------------------------------------'

# .PHONY: zlib-build
# zlib-build: /home/zlib-$(ZLIB_VER).tar.gz
# 	@echo "# $(notdir $@) #"
# 	@tar xzf $<
# 	@cd $(basename $(notdir $<)) \
#  && ./configure --prefix=$(PREFIX)/zlib \
#  && make && make install
# 	@rm -rf $(PREFIX)/zlib/share
# 	@rm -rf $(PREFIX)/lib/*.la
# 	@rm -rf $(PREFIX)/lib/pkgconfig
# 	@echo '------------------------------------------------'

/home/pcre-$(PCRE_VER).tar.bz2:
	@echo "# $(notdir $@) #"
	@wget -nH --quiet --show-progress  --progress=bar:force:noscroll \
 'https://ftp.pcre.org/pub/pcre/pcre-$(PCRE_VER).tar.bz2'
	@echo '------------------------------------------------'

.PHONY: pcre-build
pcre-build: /home/pcre-$(PCRE_VER).tar.bz2
	@echo "# $(notdir $@) #"
	@mkdir openresty-pcre
	@tar xfj $<
	@cd /home/pcre-$(PCRE_VER) \
 && ./configure \
 --prefix=$(PREFIX)/pcre \
 --disable-cpp \
 --enable-jit \
 --enable-utf \
 --enable-unicode-properties \
 && make && make install
	@rm -rf $(PREFIX)/pcre/bin
	@rm -rf $(PREFIX)/pcre/share
	@rm -f $(PREFIX)/pcre/lib/*.la
	@rm -f $(PREFIX)/pcre/lib/*pcrecpp*
	@rm -f $(PREFIX)/pcre/lib/*pcreposix*
	@rm -rf $(PREFIX)/pcre/lib/pkgconfig
	@echo '------------------------------------------------'

###########
# openssl depends on zlib
# zlib-build

/home/openssl-$(SSL_VER).tar.gz: 
	@echo "# $(notdir $@) #"
	@wget -nH --quiet --show-progress  --progress=bar:force:noscroll \
 'https://www.openssl.org/source/openssl-$(SSL_VER).tar.gz'
	@echo '------------------------------------------------'

.PHONY: openssl-build
openssl-build: /home/openssl-$(SSL_VER).tar.gz 
	@echo "# $(notdir $@) #"
	@tar xzf $< 
	echo 'patching OpenSSL 1.1.1 for OpenResty'
	@cd /home/openssl-$(SSL_VER) \
  && curl -s https://raw.githubusercontent.com/openresty/openresty/master/patches/openssl-1.1.1c-sess_set_get_cb_yield.patch | patch -p1 ;
	@cd /home/openssl-$(SSL_VER) \
  && ./config \
  no-threads shared zlib -g \
  enable-ssl3 enable-ssl3-method \
  --prefix=$(PREFIX)/openssl \
  --libdir=lib \
  -I$(PREFIX)/zlib/include \
  -L$(PREFIX)/zlib/lib \
  -Wl,-rpath,$(PREFIX)/zlib/lib:$(PREFIX)/openssl/lib \
 && make && make install_sw
	@echo '------------------------------------------------'




/home/openresty-$(OR_VER).tar.gz:  openssl-build pcre-build
	@echo "# $(notdir $@) #"
	@wget -nH --quiet --show-progress  --progress=bar:force:noscroll \
 'https://openresty.org/download/openresty-$(OR_VER).tar.gz'
	@echo '------------------------------------------------'

.PHONY: openresty-build
openresty-build: /home/openresty-$(OR_VER).tar.gz
	@echo "# $@ #"
	@tar xfv $<
	@cd /home/openresty-$(OR_VER) \
 && ./configure $(RESTY_CONFIG_DEPS) $(RESTY_CONFIG_OPTIONS) $(RESTY_LUAJIT_OPTIONS) \
   && make && make install
	@echo 'clean up' \
    && cd /home && rm -rf \
     openssl-$(SSL_VER)}.tar.gz openssl-$(SSL_VER) \
     openssl-$(SSL_VER)}.tar.gz openssl-$(SSL_VER) \
     pcre-$(PCRE_VER).tar.gz pcre-$(PCRE_VER) \
     openresty-$(OR_VER).tar.gz openresty-$(OR_VER) \
	@#rm -rf $(PREFIX)/luajit/share/man
	@#rm -rf $(PREFIX)/luajit/lib/libluajit-5.1.a
	@echo '------------------------------------------------'

# zlib-$(ZLIB_VER).tar.gz zlib-$(ZLIB_VER) \

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
  --tag="$(DOCKER_IMAGE):v$(shell date --iso | sed s/-//g)" \
 .

.PHONY: push
push:
	@echo '## $@ ##'
	@docker push $(DOCKER_IMAGE):v$(OR_VER)
	@docker push $(DOCKER_IMAGE):$(DOCKER_TAG)
	@docker push $(DOCKER_IMAGE):v$(shell date --iso | sed s/-//g)

.PHONY: clean
clean:
	@docker images -a | grep "grantmacken" | awk '{print $3}' | xargs docker rmi

.PHONY: travis
travis: 
	@travis env set DOCKER_USERNAME $(shell git config --get user.name)
	@#travis env set DOCKER_PASSWORD
	@travis env list
