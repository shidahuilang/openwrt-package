# Copyright (C) 2016 Openwrt.org
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for NginxManager From sundaqiang
LUCI_DEPENDS:=+luci-nginx +luci-ssl-nginx +luci-ssl-openssl
LUCI_PKGARCH:=all
PKG_VERSION:=1.0
PKG_RELEASE:=20211030
PKG_MAINTAINER:=sundaqiang

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
