#
# Copyright (C) 2006-2009 OpenWrt.org
# Copyright (C) 2005-2016 Weijie Gao <hackpascal@gmail.com>
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=brlaser
PKG_VERSION:=6
PKG_RELEASE:=2

PKG_SOURCE_URL:=https://github.com/pdewacht/brlaser.git
PKG_SOURCE_PROTO:=git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=23117fe9e0266396e4791cdae84d979928aed135
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz

PKG_FIXUP:=autoreconf

PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/brlaser
  SECTION:=print
  CATEGORY:=Printing and Imaging
  TITLE:=Driver for (some) Brother laster printers
  DEPENDS:=+libcupsimage +libstdcpp
  MAINTAINER:=Weijie Gao <hackpascal@gmail.com>
  URL:=https://github.com/pdewacht/brlaser
endef

define Package/brlaser/description
  Driver for Brother DCP-7030 / Brother DCP-7055 / Brother DCP-7065DN
endef

define Package/brlaser/install
	$(INSTALL_DIR) $(1)/usr/lib/cups/filter
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/lib/cups/filter/rastertobrlaser $(1)/usr/lib/cups/filter/

	$(INSTALL_DIR) $(1)/usr/share/cups/drv
	$(INSTALL_DATA) $(PKG_INSTALL_DIR)/usr/share/cups/drv/brlaser.drv $(1)/usr/share/cups/drv/

	(cd $(PKG_BUILD_DIR) && ppdc brlaser.drv)

	$(INSTALL_DIR) $(1)/usr/share/ppd/Brother
	$(CP) $(PKG_BUILD_DIR)/ppd/*.ppd $(1)/usr/share/ppd/Brother

	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/brlaser-set-cups-filter-permission $(1)/etc/uci-defaults/
endef

$(eval $(call BuildPackage,brlaser))
