include $(TOPDIR)/rules.mk

LUCI_TITLE:=Configrure modem bands via mmcli utility
LUCI_DEPENDS:=+modemmanager +luci-compat
PKG_LICENSE:=GPLv3

define Package/luci-app-mmconfig/postrm
	rm -f /etc/config/modemconfig
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
