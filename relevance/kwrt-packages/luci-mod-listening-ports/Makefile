# Copyright 2024- Douglas Orend <doug.orend2@gmail.com>
# This is free software, licensed under the Apache License, Version 2.0

include $(TOPDIR)/rules.mk

PKG_LICENSE:=Apache-2.0
PKG_NAME:=luci-mod-listening-ports
PKG_VERSION:=1.0
PKG_RELEASE:=2
PKG_MAINTAINER:=Douglas Orend <doug.orend2@gmail.com>

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/luci-mod-listening-ports
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=Server Listening Ports
	PKGARCH:=all
	DEPENDS:=+luci-base +bash
endef

define Package/luci-mod-listening-ports/description
	Shows Server Listening Ports for LuCI 
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/luci-mod-listening-ports/install
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/
	$(INSTALL_DATA) ./htdocs/luci-static/resources/view/*.js $(1)/www/luci-static/resources/view/

	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d/
	$(INSTALL_DATA) ./root/usr/share/luci/menu.d/luci-mod-listening-ports.json $(1)/usr/share/luci/menu.d/

	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./root/usr/share/rpcd/acl.d/luci-mod-listening-ports.json $(1)/usr/share/rpcd/acl.d/
endef

$(eval $(call BuildPackage,luci-mod-listening-ports))
