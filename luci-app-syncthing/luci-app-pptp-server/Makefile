# Copyright (C) 2018-2021 Lienol <lawlienol@gmail.com>
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for PPTP VPN Server
LUCI_DEPENDS:=+pptpd +kmod-mppe +ppp +luci-lib-jsonc
LUCI_PKGARCH:=all
PKG_VERSION:=20211223
PKG_RELEASE:=2

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
