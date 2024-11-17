#
# Copyright 2022-2024 Rafał Wabik - IceG - From eko.one.pl forum
#
# Licensed to the GNU General Public License v3.0.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-sms-tool-js
LUCI_TITLE:=LuCI JS Support for sms-tool
MAINTAINER:=Rafał Wabik <4Rafal@gmail.com>
LUCI_DESCRIPTION:=LuCI JS interface for the sms-tool. The user interface supports SMS / USSD Codes / AT Commands.
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+sms-tool +kmod-usb-serial +kmod-usb-serial-option +comgt

define Package/luci-app-sms-tool-js/conffiles
/etc/config/sms_tool_js
/etc/modem/atcmmds.user
/etc/modem/phonebook.user
/etc/modem/ussdcodes.user
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
