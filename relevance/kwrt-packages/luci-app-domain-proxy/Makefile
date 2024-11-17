include $(TOPDIR)/rules.mk

PKG_LICENSE:=GPLv3
PKG_MAINTAINER:=Yu <mukaiu@live.com>

LUCI_TITLE:=Domain Proxy for redsocks.
LUCI_DESCRIPTION:=Domain Proxy for redsocks.
LUCI_DEPENDS:=+luci-base

define Package/luci-app-domain-proxy/conffiles
/etc/config/domain-proxy
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
