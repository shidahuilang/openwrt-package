# Copyright 2023- Douglas Orend <doug.orend2@gmail.com>
# This is free software, licensed under the Apache License, Version 2.0

include $(TOPDIR)/rules.mk

PKG_LICENSE:=Apache-2.0
PKG_NAME:=luci-app-nodogsplash
PKG_VERSION:=2.0.1
PKG_RELEASE:=2
PKG_MAINTAINER:=Douglas Orend <doug.orend2@gmail.com>

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-nodogsplash
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI support for NoDogSplash
	PKGARCH:=all
	DEPENDS:=+nodogsplash +luci-base
endef

define Package/luci-app-nodogsplash/description
	LuCI Support for NoDogSplash
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/luci-app-nodogsplash/install
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/nodogsplash/
	$(INSTALL_DATA) ./htdocs/luci-static/resources/view/nodogsplash/*.js $(1)/www/luci-static/resources/view/nodogsplash/

	$(INSTALL_DIR) $(1)/usr/libexec/rpcd/
	$(INSTALL_DATA) ./root/usr/libexec/rpcd/luci.nodogsplash $(1)/usr/libexec/rpcd/

	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d/
	$(INSTALL_DATA) ./root/usr/share/luci/menu.d/luci-app-nodogsplash.json $(1)/usr/share/luci/menu.d/

	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./root/usr/share/rpcd/acl.d/luci-app-nodogsplash.json $(1)/usr/share/rpcd/acl.d/
endef

$(eval $(call BuildPackage,luci-app-nodogsplash))
