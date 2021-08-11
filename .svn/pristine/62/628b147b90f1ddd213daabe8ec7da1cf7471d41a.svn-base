# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=tcping-simple
PKG_VERSION:=1.3.5
PKG_RELEASE:=$(AUTORELEASE)

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/MushrooM93/tcping.git
PKG_SOURCE_DATE:=2018-08-10
PKG_SOURCE_VERSION:=b9ee61a5c1d05f228aa70027331556f0c27dd4c2
PKG_MIRROR_HASH:=1f084e097e976f351a4a824b967cf8148c7387ffa782770d762d2bde9e05ffc1

include $(INCLUDE_DIR)/package.mk

define Package/tcping-simple
  SECTION:=net
  CATEGORY:=Network
  TITLE:=the operation is similar to ping but it does not use the ICMP protocol
  URL:=https://github.com/MushrooM93/tcping
endef

define Package/tcping-simple/description
  tcping support ipv4/ipv6 dual-stack in linux, the operation is similar
  to ping but it does not use the ICMP protocol.
endef

define Build/Compile
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_LDFLAGS) $(PKG_BUILD_DIR)/tcping.c -o $(PKG_BUILD_DIR)/tcping-simple
endef

define Package/tcping-simple/install
	$(INSTALL_DIR) $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/tcping-simple $(1)/usr/bin/
endef

$(eval $(call BuildPackage,tcping-simple))
