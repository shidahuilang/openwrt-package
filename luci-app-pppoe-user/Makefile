#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=PPPoE Server User Management
LUCI_DEPENDS:=+luci-compat +kmod-nft-connlimit
LUCI_PKGARCH:=all
PKG_DATE:=2024-10-25

define Package/luci-app-pppoe-user/preinst
#!/bin/sh
rm -rf $${IPKG_INSTROOT}/etc/config/pppoe-user >/dev/null 2>&1
rm -rf $${IPKG_INSTROOT}/etc/init.d/pppoe-user >/dev/null 2>&1
mkdir -p $${IPKG_INSTROOT}/var/pppoe-user/log/userinfo >/dev/null 2>&1
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
