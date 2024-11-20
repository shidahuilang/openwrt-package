include $(TOPDIR)/rules.mk

PKG_NAME:=cpulimit-ng
PKG_VERSION:=1.2
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/gangbanlau/cpulimit-ng.git
PKG_SOURCE_VERSION:=4a02951a4056caf943b5df630c530ded3185b277
PKG_MIRROR_HASH:=80ec7dfb881174e300284476a3e091fb58af494aaa79c9f29cf2322af4c31190

PKG_BUILD_PARALLEL:=1

MAKE_PATH:=src

include $(INCLUDE_DIR)/package.mk

define Package/cpulimit-ng
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=CPU Usage Limiter for Linux
  URL:=https://code.google.com/p/cpulimit-ng
endef

define Pacakge/cpulimit-ng/description
  cpulimit-ng is a simple program which attempts to limit the cpu
  usage of a process (expressed in percentage, not in cpu time).
endef

define Package/cpulimit-ng/install
	$(INSTALL_DIR) $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/cpulimit-ng $(1)/usr/bin/
endef

$(eval $(call BuildPackage,cpulimit-ng))
