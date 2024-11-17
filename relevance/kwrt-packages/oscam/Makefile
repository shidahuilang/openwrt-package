include $(TOPDIR)/rules.mk

PKG_NAME:=oscam
PKG_RELEASE:=2

PKG_SOURCE_URL:=https://git.streamboard.tv/common/oscam
PKG_SOURCE_PROTO:=git
PKG_SOURCE_DATE:=2024-05-10
PKG_SOURCE_VERSION:=6d9801f2c605d7656d7e6b6fde5c8210b28e9d2d
#PKG_MIRROR_HASH:=ea17426c945c29c1361f9e69ae1d980d8bd51a008876111ffb8f55146477bdba
PKG_MIRROR_HASH:=skip

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/oscam
  SECTION:=utils
  CATEGORY:=Utilities
  DEPENDS:=+libopenssl +libusb-1.0 +libpcsclite +librt +libpthread +libdvbcsa
  TITLE:=OSCam is an Open Source Conditional Access Module software
endef

define Package/oscam/description
  OSCam is an Open Source Conditional Access Module software
endef

CMAKE_OPTIONS += \
	-DCS_CONFDIR=/etc/oscam \
	-DUSE_LIBUSB=1 \
	-DUSE_LIBCRYPT=1 \
	-DUSE_PCSC=1 \
	-DHAVE_LIBDVBCSA=1

define Package/oscam/conffiles
/etc/oscam/oscam.user
/etc/oscam/oscam.conf
/etc/oscam/oscam.server
endef

define Build/Configure
	(cd $(PKG_BUILD_DIR); echo $(PKG_VERSION) > version.txt; ./config.sh --enable all --disable IPV6SUPPORT)
	$(call Build/Configure/Default)
endef

define Package/oscam/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/oscam.init $(1)/etc/init.d/oscam

	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/oscam $(1)/usr/bin/

	$(INSTALL_DIR) $(1)/etc/oscam
	$(CP) ./files/oscam.server $(1)/etc/oscam/oscam.server
	$(CP) ./files/oscam.conf $(1)/etc/oscam/oscam.conf
	$(CP) ./files/oscam.user $(1)/etc/oscam/oscam.user
endef

$(eval $(call BuildPackage,oscam))
