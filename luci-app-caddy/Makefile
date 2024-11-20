# Copyright (C) 2016 Openwrt.org
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-caddy

LUCI_TITLE:=LuCI support for caddy
LUCI_DEPENDS:=

define Package/$(PKG_NAME)/conffiles
/etc/caddy
endef

define Package/$(PKG_NAME)/postrm
#!/bin/sh
[ -f /etc/caddy/Caddyfile ] && rm -rf /etc/caddy/Caddyfile >/dev/null 2>&1
 return 0
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
[ -n "${IPKG_INSTROOT}" ] || {
	( . /etc/uci-defaults/luci-caddy ) && rm -f /etc/uci-defaults/luci-caddy
	exit 0
}
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
