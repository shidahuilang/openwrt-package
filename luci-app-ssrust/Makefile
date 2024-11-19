#
# Copyright (C) 2017 Yousong Zhou <yszhou4tech@gmail.com>
# Copyright (C) 2024 Anya Lin <hukk1996@gmail.com>
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-shadowsocks-rust
LUCI_NAME:=luci-app-shadowsocks-rust
LUCI_TITLE:=LuCI Support for shadowsocks-rust
LUCI_DEPENDS:=+luci-base +shadowsocks-rust-config

PKG_LICENSE:=Apache-2.0

define Package/luci-app-shadowsocks-rust/conffiles
/etc/config/shadowsocks-rust
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
