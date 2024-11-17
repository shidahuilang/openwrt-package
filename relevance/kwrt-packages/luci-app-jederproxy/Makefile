include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-jederproxy
PKG_VERSION:=1.0.0
PKG_RELEASE:=2

PKG_LICENSE:=MPLv2
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=ttimasdf <opensource@rabit.pw>
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=Custom
	CATEGORY:=Extra packages
	TITLE:=LuCI Support for jeder(every) proxies
	DEPENDS:=+luci-base +dnsmasq +ca-bundle +PACKAGE_firewall4:kmod-nft-tproxy +PACKAGE_firewall4:ucode-mod-resolv +PACKAGE_firewall:ipset +PACKAGE_firewall:iptables +PACKAGE_firewall:iptables-mod-conntrack-extra +PACKAGE_firewall:iptables-mod-extra +PACKAGE_firewall:iptables-mod-tproxy
	PKGARCH:=all
	USERID:=jederproxy=346:jederproxy=346
endef

define Package/$(PKG_NAME)/description
	LuCI interface for multiple proxy backends, supporting clash/clash meta, xray/v2ray, shadowsocks (ss-redir).
endef

define Package/$(PKG_NAME)/config
menu "luci-app-jederproxy Configuration"
	depends on PACKAGE_$(PKG_NAME)

endmenu
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/jederproxy
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/init.d/
	$(INSTALL_BIN) $(CURDIR)/root/etc/init.d/jederproxy $(1)/etc/init.d/jederproxy
	$(INSTALL_DIR) $(1)/etc/config/
	$(INSTALL_DATA) $(CURDIR)/root/etc/config/jederproxy $(1)/etc/config/jederproxy

	$(INSTALL_DIR) $(1)/etc/luci-uploads/jederproxy/

	$(INSTALL_DIR) $(1)/www/luci-static/resources/view
	$(INSTALL_DATA) ./root/www/luci-static/resources/view/jederproxy.js $(1)/www/luci-static/resources/view/jederproxy.js

	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/
	$(INSTALL_DATA) $(CURDIR)/root/www/luci-static/resources/view/jederproxy.js $(1)/www/luci-static/resources/view/jederproxy.js
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d/
	$(INSTALL_DATA) $(CURDIR)/root/usr/share/luci/menu.d/luci-app-jederproxy.json $(1)/usr/share/luci/menu.d/luci-app-jederproxy.json

	$(INSTALL_DIR) $(1)/usr/libexec/jederproxy/
	$(INSTALL_BIN) $(CURDIR)/root/usr/libexec/jederproxy/jederproxy_jail $(1)/usr/libexec/jederproxy/jederproxy_jail
	$(INSTALL_DIR) $(1)/usr/libexec/rpcd/
	$(INSTALL_BIN) $(CURDIR)/root/usr/libexec/rpcd/jederproxy $(1)/usr/libexec/rpcd/jederproxy
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d/
	$(INSTALL_DATA) $(CURDIR)/root/usr/share/rpcd/acl.d/luci-app-jederproxy.json $(1)/usr/share/rpcd/acl.d/luci-app-jederproxy.json

	$(INSTALL_DIR) $(1)/usr/share/jederproxy/
	$(INSTALL_DIR) $(1)/lib/functions/

ifdef CONFIG_PACKAGE_firewall
	$(INSTALL_BIN) $(CURDIR)/root/usr/share/jederproxy/gen_ipset_rules.lua $(1)/usr/share/jederproxy/gen_ipset_rules.lua
	$(INSTALL_BIN) $(CURDIR)/root/usr/share/jederproxy/gen_ipset_rules_extra_normal.lua $(1)/usr/share/jederproxy/gen_ipset_rules_extra.lua
	$(INSTALL_BIN) $(CURDIR)/root/usr/share/jederproxy/firewall_include.lua $(1)/usr/share/jederproxy/firewall_include.lua
	$(INSTALL_BIN) $(CURDIR)/root/usr/share/jederproxy/gen_config.lua $(1)/usr/share/jederproxy/gen_config.lua
	$(INSTALL_BIN) $(CURDIR)/root/lib/functions/jederproxy.fw3.sh $(1)/lib/functions/jederproxy.sh
endif

ifdef CONFIG_PACKAGE_firewall4
	$(INSTALL_DIR) $(1)/etc/nftables.d/
	$(INSTALL_DATA) $(CURDIR)/root/etc/nftables.d/99-jederproxy.nft $(1)/etc/nftables.d/99-jederproxy.nft
	$(INSTALL_BIN) $(CURDIR)/root/usr/share/jederproxy/firewall_include.ut $(1)/usr/share/jederproxy/firewall_include.ut
	$(INSTALL_BIN) $(CURDIR)/root/usr/share/jederproxy/gen_config.uc $(1)/usr/share/jederproxy/gen_config.uc
	$(INSTALL_BIN) $(CURDIR)/root/lib/functions/jederproxy.fw4.sh $(1)/lib/functions/jederproxy.sh
endif

endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh

enable_feature_flag() {
	flag="$$1"
	file="$$2"
	sed -i -e "/%FLAG_NO_$${flag}%/d" -e "s@// *%FLAG_$${flag}% *@@" "$$file"
	echo "Feature [$${flag}] enabled"
}

if [ -z "$${PKG_INSTROOT}" ]; then
	sed -i -e '/%FLAG_DELETE%/d' /www/luci-static/resources/view/jederproxy.js
	if [ -f "/usr/share/jederproxy/gen_config.lua" ]; then
		enable_feature_flag FW3 /www/luci-static/resources/view/jederproxy.js
	fi
	if [ -f "/usr/share/jederproxy/gen_config.uc" ]; then
		enable_feature_flag FW4 /www/luci-static/resources/view/jederproxy.js
	fi
fi

exit 0
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
