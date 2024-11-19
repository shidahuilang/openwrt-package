#
# This is free software, licensed under the MIT License.
#

include $(TOPDIR)/rules.mk

PKG_MAINTAINER:=Markus Hütter <mh@hudra.net>
PKG_LICENSE:=GPL-3.0-or-later

LUCI_TITLE:=LuCI support for QoSmate
LUCI_DEPENDS:=+qosmate +luci-lib-jsonc +lua
LUCI_PKGARCH:=all

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
