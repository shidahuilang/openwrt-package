include $(TOPDIR)/rules.mk

PKG_NAME:=mnh
PKG_VERSION:=0.7.3
PKG_RELEASE:=2

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/hzyitc/mnh/tar.gz/v${PKG_VERSION}?
PKG_HASH:=skip

PKG_MAINTAINER:=HZY
PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

GO_PKG:=github.com/hzyitc/mnh

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

define Package/mnh
  SECTION:=net
  CATEGORY:=Network
  TITLE:=NAT hole punching tool
  URL:=https://github.com/hzyitc/mnh
  DEPENDS:= $(GO_ARCH_DEPENDS)
endef

define Package/mnh/description
  mnh is a NAT hole punching tool that allows peers directly connect to your 
  NATed server without client. 
endef

define Package/mnh/conffiles
/etc/config/mnh
endef

define Package/mnh/install
	$(call GoPackage/Package/Install/Bin,$(PKG_INSTALL_DIR))

	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/mnh $(1)/usr/bin/mnh
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/mnh.init $(1)/etc/init.d/mnh
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/mnh.config $(1)/etc/config/mnh
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/mnh.defaults $(1)/etc/uci-defaults/99-mnh
	$(INSTALL_DIR) $(1)/usr/share/mnh/
	$(INSTALL_BIN) ./files/firewall3.include $(1)/usr/share/mnh/firewall3.include
	$(INSTALL_BIN) ./files/firewall4.include $(1)/usr/share/mnh/firewall4.include
	$(INSTALL_BIN) ./files/hook.sh $(1)/usr/share/mnh/hook.sh
endef

$(eval $(call BuildPackage,mnh))