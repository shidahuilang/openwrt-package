#
# Copyright (c) 2018-2023 Nick Peng (pymumu@gmail.com)
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=smartdns
PKG_VERSION:=1.2025.46.2
PKG_RELEASE:=5

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://www.github.com/pymumu/smartdns.git
PKG_MIRROR_HASH:=a7edb052fea61418c91c7a052f7eb1478fe6d844aec5e3eda0f2fcf82de29a10
PKG_SOURCE_VERSION:=4027503602c1dab32d2df5b8a471bc5778d1a536

SMARTDNS_WEBUI_VERSION:=1.0.0
SMARTDNS_WEBUI_SOURCE_PROTO:=git
SMARTDNS_WEBUI_SOURCE_URL:=https://github.com/pymumu/smartdns-webui.git
SMARTDNS_WEBUI_SOURCE_VERSION:=95f5d622fd014713aa2991190cbb62a2d58024b5
SMARTDNS_WEBUI_FILE:=smartdns-webui-$(SMARTDNS_WEBUI_VERSION).tar.gz

PKG_MAINTAINER:=Nick Peng <pymumu@gmail.com>
PKG_LICENSE:=GPL-3.0-or-later
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_PARALLEL:=1

# node compile is slow, so do not use it, doownload node manually.
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
  DEPENDS:=+libpthread +libopenssl +libatomic
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
	make -C $(PKG_BUILD_DIR)/plugin/smartdns-ui
endef

define Download/smartdns-webui
	FILE:=$(SMARTDNS_WEBUI_FILE)
	PROTO:=$(SMARTDNS_WEBUI_SOURCE_PROTO)
	URL:=$(SMARTDNS_WEBUI_SOURCE_URL)
	MIRROR_HASH:=a1c084dcc4fb7f87641d706b70168fc3c159f60f37d4b7eac6089ae68f0a18a1
	VERSION:=$(SMARTDNS_WEBUI_SOURCE_VERSION)
	HASH:=$(SMARTDNS_WEBUI_HASH)
	SUBDIR:=smartdns-webui
endef
$(eval $(call Download,smartdns-webui))

ifdef CONFIG_PACKAGE_smartdns-ui
define Build/Prepare
	$(call Build/Prepare/Default)
	$(TAR) -C $(PKG_BUILD_DIR)/ -xf $(DL_DIR)/$(SMARTDNS_WEBUI_FILE)
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
