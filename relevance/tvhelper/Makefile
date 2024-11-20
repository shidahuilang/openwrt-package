include $(TOPDIR)/rules.mk

PKG_NAME:=tvhelper
PKG_VERSION:=2.0.5
PKG_RELEASE:=2

PKG_SOURCE:=tv.sh
PKG_SOURCE_URL:=https://raw.githubusercontent.com/wukongdaily/tvhelper/master/shells/
PKG_HASH:=skip

include $(INCLUDE_DIR)/package.mk

define Package/tvhelper
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=TV Helper
  DEPENDS:=+bash
endef

define Package/tvhelper/description
  tv.sh script from @wukongdaily.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) $(DL_DIR)/$(PKG_SOURCE) $(PKG_BUILD_DIR)/
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/tvhelper/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/tv.sh $(1)/usr/bin/tv.sh
	$(INSTALL_DIR) $(1)/root
	ln -sf /usr/bin/tv.sh $(1)/root/tv.sh
endef

$(eval $(call BuildPackage,tvhelper))
