# Copyright (C) 2018 XiaoShan mivm.cn

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-k3screenctrl
PKG_VERSION:=1.1.0
PKG_RELEASE:=2

PKG_LICENSE:=GPLv3
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Hill <lufanzhong@gmail.com>

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI Support for k3screenctrl
	DEPENDS:=+k3screenctrl
endef

define Package/$(PKG_NAME)/description
	LuCI Support for k3screenctrl.
endef

define Build/Prepare
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./files/luci/controller/k3screenctrl.lua $(1)/usr/lib/lua/luci/controller/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi
	$(INSTALL_DATA) ./files/luci/model/cbi/k3screenctrl.lua $(1)/usr/lib/lua/luci/model/cbi/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	po2lmo ./files/luci/i18n/k3screenctrl.zh-cn.po $(1)/usr/lib/lua/luci/i18n/k3screenctrl.zh-cn.lmo
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
