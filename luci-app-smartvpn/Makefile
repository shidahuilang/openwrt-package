# Copyright 2021 Daniel Yang (gzdaniel@me.com)
# This is free software, licensed under the Apache License, Version 2.0

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for SmartVPN
LUCI_DEPENDS:=+softethervpn-server +luci-lib-jsonc +luci-app-mwan3 +luci-app-statistics +luci-app-nlbwmon
LUCI_PKGARCH:=all

PKG_LICENSE:=Apache-2.0

define Package/luci-app-smartvpn/conffiles
/etc/config/smartvpn
/etc/smartvpn/user_mainland.txt
/etc/smartvpn/user_oversea.txt
/etc/smartvpn/user_hongkong.txt
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
