include $(TOPDIR)/rules.mk

PKG_NAME:=ifmetric
PKG_VERSION:=0.3.0
PKG_RELEASE:=2

PKG_MAINTAINER:=Konstantine Shevlakov <shevlakov@132lan.ru>
PKG_LICENSE:=LICENSE
PKG_LICENSE_FILES:=COPYING

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/mshuler/ifmetric.git
PKG_SOURCE_VERSION:=5c779caf7665f53995b26104124af17f6e49e552

PKG_SOURCE_SUBDIR:=$(PKG_NAME)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_SOURCE_SUBDIR)

PKG_INSTALL:=1
PKG_BUILD_PARALLEL:=1

PKG_FIXUP:=autoreconf

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Tool for setting the metrics of all IPv4 routes
  URL:=http://0pointer.de/lennart/projects/ifmetric/
endef

define Package/$(PKG_NAME)/description
	ifmetric is a Linux tool for setting the metrics of all IPv4 routes
	attached to a given network interface at once. This may be used to
	change the priority of routing IPv4 traffic over the interface. Lower
	metrics correlate with higher priorities. and min/max network usage.
endef

CONFIGURE_ARGS+= \
	--disable-lynx

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/$(PKG_NAME) $(1)/usr/bin/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))