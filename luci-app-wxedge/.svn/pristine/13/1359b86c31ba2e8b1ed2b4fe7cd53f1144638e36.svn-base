

include $(TOPDIR)/rules.mk

PKG_VERSION:=1.0.3
PKG_RELEASE:=20220715

LUCI_TITLE:=LuCI support for wxedge
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+docker +luci-lib-iform

define Package/luci-app-wxedge/conffiles
/etc/config/wxedge
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature

