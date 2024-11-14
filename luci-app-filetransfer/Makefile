include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-filetransfer
PKG_VERSION=1.0
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-filetransfer
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=file transfer tool
	PKGARCH:=all
endef

define Package/luci-app-filetransfer/description
	This package contains LuCI configuration pages for file transfer.
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/luci-app-filetransfer/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/cbi
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	
	$(INSTALL_DATA) ./luasrc/model/cbi/updownload.lua $(1)/usr/lib/lua/luci/model/cbi/updownload.lua
	$(INSTALL_DATA) ./luasrc/controller/filetransfer.lua $(1)/usr/lib/lua/luci/controller/filetransfer.lua
	$(INSTALL_DATA) ./luasrc/view/cbi/* $(1)/usr/lib/lua/luci/view/cbi/
endef

$(eval $(call BuildPackage,luci-app-filetransfer))
