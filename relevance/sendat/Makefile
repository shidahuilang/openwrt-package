
include $(TOPDIR)/rules.mk
 
PKG_NAME:=sendat
PKG_RELEASE:=2

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ouyangzq/sendat.git
PKG_SOURCE_DATE:=2023-10-26
PKG_SOURCE_VERSION:=624c58f6331e5be3eac6d144ed985b4a4af94b10
PKG_MIRROR_HASH:=skip

include $(INCLUDE_DIR)/package.mk
 
define Package/sendat
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU :=CPE
  TITLE:=Sendat AT
  DEPENDS:=+libpthread
endef
 
define Package/sendat/description
  AT Commnad for sendat test
endef

MAKE_PATH:=src

define Package/sendat/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/sendat $(1)/usr/bin/
endef

$(eval $(call BuildPackage,sendat))
