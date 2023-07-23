# Copyright (C) 2019 Openwrt.org
#
# This is free software, licensed under the GNU General Public License v3.
# 

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI disk monitor
LUCI_DEPENDS:=+smartmontools
LUCI_PKGARCH:=all
PKG_NAME:=luci-app-smartinfo
PKG_VERSION:=1.0
PKG_RELEASE:=3
PKG_MAINTAINER:=<https://github.com/animefansxj/luci-app-smartinfo>

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
