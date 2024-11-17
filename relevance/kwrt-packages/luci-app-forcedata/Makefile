
include $(TOPDIR)/rules.mk

PKG_MAINTAINER:=forcedata

LUCI_TITLE:=LuCI support for forcedata
LUCI_PKGARCH:=all
LUCI_DEPENDS:= +luci-lib-taskd


define Package/luci-app-forcedata/conffiles
/etc/config/forcedata
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
