include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-cqustdotnet
PKG_VERSION:=1.1.10
PKG_RELEASE:=2
PKG_MAINTAINER:=Hurring <https://github.com/ApeaSuperZ/luci-app-cqustdotnet>

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)/config
endef

define Package/$(PKG_NAME)
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=A LuCI app to simply connect to network of CQUST
	PKGARCH:=all
	DEPENDS:=+bash +curl +lua +libuci-lua
	MAINTAINER:=Hurring
endef

define Package/$(PKG_NAME)/description
	A LuCI app to simply connect to network of CQUST
endef

define Build/Prepare
	$(CP) $(CURDIR)/root $(PKG_BUILD_DIR)
	$(CP) $(CURDIR)/luasrc $(PKG_BUILD_DIR)
	chmod 0755 $(PKG_BUILD_DIR)/root/etc/init.d/cqustdotnet
	chmod -R 0755 $(PKG_BUILD_DIR)/root/usr/share/cqustdotnet/
	mkdir -p $(PKG_BUILD_DIR)/root/etc/openclash/config
	exit 0
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/conffiles
	/etc/config/cqustdotnet
endef

define Package/$(PKG_NAME)/preinst
endef

define Package/$(PKG_NAME)/postinst
endef

define Package/$(PKG_NAME)/prerm
	uci -q set cqustdotnet.config.enabled=0
	uci -q commit cqustdotnet
	exit 0
endef

define Package/$(PKG_NAME)/postrm
endef

define Package/$(PKG_NAME)/install
	$(CP) $(PKG_BUILD_DIR)/root/* $(1)/
	[ -d $(1)/usr/lib/lua/luci ] || mkdir -p $(1)/usr/lib/lua/luci
	$(CP) $(PKG_BUILD_DIR)/luasrc/* $(1)/usr/lib/lua/luci/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
