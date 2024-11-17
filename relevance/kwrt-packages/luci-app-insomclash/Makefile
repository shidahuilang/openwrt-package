# This is open source software, licensed under the MIT License.
#
# Copyright (C) 2024 BobbyUnknown
#
# Description:
# This software provides a tunneling application for OpenWrt using Mihomo core.
# The application allows users to configure and manage proxy rules, connections,
# and network traffic routing through a user-friendly web interface, enabling
# advanced networking capabilities and traffic control on OpenWrt routers.


include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-insomclash
PKG_VERSION:=1.0.0
PKG_RELEASE:=17

PKG_MAINTAINER:=BobbyUnknown <bobbyun.known88@gmail.com>

LUCI_TITLE:=LuCI interface for InsomClash
LUCI_DEPENDS:=+luci-base +dnsmasq-full +ipset +ip-full +ruby +ruby-yaml
LUCI_PKGARCH:=all

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=$(LUCI_TITLE)
  DEPENDS:=$(LUCI_DEPENDS)
  PKGARCH:=$(LUCI_PKGARCH)
endef

define Package/$(PKG_NAME)/description
  LuCI interface for InsomClash, a Mihomo TProxy implementation for OpenWrt.
endef

define Build/Prepare
	# No preparation steps required
endef

define Build/Compile
	# No compilation steps required
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/share/insomclash
	$(INSTALL_BIN) ./root/usr/share/insomclash/* $(1)/usr/share/insomclash/

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./root/etc/init.d/insomclash $(1)/etc/init.d/

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./root/etc/config/insomclash $(1)/etc/config/

	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./root/usr/share/rpcd/acl.d/* $(1)/usr/share/rpcd/acl.d/

	$(INSTALL_DIR) $(1)/etc/insomclash/profile
	$(INSTALL_DATA) ./root/etc/insomclash/profile/config.yaml $(1)/etc/insomclash/profile/

	$(INSTALL_DIR) $(1)/var/log/insomclash
	$(INSTALL_DIR) $(1)/etc/insomclash/core
	$(INSTALL_DIR) $(1)/etc/insomclash/run
	$(INSTALL_DIR) $(1)/etc/insomclash/run/proxy
	$(INSTALL_DIR) $(1)/etc/insomclash/run/rule
	$(INSTALL_DIR) $(1)/etc/insomclash/run/ui
	$(INSTALL_DIR) $(1)/etc/insomclash/run/ui/assets
	$(CP) ./root/etc/insomclash/run/ui/* $(1)/etc/insomclash/run/ui/

	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) ./root/usr/share/luci/menu.d/* $(1)/usr/share/luci/menu.d/

	$(INSTALL_DIR) $(1)/www/luci-static/resources/insomclash/assets
	$(INSTALL_DATA) ./htdocs/luci-static/resources/insomclash/assets/* $(1)/www/luci-static/resources/insomclash/assets

	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/insomclash
	$(INSTALL_DATA) ./htdocs/luci-static/resources/view/insomclash/* $(1)/www/luci-static/resources/view/insomclash/
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
[ -n "$$IPKG_INSTROOT" ] || {
    /etc/init.d/insomclash enable
    /etc/init.d/insomclash start
    sleep 5
    /etc/init.d/insomclash stop
	/etc/init.d/insomclash disable
}
exit 0
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
[ -f /etc/init.d/insomclash ] && {
    /etc/init.d/insomclash status | grep -q "running" && {
        /etc/init.d/insomclash stop >/dev/null 2>&1
    }
    /etc/init.d/insomclash disable >/dev/null 2>&1
}
exit 0
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
