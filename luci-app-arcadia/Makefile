

include $(TOPDIR)/rules.mk


LUCI_TITLE:=LuCI support for arcadia
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+lsblk +docker +dockerd +luci-lib-taskd

define Package/luci-app-arcadia/conffiles
/etc/config/arcadia
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature

