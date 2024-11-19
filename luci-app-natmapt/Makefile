# NATMap by heiher <https://github.com/heiher/natmap>
# Copyright (C) 2023-2024 muink <https://github.com/muink>
#
# This is free software, licensed under the Apache License, Version 2.0

include $(TOPDIR)/rules.mk

LUCI_NAME:=luci-app-natmapt

LUCI_TITLE:=LuCI Support for natmap
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+natmapt +coreutils-timeout

LUCI_DESCRIPTION:=TCP/UDP port mapping for full cone NAT

PKG_LICENSE:=Apache-2.0
PKG_MAINTAINER:=Anya Lin <hukk1996@gmail.com>, Richard Yu <yurichard3839@gmail.com>

PKG_UNPACK=$(CURDIR)/.prepare.sh $(PKG_NAME) $(CURDIR) $(PKG_BUILD_DIR)

define Package/$(LUCI_NAME)/prerm
#!/bin/sh
rm -f "$$IPKG_INSTROOT/usr/libexec/natmap/natmap-natest"
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
