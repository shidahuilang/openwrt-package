# Copyright (C) 2016 Openwrt.org
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk


PKG_NAME:=luci-app-parentcontrol
PKG_LICENSE:=Apache-2.0
LUCI_TITLE:=LuCI support for Parent Control
LUCI_DEPENDS:=+iptables-mod-filter +kmod-ipt-filter
LUCI_PKGARCH:=all
include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature


