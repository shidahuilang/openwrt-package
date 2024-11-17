# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Elon Huang <elonhhuang@gmail.com>

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-rclone

LUCI_TITLE:=LuCI support for Rclone
LUCI_DEPENDS:=+rclone-config +fuse-overlayfs +fuse3-utils \
              +PACKAGE_$(PKG_NAME)_INCLUDE_rclone-webui:rclone-webui-react \
              +PACKAGE_$(PKG_NAME)_INCLUDE_rclone-ng:rclone-ng

PKG_CONFIG_DEPENDS:= \
	CONFIG_PACKAGE_$(PKG_NAME)_INCLUDE_rclone-webui \
	CONFIG_PACKAGE_$(PKG_NAME)_INCLUDE_rclone-ng

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
