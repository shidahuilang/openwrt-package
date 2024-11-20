include $(TOPDIR)/rules.mk
PKG_NAME:=luci-proto-tinc
PKG_VERSION:=1.0.0
PKG_RELEASE:=2
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
include $(INCLUDE_DIR)/package.mk

define Package/luci-proto-tinc
	SECTION:=net
	CATEGORY:=protocols
	TITLE:=Protocol for TincVPN
	PKGARCH:=all
	DEPENDS:=+tinc
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./files/* $(PKG_BUILD_DIR)/
endef

define Package/luci-proto-tinc/install
	$(INSTALL_DIR) $(1)/lib/netifd/proto
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/netifd/proto/tinc.sh $(1)/lib/netifd/proto
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/netifd/tinc.script $(1)/lib/netifd
	$(INSTALL_DIR) $(1)/www/luci-static/resources/protocol
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/www/luci-static/resources/protocol/tinc.js $(1)/www/luci-static/resources/protocol
endef

$(eval $(call BuildPackage,luci-proto-tinc))
