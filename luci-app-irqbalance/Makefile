#
# Copyright (C) 2022 wulishui <wulishui@gmail.com>
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=Luci for irqbalance
LUCI_DEPENDS:=+irqbalance
LUCI_PKGARCH:=all

define Package/luci-app-irqbalance/preinst
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature

