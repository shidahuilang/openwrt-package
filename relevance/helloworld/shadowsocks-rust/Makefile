# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2017-2020 Yousong Zhou <yszhou4tech@gmail.com>
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=shadowsocks-rust
PKG_VERSION:=1.24.0
PKG_RELEASE:=2

PKG_SOURCE_URL:=https://github.com/shadowsocks/shadowsocks-rust/releases/download/v$(PKG_VERSION)/

ifeq ($(ARCH),aarch64)
  PKG_RELEASE_ARCH:=aarch64-unknown-linux-musl
  PKG_HASH:=e00b3d3c46f9c1773353ef5f2b1d2af5f6268a3385f3f813fc5ec0aada99f491
else ifeq ($(ARCH),arm)
  # Referred to golang/golang-values.mk
  ARM_CPU_FEATURES:=$(word 2,$(subst +,$(space),$(call qstrip,$(CONFIG_CPU_TYPE))))
  ifeq ($(ARM_CPU_FEATURES),)
    PKG_RELEASE_ARCH:=arm-unknown-linux-musleabi
    PKG_HASH:=b00694ac484eaf994408c874c70e1d3392d1654cf3d9391ddf2b589bbee9106c
  else ifneq ($(filter $(ARM_CPU_FEATURES),vfp vfpv2),)
    PKG_RELEASE_ARCH:=arm-unknown-linux-musleabi
    PKG_HASH:=b00694ac484eaf994408c874c70e1d3392d1654cf3d9391ddf2b589bbee9106c
  else
    PKG_RELEASE_ARCH:=armv7-unknown-linux-musleabihf
    PKG_HASH:=99ca0a319ef19b966f054b188e9adaede948d476a98cbd2aa9fed7c8c1d37c58
  endif
else ifeq ($(ARCH),i386)
  PKG_RELEASE_ARCH:=i686-unknown-linux-musl
  PKG_HASH:=a9aabb4209a8f29afabddb2aaaa8a38d8f604fd0075250d61bd594bb10ae38c7
else ifeq ($(ARCH),loongarch64)
  PKG_RELEASE_ARCH:=loongarch64-unknown-linux-musl
  PKG_HASH:=d17e33e7d23cc009c5e04e761705660e54e92c8a97bb65b05ccaf173e1fd87eb
else ifeq ($(ARCH),riscv64)
  PKG_RELEASE_ARCH:=riscv64gc-unknown-linux-musl
  PKG_HASH:=54cd71fc9b6a48b8d5e14c21c0fccec55908d57c6bb95ef32b7d7f9a905d0ddf
else ifeq ($(ARCH),x86_64)
  PKG_RELEASE_ARCH:=x86_64-unknown-linux-musl
  PKG_HASH:=0d84f5f350ec99396867d718f146fc3810975b2a7cd06192f158d96bdef460e7
# Set the default value to make OpenWrt Package Checker happy
else
  PKG_RELEASE_ARCH:=dummy
  PKG_HASH:=dummy
endif

PKG_SOURCE:=shadowsocks-v$(PKG_VERSION).$(PKG_RELEASE_ARCH).tar.xz

PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>
PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

TAR_CMD:=$(HOST_TAR) -C $(PKG_BUILD_DIR) $(TAR_OPTIONS)

define Package/shadowsocks-rust/Default
  define Package/shadowsocks-rust-$(1)
    SECTION:=net
    CATEGORY:=Network
    SUBMENU:=Web Servers/Proxies
    TITLE:=shadowsocks-rust $(1)
    URL:=https://github.com/shadowsocks/shadowsocks-rust
    DEPENDS:=@USE_MUSL @(aarch64||arm||i386||loongarch64||riscv64||x86_64) @!(TARGET_x86_geode||TARGET_x86_legacy)
  endef

  define Package/shadowsocks-rust-$(1)/install
	$$(INSTALL_DIR) $$(1)/usr/bin
	$$(INSTALL_BIN) $$(PKG_BUILD_DIR)/$(1) $$(1)/usr/bin
  endef
endef

SHADOWSOCKS_COMPONENTS:=sslocal ssmanager ssserver ssurl ssservice
define shadowsocks-rust/templates
  $(foreach component,$(SHADOWSOCKS_COMPONENTS),
    $(call Package/shadowsocks-rust/Default,$(component))
  )
endef
$(eval $(call shadowsocks-rust/templates))

define Build/Compile
endef

$(foreach component,$(SHADOWSOCKS_COMPONENTS), \
  $(eval $(call BuildPackage,shadowsocks-rust-$(component))) \
)
