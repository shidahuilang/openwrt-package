include $(TOPDIR)/rules.mk

PKG_NAME:=homebox
PKG_VERSION:=0.0.0-dev.2020062901
PKG_RELEASE:=2

PKG_SOURCE_URL_FILE:=v$(PKG_VERSION).tar.gz
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_GIT_URL:=github.com/XGHeaven/homebox
PKG_GIT_REF:=v$(PKG_VERSION)
PKG_SOURCE_URL:=https://codeload.$(PKG_GIT_URL)/tar.gz/$(PKG_GIT_REF)?
PKG_HASH:=815a2a0fc5458245769648ef5b394f69fdec2573a1403b789146be0c4217a443

PKG_BUILD_DEPENDS:=golang/host homebox/host
PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

PKG_CONFIG_DEPENDS:= \
	CONFIG_HOMEBOX_COMPRESS_GOPROXY \
	CONFIG_HOMEBOX_COMPRESS_UPX

HOST_BUILD_DEPENDS:=node/host
HOST_BUILD_DIR:=$(BUILD_DIR_HOST)/${PKG_NAME}

include $(INCLUDE_DIR)/host-build.mk
include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=A Toolbox for Home Local Networks
  URL:=https://github.com/XGHeaven/homebox
  DEPENDS:=$(GO_ARCH_DEPENDS)
  MENU:=1
endef

define Package/$(PKG_NAME)/description
  A Toolbox for Home Local Networks Speed Test
endef

define Package/$(PKG_NAME)/config
config HOMEBOX_COMPRESS_GOPROXY
	bool "Compiling with GOPROXY proxy"
	default n

config HOMEBOX_COMPRESS_UPX
	bool "Compress executable files with UPX"
	default y
endef

ifeq ($(CONFIG_HOMEBOX_COMPRESS_GOPROXY),y)
	export GO111MODULE=on
	export GOPROXY=https://goproxy.cn
endif

GO_PKG_BUILD_VARS += GO111MODULE=auto
TAR_OPTIONS:=--strip-components 1 $(TAR_OPTIONS)
TAR_CMD=$(HOST_TAR) -C $(1) $(TAR_OPTIONS)

define Build/Configure
	( \
		cd $(PKG_BUILD_DIR)/server; \
		$(GO_PKG_VARS) \
		go get -d -modcacherw; \
	)
	( \
		cd $(PKG_BUILD_DIR)/server; \
		GOPATH=$(PKG_BUILD_DIR)/.go_work/build \
		go get -modcacherw github.com/go-bindata/go-bindata/...; \
	)
endef

define Build/Compile
	rm -rf $(PKG_BUILD_DIR)/build/static
	mkdir -p $(PKG_BUILD_DIR)/build
	$(CP) $(HOST_BUILD_DIR)/build/static $(PKG_BUILD_DIR)/build/
	( \
		cd $(PKG_BUILD_DIR); \
		$(GO_PKG_VARS) PATH=$$$$PATH:$(PKG_BUILD_DIR)/.go_work/build/bin \
		$(MAKE) build-server; \
	)
ifeq ($(CONFIG_HOMEBOX_COMPRESS_UPX),y)
	$(STAGING_DIR_HOST)/bin/upx --lzma --best $(PKG_BUILD_DIR)/build/server
endif
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/etc/config $(1)/etc/init.d $(1)/etc/uci-defaults
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/build/server $(1)/usr/bin/homebox
	$(INSTALL_CONF) ./files/homebox.config $(1)/etc/config/homebox
	$(INSTALL_BIN) ./files/homebox.init $(1)/etc/init.d/homebox
	$(INSTALL_BIN) ./files/homebox.uci-default $(1)/etc/uci-defaults/homebox
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/homebox
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	[ -f /etc/uci-defaults/homebox ] && /etc/uci-defaults/homebox && rm -f /etc/uci-defaults/homebox
fi
endef

define Host/Configure
	cd $(HOST_BUILD_DIR)/web && rm -f package-lock.json && npm config set registry http://registry.npm.taobao.org/ && npm --cache-min 1440 install
endef

define Host/Compile
	cd $(HOST_BUILD_DIR) && $(MAKE) build-web
endef

define Host/Install
endef

define Host/Clean
	rm -f $(HOST_BUILD_DIR)/build/static
endef

$(eval $(call HostBuild))
$(eval $(call BuildPackage,homebox))
