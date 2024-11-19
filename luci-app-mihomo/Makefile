include $(TOPDIR)/rules.mk


LUCI_TITLE:=LuCI Support for mihomo
LUCI_DEPENDS:=+luci-base +mihomo +ca-bundle +curl +yq firewall4 +ip-full +kmod-inet-diag +kmod-nft-tproxy +kmod-tun

define Package/luci-app-mihomo/conffiles
/etc/config/mihomo
/etc/mihomo/mixin.yaml
/etc/mihomo/nftables/reserved_ip.nft
/etc/mihomo/nftables/reserved_ip6.nft
endef

define Package/luci-app-mihomo/postrm
#!/bin/sh
if [ -z $${IPKG_INSTROOT} ]; then
	uci -q batch <<-EOF > /dev/null
		del firewall.mihomo
		commit firewall
	EOF
fi
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
