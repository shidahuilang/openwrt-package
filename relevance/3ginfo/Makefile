include $(TOPDIR)/rules.mk

PKG_NAME:=3ginfo-text
PKG_VERSION:=20190418

include $(INCLUDE_DIR)/package.mk

define Package/3ginfo-text/Default
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Information about status of 3G/4G modem
	MAINTAINER:=3ginfo
	PKGARCH:=all
endef

define Package/3ginfo-text
$(call Package/3ginfo-text/Default)
	TITLE+= (text version)
	DEPENDS:=+comgt
endef

define Package/3ginfo-text/conffiles
/etc/config/3ginfo
endef

define Build/Compile
endef

define Package/3ginfo-text/install
	$(CP) ./files-text/* $(1)
endef

define Package/3ginfo-text/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	chmod +x /usr/share/3ginfo/cgi-bin/3ginfo.sh
	ln -sf /usr/share/3ginfo/cgi-bin/3ginfo.sh /usr/bin/3ginfo
}
exit 0
endef

$(eval $(call BuildPackage,3ginfo-text))
