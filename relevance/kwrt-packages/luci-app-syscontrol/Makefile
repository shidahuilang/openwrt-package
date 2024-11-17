# This is open source software, licensed under the MIT License.
#
# Copyright (C) 2024 BobbyUnknown
#
# Description:
# This software provides a RAM release scheduling application for OpenWrt.
# The application allows users to configure and automate the process of
# releasing RAM on their OpenWrt routers at specified intervals, helping
# to optimize system performance and resource management through
# a user-friendly web interface.


include $(TOPDIR)/rules.mk

PKG_MAINTAINER:=BobbyUnknown <bobbyun.known88@gmail.com>

LUCI_TITLE:=LuCI for System Control
LUCI_DEPENDS:=+luci-base
LUCI_PKGARCH:=all

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
