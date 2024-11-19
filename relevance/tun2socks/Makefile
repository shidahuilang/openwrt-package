include $(TOPDIR)/rules.mk

PKG_NAME:=tun2socks
PKG_VERSION:=2.5.2
PKG_RELEASE:=11

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/xjasonlyu/tun2socks.git
PKG_SOURCE_VERSION:=e5009398d5e5c40bba2b1c12d856d77e7172c8bb

PKG_MAINTAINER:=Konstantine Shevlakov <shevlako@132lan.ru>
PKG_LICENSE:=GPL-3.0
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16

GO_PKG=github.com/xjasonlyu/tun2socks

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

GO_MOD_ARGS:=
GO_PKG_BUILD_VARS+= GO111MODULE=on

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  TITLE:=tun to socks proxy redirector written on golang
  URL:=https://github.com/xjasonlyu/tun2socks
  DEPENDS:=$(GO_ARCH_DEPENDS) +ca-bundle \
	   +kmod-tun +ip-full +coreutils-base64
endef

define Package/$(PKG_NAME)/install
	$(call GoPackage/Package/Install/Bin,$(PKG_INSTALL_DIR))
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/$(PKG_NAME) $(1)/usr/sbin/
	$(CP) ./root/* $(1)/
endef

$(eval $(call GoBinPackage,$(PKG_NAME)))
$(eval $(call BuildPackage,$(PKG_NAME)))
