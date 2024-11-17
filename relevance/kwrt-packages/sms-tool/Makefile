include $(TOPDIR)/rules.mk

PKG_NAME:=sms-tool
PKG_RELEASE:=3

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/obsy/sms_tool.git
PKG_SOURCE_DATE:=2024-07-25
PKG_SOURCE_VERSION:=fce2b931c8d749c28b8281363950e963c98324eb
PKG_MIRROR_HASH:=skip

include $(INCLUDE_DIR)/package.mk

define Package/sms-tool
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=sms tool
  URL:=https://github.com/obsy/sms_tool
endef

define Package/sms-tool/description
	SMS Tool for 3G/4G/5G modem
endef

define Package/sms-tool/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/sms_tool $(1)/usr/bin/
endef

$(eval $(call BuildPackage,sms-tool))
