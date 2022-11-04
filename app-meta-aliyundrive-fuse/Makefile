# This is free software, licensed under the Apache License, Version 2.0 .

include $(TOPDIR)/rules.mk

PKG_VERSION:=0.1.13
PKG_RELEASE:=1
META_TITLE:=阿里云盘Fuse
META_TITLE.en:=Aliyun Drive Fuse
META_DEPENDS:=+aliyundrive-fuse +luci-i18n-aliyundrive-fuse-zh-cn +luci-app-aliyundrive-fuse
META_DESCRIPTION:=阿里云盘Fuse磁盘挂载，用于配合Emby或者Jellyfin观看阿里云盘内容，目前只读，不支持写入。
META_DESCRIPTION.en:=Mount aliyun drive (aliyundrive.com) locally, read-only
META_AUTHOR:=messense
META_ARCH:=x86_64 aarch64_cortex-a53
META_TAGS:=net tool
META_LUCI_ENTRY:=/cgi-bin/luci/admin/services/aliyundrive-fuse
META_WEBSITE:=https://github.com/messense/aliyundrive-fuse
META_TUTORIAL:=https://doc.linkease.com/zh/guide/easepi/advanced.html\#网盘影院之阿里云盘fuse

include ../../meta.mk

# call BuildPackage - OpenWrt buildroot signature
