#
# Copyright (C) 2010-2011 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-qos-emong
PKG_VERSION:=1.4
PKG_RELEASE:=2


PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-qos-emong
  SECTION:=luci
  CATEGORY:=LuCI
  DEPENDS:=+tc +iptables-mod-conntrack-extra +iptables-mod-filter +iptables-mod-ipopt +iptables-mod-nat-extra +kmod-sched +iptables-mod-iprange +iptables-mod-hashlimit
  TITLE:=LuCI - Lua Configuration Interface
  URL:=http://
  MAINTAINER:=Jeroen Louwes <jeroen.louwes@gmail.com>
  SUBMENU:=3. Applications
  TITLE:=LuCI Support for qos-emong
endef

define Package/luci-app-qos-emong/description
luci app for qos-emong
endef

define Build/Prepare
	$(foreach po,$(wildcard ${CURDIR}/files/i18n/*.po), \
		po2lmo $(po) $(PKG_BUILD_DIR)/$(patsubst %.po,%.lmo,$(notdir $(po)));)
endef

define Build/Compile
endef

define Package/luci-app-qos-emong/postinst
#!/bin/sh 
[ -n "$${IPKG_INSTROOT}" ] || {
	( . /etc/uci-defaults/luci-qos-emong ) && rm -f /etc/uci-defaults/luci-qos-emong
	/etc/init.d/qos-emong enable
	exit 0
}
endef

define Package/luci-app-qos-emong/conffiles
/etc/config/qos-emong
endef

define Package/luci-app-qos-emong/install
	
	$(INSTALL_DIR) $(1)/etc/uci-defaults $(1)/etc/config $(1)/etc/init.d $(1)/etc/hotplug.d/iface
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n $(1)/usr/bin
	
	$(INSTALL_BIN) ./files/etc/uci-defaults/luci-qos-emong $(1)/etc/uci-defaults/
	$(INSTALL_CONF) ./files/etc/config/qos-emong $(1)/etc/config/qos-emong
	$(INSTALL_BIN) ./files/etc/init.d/qos-emong $(1)/etc/init.d/qos-emong
	$(INSTALL_BIN) ./files/etc/hotplug.d/iface/* $(1)/etc/hotplug.d/iface/
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/model/cbi/* $(1)/usr/lib/lua/luci/model/cbi/
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/controller/* $(1)/usr/lib/lua/luci/controller/
	$(INSTALL_BIN) ./files/usr/bin/qos-emong $(1)/usr/bin/qos-emong
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/qos-emong.zh-cn.lmo $(1)/usr/lib/lua/luci/i18n/
	
endef

$(eval $(call BuildPackage,luci-app-qos-emong))
