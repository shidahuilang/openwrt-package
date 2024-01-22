#
# Copyright (C) 2014-2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=dns-proxy
PKG_VERSION:=0.1
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.xz
PKG_SOURCE_PROTO:=git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_URL:=https://github.com/wzhd/dns-tcp-socks-proxy.git
PKG_SOURCE_VERSION:=null

PKG_MAINTAINER:=qiuchengxuan <qiuchengxuan@gmail.com>
PKG_LICENSE:=Apache-2.0

include $(INCLUDE_DIR)/package.mk

define Package/dns-proxy
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=
  TITLE:=A simple dns proxy to tunnel DNS requests over a socks proxy
endef

define Package/dns-proxy/conffiles
/etc/dns-proxy.conf
endef

define Package/dns-proxy/description
A simple dns proxy to tunnel DNS requests over a socks proxy (for example, over ssh or Tor). This can come in handy when setting up transparent proxies.
It chooses a random DNS server for each request from the file "resolv.conf" which is a newline delimited list of DNS servers.
The daemon must be run as root in order for it to bind to port 53.
endef

define Package/dns-proxy/install
	$(INSTALL_DIR) $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/dns_proxy $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/etc/init.d/
	$(INSTALL_BIN) files/dns_proxy.init $(1)/etc/init.d/dns_proxy
	$(INSTALL_CONF) files/dns_proxy.conf $(1)/etc/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/resolv.conf $(1)/etc/dns_proxy_resolv.conf
endef

$(eval $(call BuildPackage,dns-proxy))
