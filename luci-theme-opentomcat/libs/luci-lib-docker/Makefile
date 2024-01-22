include $(TOPDIR)/rules.mk

PKG_NAME:=luci-lib-docker
PKG_VERSION:=0.3.4
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/lisaac/luci-lib-docker/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=00690867c7b071fbf7c2ca62f60b398ab8f8fdf8363a3c50124ce93e4112b6a3

PKG_LICENSE:=AGPL-3.0
PKG_MAINTAINER:=lisaac <lisaac.cn@gmail.com>

include $(INCLUDE_DIR)/package.mk

define Package/luci-lib-docker
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=6. Libraries
  TITLE:=Docker Engine API for LuCI
  URL:=https://github.com/lisaac/luci-lib-docker
  DEPENDS:=@(aarch64||arm||x86_64) @HAS_FPU +luci-lib-jsonc
  PKGARCH:=all
endef

define Build/Compile
	true
endef

define Package/luci-lib-docker/postinst
#!/bin/sh
rm -fr /tmp/luci-indexcache /tmp/luci-modulecache
endef

define Package/luci-lib-docker/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	$(CP) $(PKG_BUILD_DIR)/collections/luci-lib-docker/luasrc/* $(1)/usr/lib/lua/luci/
endef

$(eval $(call BuildPackage,luci-lib-docker))
