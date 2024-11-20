include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-coredns

LUCI_TITLE:=LuCI Support for coredns
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+luci-compat +curl

define Package/$(PKG_NAME)/conffiles
	/etc/config/coredns
endef

define Package/$(PKG_NAME)/install
	
endef

define Package/$(PKG_NAME)/preinst
	
endef

define Package/$(PKG_NAME)/postinst
	#!/bin/sh
	chmod +x /etc/init.d/coredns
	chmod +x /usr/share/coredns/*.sh
	rm -rf /usr/lib/lua/luci/i18n/coredns.zh-cn.lmo
	cp /usr/share/coredns/coredns.zh-cn.lmo /usr/lib/lua/luci/i18n/
endef

define Package/$(PKG_NAME)/prerm
	 
endef

define Package/$(PKG_NAME)/postrm
	#!/bin/sh
	rm -rf /usr/lib/lua/luci/i18n/coredns.zh-cn.lmo
	rm -rf /usr/share/coredns
	rm -rf /tmp/coredns.log
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
