

include $(TOPDIR)/rules.mk

PKG_VERSION:=1.0.1-20220715
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for nastools
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+docker +luci-lib-iform

define Package/luci-app-nastools/conffiles
/etc/config/nastools
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature

