# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021-2022  sirpdboy  <herboy2008@gmail.com>
# 
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

PKG_NAME:=lucky
PKG_VERSION:=1.5.1
PKG_RELEASE:=3

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Lucky dynamic domain name ddns-go service, socat,frp  
	DEPENDS:=@(i386||x86_64||arm||aarch64||mipsel||mips)
	URL:=https://github.com/gdy666/lucky
endef

define Package/$(PKG_NAME)/description
  Main functions of Lucky: dynamic domain name ddns-go service, socat,frp 
endef
define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	[ -f /etc/uci-defaults/luci-lucky ] && /etc/uci-defaults/luci-lucky && rm -f /etc/uci-defaults/luci-lucky
fi
endef

ifeq ($(ARCH),i386)
	LUCKY_DIR:=x86
endif

ifeq ($(ARCH),x86_64)
	LUCKY_DIR:=x86
endif

ifeq ($(ARCH),arm)
	LUCKY_DIR:=arm
	ifeq ($(CONFIG_HAS_FPU),)
		LUCKY_DIR:=arm
	endif
endif

ifeq ($(ARCH),aarch64)
	LUCKY_DIR:=armv7
endif

ifeq ($(ARCH),mips)
	LUCKY_DIR:=mips
endif

ifeq ($(ARCH),mipsel)
	LUCKY_DIR:=mipsle
endif

define Build/Compile
	true
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/etc/init.d $(1)/etc/uci-defaults $(1)/etc/lucky
	$(INSTALL_BIN) ./files/lucky.init $(1)/etc/init.d/lucky
	$(INSTALL_BIN) ./files/luci-lucky.uci-default $(1)/etc/uci-defaults/luci-lucky
	$(INSTALL_BIN) ./files/$(LUCKY_DIR)/lucky $(1)/usr/bin/lucky
	$(INSTALL_DATA) ./files/lucky-default.conf $(1)/etc/lucky/lucky-default.conf

endef

$(eval $(call BuildPackage,$(PKG_NAME)))
