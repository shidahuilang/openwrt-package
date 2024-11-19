#
# This is free software, licensed under the GPL License, Version 3.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for Samba4 Users Management
LUCI_DEPENDS:=+samba4-server +shadow-utils +shadow-useradd +shadow-groupadd +shadow-userdel +shadow-groupdel
LUCI_PKGARCH:=all

PKG_MAINTAINER:=sbwml <admin@cooluc.com>

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
