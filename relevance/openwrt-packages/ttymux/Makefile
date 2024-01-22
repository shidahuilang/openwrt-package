#
# Copyright (C) 2013-2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=ttymux
PKG_VERSION:=1
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL=https://github.com/wd5gnr/SerialMux.git
PKG_SOURCE_VERSION:=553d6e5b0d96773e8a7aaeb30d5bd1a1d1e3c8b9

PKG_MAINTAINER:=Konstatnine Shevlakov <shevlakov@132lan.ru>
PKG_LICENSE:=GPL-2.0

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

MAKE_PATH:=linux

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=Telephony
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Serial port multiplexer
  DEPENDS:=+libpthread +libstdcpp
  URL:=https://github.com/wd5gnr/SerialMux
endef

define Package/$(PKG_NAME)/description
	Is a serial multiplexer and demultiplexer protocol for Linux and a microcontroller.
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/linux/ttymux $(1)/usr/bin
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
