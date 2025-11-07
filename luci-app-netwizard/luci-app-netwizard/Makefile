# Copyright 2019 X-WRT <dev@x-wrt.com>
# Copyright 2022-2025 sirpdboy <herboy2008@gmail.com>

include $(TOPDIR)/rules.mk

NAME:=netwizard
PKG_NAME:=luci-app-$(NAME)
PKG_VERSION:=1.10.1
PKG_RELEASE:=20251106

PKG_LICENSE:=GPLv3
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=sirpdboy <herboy2008@gmail.com>

LUCI_TITLE:=LuCI Support for Wizard
LUCI_DEPENDS:=+libustream-openssl +ca-bundle
LUCI_PKGARCH:=all

define Package/$(PKG_NAME)/conffiles
/etc/config/netwizard
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
