#
# Copyright (C) 2020 muink <https://github.com/muink>
#
# This is free software, licensed under the MIT License
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

LUCI_NAME:=luci-app-change-mac

LUCI_TITLE:=LuCI for MAC address randomizer
LUCI_DEPENDS:=+bash +rgmac +getopt

LUCI_DESCRIPTION:=Assign a random MAC address to the designated interface on every time boot.

define Package/$(LUCI_NAME)/conffiles
/etc/config/change-mac
endef

define Package/$(LUCI_NAME)/prerm
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
