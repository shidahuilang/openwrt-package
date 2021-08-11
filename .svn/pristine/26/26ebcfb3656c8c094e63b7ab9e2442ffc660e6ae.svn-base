#
# Copyright (C) 2019 CZ.NIC, z. s. p. o. (https://www.nic.cz/)
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=homeassistant
PKG_VERSION:=2021.5.5
PKG_RELEASE:=1

PYPI_NAME:=$(PKG_NAME)
PKG_HASH:=135bc9ebef7c7c6b7371306a91389b6a8acdecbf9bba6044dca2fa071abb4a62

PKG_MAINTAINER:=Josef Schlehofer <pepe.schlehofer@gmail.com>
PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE.md
PKG_CPE_ID:=cpe:/a:home-assistant:home-assistant

include ../pypi.mk
include $(INCLUDE_DIR)/package.mk
include ../python3-package.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Home Assistant
  URL:=https://www.home-assistant.io/
  DEPENDS:= \
    +python3-aiohttp \
    +python3-aiohttp-cors \
    +python3-astral \
    +python3-async-timeout \
    +python3-attrs \
    +python3-bcrypt \
    +python3-certifi \
    +python3-cryptography \
    +python3-ifaddr \
    +python3-importlib-metadata \
    +python3-jinja2 \
    +python3-netdisco \
    +python3-pip \
    +python3-pyjwt \
    +python3-pyotp \
    +python3-pytz \
    +python3-slugify \
    +python3-sqlalchemy \
    +python3-requests \
    +python3-ruamel-yaml \
    +python3-voluptuous \
    +python3-voluptuous-serialize \
    +python3-yaml \
    +python3-zeroconf
endef

define Package/$(PKG_NAME)/description
  Home Assistant is a home automation platform running on Python 3.
  It is able to track and control all devices at home and offer a platform for automating control.

  It requires a minimum of 1 GB of RAM.
endef

define Py3Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(CP) $(PKG_INSTALL_DIR)/usr/bin/* $(1)/usr/bin/

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/hass.init $(1)/etc/init.d/hass
endef

$(eval $(call Py3Package,$(PKG_NAME)))
$(eval $(call BuildPackage,$(PKG_NAME)))
$(eval $(call BuildPackage,$(PKG_NAME)-src))
