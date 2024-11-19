#
# Copyright (C) 2024 gSpot (https://github.com/gSpotx2f/luci-app-disks-info)
#
# This is free software, licensed under the MIT License.
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=Information about connected disk devices (partitions, filesystems, SMART).
LUCI_DEPENDS:=+fdisk +smartmontools +smartmontools-drivedb
LUCI_PKGARCH:=all
PKG_LICENSE:=MIT

#include $(TOPDIR)/feeds/luci/luci.mk
include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
