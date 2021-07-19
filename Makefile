.PHONY: all install clean

all:
	cd /home/lihang/workspace/data-lhlh-ngproxy/build/LuaJIT-2.1-20170405 && $(MAKE) TARGET_STRIP=@: CCDEBUG=-g XCFLAGS='-std=gnu99 -DLUAJIT_ENABLE_LUA52COMPAT -msse4.2' CC=cc PREFIX=/home/lhlh/data-lhlh-ngproxy/luajit
	cd /home/lihang/workspace/data-lhlh-ngproxy/build/lua-cjson-2.1.0.5 && $(MAKE) DESTDIR=$(DESTDIR) LUA_INCLUDE_DIR=/home/lihang/workspace/data-lhlh-ngproxy/build/luajit-root/home/lhlh/data-lhlh-ngproxy/luajit/include/luajit-2.1 LUA_CMODULE_DIR=/home/lhlh/data-lhlh-ngproxy/lualib LUA_MODULE_DIR=/home/lhlh/data-lhlh-ngproxy/lualib CJSON_CFLAGS="-g -fpic" CC=cc
	cd /home/lihang/workspace/data-lhlh-ngproxy/build/lua-redis-parser-0.13 && $(MAKE) DESTDIR=$(DESTDIR) LUA_INCLUDE_DIR=/home/lihang/workspace/data-lhlh-ngproxy/build/luajit-root/home/lhlh/data-lhlh-ngproxy/luajit/include/luajit-2.1 LUA_LIB_DIR=/home/lhlh/data-lhlh-ngproxy/lualib CC=cc
	cd /home/lihang/workspace/data-lhlh-ngproxy/build/lua-rds-parser-0.06 && $(MAKE) DESTDIR=$(DESTDIR) LUA_INCLUDE_DIR=/home/lihang/workspace/data-lhlh-ngproxy/build/luajit-root/home/lhlh/data-lhlh-ngproxy/luajit/include/luajit-2.1 LUA_LIB_DIR=/home/lhlh/data-lhlh-ngproxy/lualib CC=cc
	cd /home/lihang/workspace/data-lhlh-ngproxy/build/nginx-1.11.2 && $(MAKE)

install: all
	cd /home/lihang/workspace/data-lhlh-ngproxy/build/LuaJIT-2.1-20170405 && $(MAKE) install TARGET_STRIP=@: CCDEBUG=-g XCFLAGS='-std=gnu99 -DLUAJIT_ENABLE_LUA52COMPAT -msse4.2' CC=cc PREFIX=/home/lhlh/data-lhlh-ngproxy/luajit DESTDIR=$(DESTDIR)
	cd /home/lihang/workspace/data-lhlh-ngproxy/build/lua-cjson-2.1.0.5 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_INCLUDE_DIR=/home/lihang/workspace/data-lhlh-ngproxy/build/luajit-root/home/lhlh/data-lhlh-ngproxy/luajit/include/luajit-2.1 LUA_CMODULE_DIR=/home/lhlh/data-lhlh-ngproxy/lualib LUA_MODULE_DIR=/home/lhlh/data-lhlh-ngproxy/lualib CJSON_CFLAGS="-g -fpic" CC=cc
	cd /home/lihang/workspace/data-lhlh-ngproxy/build/lua-redis-parser-0.13 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_INCLUDE_DIR=/home/lihang/workspace/data-lhlh-ngproxy/build/luajit-root/home/lhlh/data-lhlh-ngproxy/luajit/include/luajit-2.1 LUA_LIB_DIR=/home/lhlh/data-lhlh-ngproxy/lualib CC=cc
	cd /home/lihang/workspace/data-lhlh-ngproxy/build/lua-rds-parser-0.06 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_INCLUDE_DIR=/home/lihang/workspace/data-lhlh-ngproxy/build/luajit-root/home/lhlh/data-lhlh-ngproxy/luajit/include/luajit-2.1 LUA_LIB_DIR=/home/lhlh/data-lhlh-ngproxy/lualib CC=cc
	cd /home/lihang/workspace/data-lhlh-ngproxy/build/lua-resty-dns-0.18 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/home/lhlh/data-lhlh-ngproxy/lualib INSTALL=/home/lihang/workspace/data-lhlh-ngproxy/build/install
	cd /home/lihang/workspace/data-lhlh-ngproxy/build/lua-resty-memcached-0.14 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/home/lhlh/data-lhlh-ngproxy/lualib INSTALL=/home/lihang/workspace/data-lhlh-ngproxy/build/install
	cd /home/lihang/workspace/data-lhlh-ngproxy/build/lua-resty-redis-0.26 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/home/lhlh/data-lhlh-ngproxy/lualib INSTALL=/home/lihang/workspace/data-lhlh-ngproxy/build/install
	cd /home/lihang/workspace/data-lhlh-ngproxy/build/lua-resty-mysql-0.19 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/home/lhlh/data-lhlh-ngproxy/lualib INSTALL=/home/lihang/workspace/data-lhlh-ngproxy/build/install
	cd /home/lihang/workspace/data-lhlh-ngproxy/build/lua-resty-string-0.09 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/home/lhlh/data-lhlh-ngproxy/lualib INSTALL=/home/lihang/workspace/data-lhlh-ngproxy/build/install
	cd /home/lihang/workspace/data-lhlh-ngproxy/build/lua-resty-upload-0.10 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/home/lhlh/data-lhlh-ngproxy/lualib INSTALL=/home/lihang/workspace/data-lhlh-ngproxy/build/install
	cd /home/lihang/workspace/data-lhlh-ngproxy/build/lua-resty-websocket-0.06 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/home/lhlh/data-lhlh-ngproxy/lualib INSTALL=/home/lihang/workspace/data-lhlh-ngproxy/build/install
	cd /home/lihang/workspace/data-lhlh-ngproxy/build/lua-resty-lock-0.06 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/home/lhlh/data-lhlh-ngproxy/lualib INSTALL=/home/lihang/workspace/data-lhlh-ngproxy/build/install
	cd /home/lihang/workspace/data-lhlh-ngproxy/build/lua-resty-lrucache-0.06 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/home/lhlh/data-lhlh-ngproxy/lualib INSTALL=/home/lihang/workspace/data-lhlh-ngproxy/build/install
	cd /home/lihang/workspace/data-lhlh-ngproxy/build/lua-resty-core-0.1.11 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/home/lhlh/data-lhlh-ngproxy/lualib INSTALL=/home/lihang/workspace/data-lhlh-ngproxy/build/install
	cd /home/lihang/workspace/data-lhlh-ngproxy/build/lua-resty-upstream-healthcheck-0.04 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/home/lhlh/data-lhlh-ngproxy/lualib INSTALL=/home/lihang/workspace/data-lhlh-ngproxy/build/install
	cd /home/lihang/workspace/data-lhlh-ngproxy/build/lua-resty-limit-traffic-0.03 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/home/lhlh/data-lhlh-ngproxy/lualib INSTALL=/home/lihang/workspace/data-lhlh-ngproxy/build/install
	cd /home/lihang/workspace/data-lhlh-ngproxy/build/opm-0.0.3 && /home/lihang/workspace/data-lhlh-ngproxy/build/install bin/* $(DESTDIR)/home/lhlh/data-lhlh-ngproxy/bin/
	cd /home/lihang/workspace/data-lhlh-ngproxy/build/resty-cli-0.17 && /home/lihang/workspace/data-lhlh-ngproxy/build/install bin/* $(DESTDIR)/home/lhlh/data-lhlh-ngproxy/bin/
	cp /home/lihang/workspace/data-lhlh-ngproxy/build/resty.index $(DESTDIR)/home/lhlh/data-lhlh-ngproxy/
	cp -r /home/lihang/workspace/data-lhlh-ngproxy/build/pod $(DESTDIR)/home/lhlh/data-lhlh-ngproxy/
	cd /home/lihang/workspace/data-lhlh-ngproxy/build/nginx-1.11.2 && $(MAKE) install DESTDIR=$(DESTDIR)
	mkdir -p $(DESTDIR)/home/lhlh/data-lhlh-ngproxy/site/lualib $(DESTDIR)/home/lhlh/data-lhlh-ngproxy/site/pod $(DESTDIR)/home/lhlh/data-lhlh-ngproxy/site/manifest
	ln -sf /home/lhlh/data-lhlh-ngproxy/nginx/sbin/nginx $(DESTDIR)/home/lhlh/data-lhlh-ngproxy/bin/openresty

clean:
	rm -rf build
