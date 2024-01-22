# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2022 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=dns2tcp
PKG_VERSION:=1.1.0
PKG_RELEASE:=9

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/zfl9/dns2tcp.git
PKG_SOURCE_DATE:=2020-05-05
PKG_SOURCE_VERSION:=558b07e4c1f9bd5be19e60892a0bce7661ed99a5
PKG_MIRROR_HASH:=skip

PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>
PKG_LICENSE:=AGPL-3.0-only
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/dns2tcp
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=IP Addresses and Names
  TITLE:=utility to convert dns query from udp to tcp
  URL:=https://github.com/zfl9/dns2tcp
endef

TARGET_CFLAGS+= $(FPIC) -flto
MAKE_FLAGS+= \
	CFLAGS="-std=c99 $(TARGET_CFLAGS)" \
	EVCFLAGS="$(TARGET_CFLAGS)"

define Package/dns2tcp/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/dns2tcp $(1)/usr/bin/
endef

$(eval $(call BuildPackage,dns2tcp))
