#
# Copyright (c) 2018-2026 Nick Peng (pymumu@gmail.com)
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=smartdns
PKG_VERSION:=48.4
PKG_RELEASE:=1

PKG_SOURCE_VERSION:=21c940edc65520849ba03544c5cf8d9cf326e680
PKG_SOURCE:=$(PKG_NAME)-$(PKG_SOURCE_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/pymumu/smartdns/tar.gz
PKG_SOURCE_URL_FILE:=$(PKG_SOURCE_VERSION)
PKG_HASH:=f4cb3ec5d2c49bf9752f717cfa1ae2e393df0a001de7ab626b9039cc0bf3ef52
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_SOURCE_VERSION)

SMARTDNS_WEBUI_SOURCE_VERSION:=1c06fee693434ec7c71f06010d3f87416baba9f0
SMARTDNS_WEBUI_SOURCE:=$(PKG_NAME)-webui-$(SMARTDNS_WEBUI_SOURCE_VERSION).tar.gz
SMARTDNS_WEBUI_SOURCE_URL:=https://codeload.github.com/pymumu/smartdns-webui/tar.gz
SMARTDNS_WEBUI_SOURCE_URL_FILE:=$(SMARTDNS_WEBUI_SOURCE_VERSION)
SMARTDNS_WEBUI_HASH:=7a698dd4826750869429e83d91ce99a4e474d0809588a7f4124ef86875be9b1f

PKG_MAINTAINER:=Nick Peng <pymumu@gmail.com>
PKG_LICENSE:=GPL-3.0-or-later
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_PARALLEL:=1

# node compile is slow, so do not use it, download node manually.
# PACKAGE_smartdns-ui:node/host
PKG_BUILD_DEPENDS:=PACKAGE_smartdns-ui:rust/host

include $(TOPDIR)/feeds/packages/lang/rust/rust-package.mk
include $(INCLUDE_DIR)/package.mk

MAKE_VARS += VER=$(PKG_VERSION)
MAKE_PATH:=src

define Package/smartdns/default
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=IP Addresses and Names
  URL:=https://www.github.com/pymumu/smartdns/
endef

define Package/smartdns
  $(Package/smartdns/default)
  TITLE:=smartdns server
  DEPENDS:=+libpthread +libopenssl +libatomic +zlib
endef

define Package/smartdns/description
SmartDNS is a local DNS server which accepts DNS query requests from local network clients,
gets DNS query results from multiple upstream DNS servers concurrently, and returns the fastest IP to clients.
Unlike dnsmasq's all-servers, smartdns returns the fastest IP, and encrypt DNS queries with DoT or DoH. 
endef

define Package/smartdns/conffiles
/etc/config/smartdns
/etc/smartdns/address.conf
/etc/smartdns/blacklist-ip.conf
/etc/smartdns/custom.conf
/etc/smartdns/domain-block.list
/etc/smartdns/domain-forwarding.list
endef

define Package/smartdns/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/config $(1)/etc/init.d 
	$(INSTALL_DIR) $(1)/etc/smartdns $(1)/etc/smartdns/domain-set $(1)/etc/smartdns/conf.d/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/smartdns $(1)/usr/sbin/smartdns
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/package/openwrt/files/etc/init.d/smartdns $(1)/etc/init.d/smartdns
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/package/openwrt/address.conf $(1)/etc/smartdns/address.conf
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/package/openwrt/blacklist-ip.conf $(1)/etc/smartdns/blacklist-ip.conf
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/package/openwrt/custom.conf $(1)/etc/smartdns/custom.conf
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/package/openwrt/files/etc/config/smartdns $(1)/etc/config/smartdns
endef

define Package/smartdns-ui
  $(Package/smartdns/default)
  TITLE:=smartdns dashboard
  DEPENDS:=+smartdns $(RUST_ARCH_DEPENDS)
endef

define Package/smartdns-ui/description
A dashboard ui for smartdns server.
endef

define Package/smartdns-ui/conffiles
/etc/config/smartdns
endef

define Package/smartdns-ui/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_DIR) $(1)/etc/smartdns/conf.d/
	$(INSTALL_DIR) $(1)/usr/share/smartdns/wwwroot
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/plugin/smartdns-ui/target/smartdns_ui.so $(1)/usr/lib/smartdns_ui.so
	$(CP) $(PKG_BUILD_DIR)/smartdns-webui/out/* $(1)/usr/share/smartdns/wwwroot
endef

define Build/Compile/smartdns-webui
	which npm || (echo "npm not found, please install npm first" && exit 1)
	npm install --prefix $(PKG_BUILD_DIR)/smartdns-webui/
	npm run build --prefix $(PKG_BUILD_DIR)/smartdns-webui/
endef

define Build/Compile/smartdns-ui
	cargo install --force --locked bindgen-cli
	CARGO_BUILD_ARGS="$(if $(strip $(RUST_PKG_FEATURES)),--features "$(strip $(RUST_PKG_FEATURES))") --profile $(CARGO_PKG_PROFILE)"
	+$(CARGO_PKG_VARS) CARGO_BUILD_ARGS="$(CARGO_BUILD_ARGS)" CC=$(TARGET_CC) \
	PATH="$$(PATH):$(CARGO_HOME)/bin" \
	AWS_LC_SYS_CFLAGS="-O0" \
	make -C $(PKG_BUILD_DIR)/plugin/smartdns-ui
endef

define Download/smartdns-webui
	FILE:=$(SMARTDNS_WEBUI_SOURCE)
	URL:=$(SMARTDNS_WEBUI_SOURCE_URL)
	URL_FILE:=$(SMARTDNS_WEBUI_SOURCE_URL_FILE)
	HASH:=$(SMARTDNS_WEBUI_HASH)
endef
$(eval $(call Download,smartdns-webui))

ifdef CONFIG_PACKAGE_smartdns-ui
define Build/Prepare
	$(call Build/Prepare/Default)
	$(INSTALL_DIR) $(PKG_BUILD_DIR)/smartdns-webui
	$(TAR) -C $(PKG_BUILD_DIR)/smartdns-webui --strip-components=1 -xf $(DL_DIR)/$(SMARTDNS_WEBUI_SOURCE)
endef
endif

define Build/Compile
	$(call Build/Compile/Default,smartdns)
ifdef CONFIG_PACKAGE_smartdns-ui
	$(call Build/Compile/smartdns-ui)
	$(call Build/Compile/smartdns-webui)
endif
endef

$(eval $(call BuildPackage,smartdns))
$(eval $(call RustBinPackage,smartdns-ui))
$(eval $(call BuildPackage,smartdns-ui))
