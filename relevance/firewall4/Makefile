#
# Copyright (C) 2021 Jo-Philipp Wich <jo@mein.io>
#

include $(TOPDIR)/rules.mk

PKG_NAME:=firewall4
PKG_RELEASE:=2

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL=$(PROJECT_GIT)/project/firewall4.git
PKG_SOURCE_DATE:=2024-06-03
PKG_SOURCE_VERSION:=dfbcc1cd127c78fc61bb870d36d2512b571d223b
PKG_MIRROR_HASH:=skip
PKG_MAINTAINER:=Jo-Philipp Wich <jo@mein.io>
PKG_LICENSE:=ISC

include $(INCLUDE_DIR)/package.mk

define Package/firewall4
  SECTION:=net
  CATEGORY:=Base system
  TITLE:=OpenWrt 4th gen firewall
  DEPENDS:= \
	+kmod-nft-core +kmod-nft-fib +kmod-nft-offload \
	+kmod-nft-nat +kmod-nft-fullcone \
	+nftables-json \
	+ucode +ucode-mod-fs +ucode-mod-ubus +ucode-mod-uci \
	+iptables +ip6tables +kmod-nft-socket +kmod-nft-tproxy
  EXTRA_DEPENDS:=ucode (>=2022.03.22)
  PROVIDES:=uci-firewall
endef

define Package/firewall4/description
 This package provides an nftables-based implementation of the UCI firewall
 sharing the same configuration format.
endef

define Package/firewall4/conffiles
/etc/config/firewall
/etc/nftables.d/
/etc/firewall.user
endef

define Package/firewall4/install
	$(CP) -a $(PKG_BUILD_DIR)/root/* $(1)/
	$(INSTALL_DIR) $(1)/etc/
	$(INSTALL_CONF) ./files/firewall.include $(1)/etc/firewall.user
	$(INSTALL_CONF) ./files/firewall.exwan $(1)/etc/firewall.exwan
endef

define Build/Compile
endef

$(eval $(call BuildPackage,firewall4))
