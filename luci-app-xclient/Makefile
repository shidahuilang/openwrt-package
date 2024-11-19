include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-xclient
PKG_VERSION:=v2.1
PKG_RELEASE:=2
PKG_MAINTAINER:=xcode75
	
include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=2. XClient
	TITLE:=LuCI Support for Xray
	PKGARCH:=all
	MAINTAINER:=xcode75
	DEPENDS:=+coreutils +coreutils-base64 +pdnsd-alt +coreutils-nohup +curl +dnsmasq-full +luci-compat +dns2socks +ipset +ip-full +iptables-mod-tproxy +libuci-lua +lua +luci-lib-jsonc +microsocks +tcping +resolveip +shadowsocks-libev-ss-local +shadowsocks-libev-ss-redir +unzip +uclient-fetch +wget-ssl +libmbedtls
endef

define Package/$(PKG_NAME)/config
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/xclient
endef


define Package/$(PKG_NAME)/prerm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
    echo "Removing rc.d symlink for xclient"
     /etc/init.d/xclient disable
     /etc/init.d/xclient stop
    echo "Removing firewall rule for xclient"
	  uci -q batch <<-EOF >/dev/null
		delete firewall.xclient
		commit firewall
	chmod -R 777 /usr/share/xclient 2>/dev/null	
EOF
fi

exit 0
endef


define Package/$(PKG_NAME)/preinst
#!/bin/sh

if [ -z "$${IPKG_INSTROOT}" ]; then
	rm -rf /tmp/dnsmasq.xclient 2>/dev/null
	mv /etc/config/xclient /etc/config/xclient.bak 2>/dev/null
	rm -rf /usr/lib/lua/luci/model/cbi/xclient 2>/dev/null
	rm -rf /usr/lib/lua/luci/view/xclient 2>/dev/null
	chmod -R 777 /usr/share/xclient 2>/dev/null
fi

exit 0
endef


define Package/$(PKG_NAME)/postinst
#!/bin/sh

if [ -z "$${IPKG_INSTROOT}" ]; then
	rm -rf /tmp/luci*
	mv /etc/config/xclient.bak /etc/config/xclient 2>/dev/null
	/etc/init.d/xclient disable 2>/dev/null
	chmod +x /etc/init.d/xclient 2>/dev/null
	/etc/init.d/xclient disable 2>/dev/null
	/etc/init.d/xclient stop 2>/dev/null
	chmod -R 777 /usr/share/xclient 2>/dev/null
fi

exit 0
endef


define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/xclient
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/xclient
	
	$(INSTALL_DATA) ./luasrc/controller/* $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./luasrc/model/cbi/xclient/* $(1)/usr/lib/lua/luci/model/cbi/xclient
	$(INSTALL_DATA) ./luasrc/view/xclient/* $(1)/usr/lib/lua/luci/view/xclient
	
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	

	$(INSTALL_BIN) 	./root/etc/init.d/* $(1)/etc/init.d
	$(INSTALL_CONF) ./root/etc/config/* $(1)/etc/config
	$(INSTALL_CONF) ./root/etc/uci-defaults/* $(1)/etc/uci-defaults
	
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/usr/share/xclient
	
	$(INSTALL_DATA) ./root/usr/bin/* $(1)/usr/bin
	$(INSTALL_DATA) ./root/usr/share/xclient/* $(1)/usr/share/xclient
	
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./root/usr/share/rpcd/acl.d/luci-app-xclient.json $(1)/usr/share/rpcd/acl.d/luci-app-xclient.json
	
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) ./root/usr/share/luci/menu.d/luci-app-xclient.json $(1)/usr/share/luci/menu.d/luci-app-xclient.json
	
	$(INSTALL_DIR) $(1)/www
	$(INSTALL_DIR) $(1)/www/luci-static
	$(INSTALL_DIR) $(1)/www/luci-static/xclient
	$(INSTALL_DIR) $(1)/www/luci-static/xclient/img
	cp -pR ./root/www/luci-static/xclient/img/*.png $(1)/www/luci-static/xclient/img
	cp -pR ./root/www/luci-static/xclient/img/*.svg $(1)/www/luci-static/xclient/img
	
endef

$(eval $(call BuildPackage,$(PKG_NAME)))	
