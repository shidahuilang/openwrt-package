# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Elon Huang <elonhhuang@gmail.com>

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-rclone
PKG_VERSION:=1.4.1
PKG_RELEASE:=3

LUCI_TITLE:=LuCI support for Rclone
LUCI_DEPENDS:=+luci-lib-ipkg +rclone-config \
              +PACKAGE_$(PKG_NAME)_INCLUDE_rclone-webui:rclone-webui-react \
              +PACKAGE_$(PKG_NAME)_INCLUDE_rclone-ng:rclone-ng
LUCI_PKGARCH:=all

PKG_LICENSE:=GPL-3.0-or-later
PKG_MAINTAINER:=ElonH <elonhhuang@gmail.com>

define Package/luci-app-rclone/config
config PACKAGE_$(PKG_NAME)_INCLUDE_rclone-webui
	bool "Include rclone-webui"
	default y

config PACKAGE_$(PKG_NAME)_INCLUDE_rclone-ng
	bool "Include rclone-ng (another webui)"
	default y
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
