#
# Copyright 2024 Rafał Wabik - IceG - From eko.one.pl forum
#
# Licensed to the GNU General Public License v3.0.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-at-socat
LUCI_TITLE:=LuCI JS Support for sending at commands using socat
MAINTAINER:=Rafał Wabik <4Rafal@gmail.com>
LUCI_DESCRIPTION:=LuCI JS interface for sending at commands using socat.
LUCI_DEPENDS:=+socat
LUCI_PKGARCH:=all

define Package/$(PKG_NAME)/conffiles
/etc/modem/atsocatcommands.user
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
