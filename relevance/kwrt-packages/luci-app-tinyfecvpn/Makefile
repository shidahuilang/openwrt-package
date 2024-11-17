#
# Copyright (C) 2019-2021 Tiou <dourokinga@gmail.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-tinyfecvpn
PKG_VERSION:=1.0.0
PKG_RELEASE:=2

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Tiou <dourokinga@gmail.com>

include $(INCLUDE_DIR)/package.mk

PKG_BUILD_DEPENDS:=luci

define Package/$(PKG_NAME)
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI Support for tinyFecVPN
	PKGARCH:=all

endef

define Package/$(PKG_NAME)/description
	LuCI Support for tinyFecVPN.
endef

define Build/Prepare
	$(foreach po,$(wildcard ${CURDIR}/files/luci/i18n/*.po), \
		po2lmo $(po) $(PKG_BUILD_DIR)/$(patsubst %.po,%.lmo,$(notdir $(po)));)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	( . /etc/uci-defaults/88_luci-tinyfecvpn ) && rm -f /etc/uci-defaults/88_luci-tinyfecvpn
fi
exit 0
endef

define Package/$(PKG_NAME)/conffiles
	/etc/config/tinyfecvpn
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/tinyfecvpn.*.lmo $(1)/usr/lib/lua/luci/i18n/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./files/luci/controller/*.lua $(1)/usr/lib/lua/luci/controller/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model
	$(INSTALL_DATA) ./files/luci/model/*.lua $(1)/usr/lib/lua/luci/model/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/tinyfecvpn
	$(INSTALL_DATA) ./files/luci/model/cbi/tinyfecvpn/*.lua $(1)/usr/lib/lua/luci/model/cbi/tinyfecvpn/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/tinyfecvpn
	$(INSTALL_DATA) ./files/luci/view/tinyfecvpn/*.htm $(1)/usr/lib/lua/luci/view/tinyfecvpn/
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/root/etc/config/tinyfecvpn $(1)/etc/config/tinyfecvpn
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/root/etc/init.d/tinyfecvpn $(1)/etc/init.d/tinyfecvpn
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/root/etc/uci-defaults/88_luci-tinyfecvpn $(1)/etc/uci-defaults/88_luci-tinyfecvpn
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
