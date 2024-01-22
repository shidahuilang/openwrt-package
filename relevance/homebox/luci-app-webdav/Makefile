# Copyright (C) 2021 Openwrt.org
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for Webdav
LUCI_DEPENDS:=+gowebdav
LUCI_PKGARCH:=all

PKG_NAME:=luci-app-webdav

define Package/$(PKG_NAME)/conffiles
/etc/config/webdav
/etc/webdav/
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
