# alwaysonline by Jamesits <https://github.com/Jamesits/alwaysonline>
# Copyright (C) 2023-2024 muink <https://github.com/muink>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-alwaysonline

LUCI_TITLE:=LuCI Support for alwaysonline
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+uci-alwaysonline

LUCI_DESCRIPTION:=Hijack/bypass Windows NCSI and iOS portal detection

define Package/$(LUCI_NAME)/conffiles
endef

define Package/$(LUCI_NAME)/postinst
endef

define Package/$(LUCI_NAME)/prerm
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
