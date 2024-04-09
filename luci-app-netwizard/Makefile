# Copyright 2019 X-WRT <dev@x-wrt.com>
# Copyright 2022-2024 sirpdboy  

include $(TOPDIR)/rules.mk

NAME:=netwizard
PKG_NAME:=luci-app-$(NAME)
PKG_VERSION:=1.8.8
PKG_RELEASE:=20240407

PKG_LICENSE:=GPLv3
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Chen Minqiang <ptpt52@gmail.com>

LUCI_TITLE:=LuCI Support for Wizard
LUCI_DEPENDS:=+luci-compat
LUCI_PKGARCH:=all

define Package/$(PKG_NAME)/conffiles
/etc/config/netwizard
endef

include $(TOPDIR)/feeds/luci/luci.mk

define Package/luci-app-netwizard/postinst
#!/bin/sh
if [ -z "$$IPKG_INSTROOT" ]; then
  ( . /etc/uci-defaults/luci-netwizard-defaults )
  rm -f /etc/uci-defaults/luci-netwizard-defaults
  rm -rf /tmp/luci*
fi
exit 0
endef
# call BuildPackage - OpenWrt buildroot signature
