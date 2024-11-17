# Copyright (C) luochognjun@gl-inet.com
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=dynv6 ddns script
LUCI_DEPENDS:= +luci-compat

PKG_MAINTAINER:=luochongjun <luochongjun@gl-inet.com>

define Package/luci-app-dynv6/postinst
        #!/bin/sh
	uci -q get ucitrack.@dynv6[0] || uci add ucitrack dynv6
	uci set ucitrack.@dynv6[0]=dynv6
	uci set ucitrack.@dynv6[0].exec="/bin/sh /etc/rc.common /etc/init.d/dynv6 restart"
	uci commit ucitrack
	/etc/init.d/ucitrack restart

        exit 0
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/dynv6
endef


include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
