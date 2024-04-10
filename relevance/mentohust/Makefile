# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2014-2015 KyleRicardo
# Copyright (C) 2021-2022 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=mentohust
PKG_VERSION:=0.3.1
PKG_RELEASE:=$(AUTORELASE)

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/KyleRicardo/MentoHUST-OpenWrt-ipk.git
PKG_SOURCE_DATE:=2018-11-27
PKG_SOURCE_VERSION:=557cffca8032b6d8ac948be8a79255dc64a1915d
PKG_MIRROR_HASH:=b7374615e46a380a44f51d39604da1783374f0aded334264fc0b41b31167fdf0

PKG_BUILD_PARALLEL:=1
MAKE_PATH:=src

include $(INCLUDE_DIR)/package.mk

define Package/mentohust
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Campus Network
  TITLE:=A Ruijie Client Daemon
  URL:=https://github.com/KyleRicardo/MentoHUST-OpenWrt-ipk
  DEPENDS:=+libpcap
endef

define Package/mentohust/description
  A Ruijie Client Daemon, most usually used in Chinese universities.
endef

define Package/mentohust/conffiles
/etc/mentohust.conf
endef

ifdef CONFIG_USE_GLIBC
  TARGET_LDFLAGS+= -ldl
endif

define Package/mentohust/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/mentohust $(1)/usr/sbin/mentohust
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/src/mentohust.conf $(1)/etc/mentohust.conf
endef

$(eval $(call BuildPackage,mentohust))
