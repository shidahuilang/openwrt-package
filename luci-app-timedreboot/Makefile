# [K] (C)2020
# http://github.com/kongfl888

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-timedreboot
PKG_VERSION:=1.0
PKG_RELEASE:=2
PKG_DATE:=20220920

PKG_MAINTAINER:=kongfl888 <kongfl888@outlook.com>
PKG_LICENSE:=GPL-3.0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=LuCI Application to timing reboot.
  PKGARCH:=all
  DEPENDS:=+luci +bash
endef

define Package/$(PKG_NAME)/description
	LuCI Application to timing reboot
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/config
	cp ./root/etc/config/timedreboot $(1)/etc/config/timedreboot

	$(INSTALL_DIR) $(1)/etc/init.d
	cp ./root/etc/init.d/timedreboot $(1)/etc/init.d/timedreboot

	$(INSTALL_DIR) $(1)/usr
	cp -pR ./root/usr/* $(1)/usr/

	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	cp -pR ./luasrc/* $(1)/usr/lib/lua/luci/

	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	po2lmo ./po/zh-cn/timedreboot.po $(1)/usr/lib/lua/luci/i18n/timedreboot.zh-cn.lmo
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
    chmod a+x ${IPKG_INSTROOT}/etc/init.d/timedreboot >/dev/null 2>&1
    chmod a+x ${IPKG_INSTROOT}/usr/bin/dorboot >/dev/null 2>&1
    exit 0
endef

define Package/$(PKG_NAME)/postrm
#!/bin/sh
    sed -i '/dorboot/d' /etc/crontabs/root >/dev/null 2>&1 || echo ""
    rm -rf /tmp/luci-modulecache/ >/dev/null 2>&1 || echo ""
    rm -f /tmp/luci-indexcache >/dev/null 2>&1 || echo ""
    exit 0
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

