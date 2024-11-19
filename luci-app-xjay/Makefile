include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-xjay
PKG_VERSION:=1.3.1
PKG_RELEASE:=2

PKG_LICENSE:=MPLv2
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=nobody
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=Custom
	CATEGORY:=Extra packages
	TITLE:=LuCI Support for Xray
	DEPENDS:=+luci-base +xray-core +xray-geodata +jsonfilter \
		 +PACKAGE_XRAY_INCLUDE_IPTABLES_SUPPORT:kmod-nft-tproxy \
		 +PACKAGE_XRAY_INCLUDE_IPTABLES_SUPPORT:kmod-nft-socket
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	LuCI Support for Xray.
endef

define Package/$(PKG_NAME)/config
menu "luci-app-xjay Configuration"
	depends on PACKAGE_$(PKG_NAME)

config PACKAGE_XRAY_INCLUDE_IPTABLES_SUPPORT
	bool "iptables support (21.02.x and below)"
	select PACKAGE_iptables
	select PACKAGE_iptables-mod-tproxy
	select PACKAGE_iptables-mod-iprange
	default n

config PACKAGE_XRAY_INCLUDE_NFTABLES_SUPPORT
	bool "nftables support (22.03.x and above)"
	select PACKAGE_nftables-json
	select PACKAGE_kmod-nft-tproxy
	select PACKAGE_kmod-nft-socket
	default y

endmenu
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/postinst
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/xjay
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/xjay.conf $(1)/etc/config/xjay
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/xjay.init $(1)/etc/init.d/xjay
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/xjay.uci-defaults $(1)/etc/uci-defaults/xjay
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/xjay
	$(INSTALL_DATA) ./files/luci/general.js $(1)/www/luci-static/resources/view/xjay/general.js
	$(INSTALL_DATA) ./files/luci/inbound.js $(1)/www/luci-static/resources/view/xjay/inbound.js
	$(INSTALL_DATA) ./files/luci/outbound.js $(1)/www/luci-static/resources/view/xjay/outbound.js
	$(INSTALL_DATA) ./files/luci/dns.js $(1)/www/luci-static/resources/view/xjay/dns.js
	$(INSTALL_DATA) ./files/luci/routing.js $(1)/www/luci-static/resources/view/xjay/routing.js
	$(INSTALL_DATA) ./files/luci/misc.js $(1)/www/luci-static/resources/view/xjay/misc.js
	$(INSTALL_DIR) $(1)/www/luci-static/resources
	$(INSTALL_DATA) ./files/luci/xjay.js $(1)/www/luci-static/resources/xjay.js
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) ./files/luci/luci-app-xjay.json.menu $(1)/usr/share/luci/menu.d/luci-app-xjay.json
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./files/luci/luci-app-xjay.json.acl $(1)/usr/share/rpcd/acl.d/luci-app-xjay.json
	$(INSTALL_DIR) $(1)/usr/share/xjay/utils
	$(INSTALL_DATA) ./files/utils/* $(1)/usr/share/xjay/utils
	$(INSTALL_DIR) $(1)/usr/share/xjay/firewall
	$(INSTALL_BIN) ./files/firewall/* $(1)/usr/share/xjay/firewall
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
