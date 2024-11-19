#
# Copyright (C) 2008-2014 The LuCI Team <luci@lists.subsignal.org>
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk


LUCI_TITLE:=LuCI support for vnt
LUCI_DEPENDS:=+luci-lib-fs +kmod-tun
LUCI_PKGARCH:=all

PKG_NAME:=luci-app-vnt

define Package/$(PKG_NAME)/prerm
#!/bin/sh
if [ -f /etc/config/vnt ] ; then
  echo "备份vnt配置文件/etc/config/vnt到/tmp/vnt_backup"
  echo "不重启设备之前再次安装luci-app-vnt 配置不丢失,不用重新配置"
  mv -f /etc/config/vnt /tmp/vnt_backup
fi
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
chmod +x /etc/init.d/vnt
if [ -f /tmp/vnt_backup ] ; then
  echo "发现vnt备份配置文件/tmp/vnt_backup，开始恢复到/etc/config/vnt"
  mv -f /tmp/vnt_backup /etc/config/vnt
  echo "请前往 VPN - VNT 界面进行重启插件"
fi
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
