include $(TOPDIR)/rules.mk

PKG_NAME:=msd
PKG_VERSION:=3.2.0
PKG_RELEASE:=2

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/rozhuk-im/msd.git
PKG_SOURCE_DATE:=2024-04-29
PKG_SOURCE_VERSION:=8b2664a982b3af48cd553ce27710dbe1a033c38c

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

CMAKE_OPTIONS+= -DCONFDIR=bin

define Package/msd
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Program for organizing IPTV streaming on the network via HTTP
  URL:=http://www.netlab.linkpc.net/wiki/software:msd:index
endef

define Package/msd/description
 Multi Stream daemon (msd) - is a program for organizing streaming IPTV on the network via HTTP.
 One server can serve thousands of clients simultaneously.
 The focus is on maximum performance, as well as a variety of subtle adjustments related to the perceptual quality of customer service: speed channel switching, fault tolerance transfer.
 Implemented proxying one to many: the data received via the one HTTP connection to be given away to the set of connected clients.
endef

define Package/msd/conffiles
/etc/config/msd
endef

define Package/msd/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/msd $(1)/usr/bin/

	$(INSTALL_DIR) $(1)/etc/msd
	$(INSTALL_DATA) $(CURDIR)/files/msd.bin.conf.sample $(1)/etc/msd/msd.conf.sample

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) $(CURDIR)/files/msd.conf $(1)/etc/config/msd

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(CURDIR)/files/msd.init $(1)/etc/init.d/msd
endef

$(eval $(call BuildPackage,msd))
