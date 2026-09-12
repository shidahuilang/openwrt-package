# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2017-2020 Yousong Zhou <yszhou4tech@gmail.com>
# Copyright (C) 2021 ImmortalWrt.org
#

include $(TOPDIR)/rules.mk

PKG_NAME:=shadowsocks-rust
PKG_VERSION:=1.25.0
PKG_RELEASE:=3

PKG_SOURCE:=shadowsocks-rust-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/shadowsocks/shadowsocks-rust/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=477a525e9b11d4c90ded6629552548d00a32675ec6f6f18ee45c98447e54b5f3
PKG_BUILD_DIR:=$(BUILD_DIR)/shadowsocks-rust-$(PKG_VERSION)

PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>
PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_DEPENDS:=rust/host
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/rust/rust-package.mk

define Package/shadowsocks-rust/Default
  define Package/shadowsocks-rust-$(1)
    SECTION:=net
    CATEGORY:=Network
    SUBMENU:=Web Servers/Proxies
    TITLE:=shadowsocks-rust $(1)
    URL:=https://github.com/shadowsocks/shadowsocks-rust
    DEPENDS:=@USE_MUSL $$(RUST_ARCH_DEPENDS) @!(TARGET_x86_geode||TARGET_x86_legacy)
  endef

  define Package/shadowsocks-rust-$(1)/install
	$$(INSTALL_DIR) $$(1)/usr/bin
	$$(INSTALL_BIN) $$(PKG_BUILD_DIR)/target/$$(RUSTC_TARGET_ARCH)/release/$(1) $$(1)/usr/bin
  endef
endef

SHADOWSOCKS_COMPONENTS:=sslocal ssmanager ssserver ssurl ssservice
$(foreach component,$(SHADOWSOCKS_COMPONENTS), \
  $(eval $(call Package/shadowsocks-rust/Default,$(component))) \
)

define Build/Compile
	$(call Build/Compile/Cargo)
endef

$(foreach component,$(SHADOWSOCKS_COMPONENTS), \
  $(eval $(call BuildPackage,shadowsocks-rust-$(component))) \
)
