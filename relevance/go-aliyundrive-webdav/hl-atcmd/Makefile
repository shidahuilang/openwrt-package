include $(TOPDIR)/rules.mk

PKG_NAME:=hl-atcmd
PKG_VERSION=1

PKG_MAINTAINER:=Konstantine Shevlakov <shevlakov@132lan.ru>
PKG_LICENSE:=GPLv2
PKG_LICENSE_FILES:=LICENSE

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/nhonchu/HL-ATcmd.git
PKG_SOURCE_VERSION:=7bbd452be2dee32056d49c666fc00a4051840b89

PKG_SOURCE_SUBDIR:=$(PKG_NAME)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_SOURCE_SUBDIR)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Telephony
	TITLE:=Simple tool a send AT command
	URL:=https://github.com/nhonchu
	MAINTAINER:=Nhon Chu <nhon.chu@gmail.com>
endef

define Package/$(PKG_NAME)/description
	This simple command line tool for sending AT command to a serial device.
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/$(PKG_NAME) $(1)/usr/bin/$(PKG_NAME)
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
