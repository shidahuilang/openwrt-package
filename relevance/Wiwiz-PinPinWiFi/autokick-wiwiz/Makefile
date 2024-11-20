include $(TOPDIR)/rules.mk

PKG_NAME:=autokick-wiwiz
PKG_VERSION:=20241103
PKG_RELEASE:=1
LUCI_DIR:=/usr/lib/lua/luci

include $(INCLUDE_DIR)/package.mk

define Package/autokick-wiwiz
  SUBMENU:=Portal
  SECTION:=net
  CATEGORY:=Wiwiz/PinPinWiFi
  DEPENDS:=
  TITLE:= Disconnects wireless user when the user is authenticated and expired via Portal
  PKGARCH:=all
endef

define Package/autokick-wiwiz/conffiles
/etc/config/autokick
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/autokick-wiwiz/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/etc/config $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_DIR) $(1)/usr/lib/lua
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi
    
	$(INSTALL_BIN) ./files/usr/bin/autokick.sh $(1)/usr/bin/autokick.sh
	$(INSTALL_CONF) ./files/etc/config/autokick $(1)/etc/config/autokick
	$(INSTALL_BIN) ./files/etc/init.d/autokick $(1)/etc/init.d/autokick  
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/controller/autokick.lua $(1)/usr/lib/lua/luci/controller/autokick.lua
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/model/cbi/autokick.lua $(1)/usr/lib/lua/luci/model/cbi/autokick.lua
endef

define Package/autokick-wiwiz/postinst
endef

define Package/autokick-wiwiz/postrm
endef

$(eval $(call BuildPackage,autokick-wiwiz))
