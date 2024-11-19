# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2024 asvow

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI for Tailscale
LUCI_DEPENDS:=+tailscale
LUCI_PKGARCH:=all


include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature