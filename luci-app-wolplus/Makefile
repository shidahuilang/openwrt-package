# Copyright (C) 2016 Openwrt.org
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for Wakeup-On-Lan-plus
LUCI_DEPENDS:=+etherwake
LUCI_PKGARCH:=all
PKG_VERSION:=1.0.2
PKG_RELEASE:=1

PKG_MAINTAINER:=siwind
PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
