

include $(TOPDIR)/rules.mk

PKG_VERSION:=1.0.0
PKG_RELEASE:=20220629

LUCI_TITLE:=LuCI support for heimdall
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+docker +luci-lib-iform

define Package/luci-app-heimdall/conffiles
/etc/config/heimdall
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature

