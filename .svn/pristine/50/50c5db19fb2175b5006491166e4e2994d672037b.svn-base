# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=RPi.GPIO
PKG_VERSION:=0.7.0
PKG_RELEASE:=1

PYPI_NAME:=RPi.GPIO
PKG_HASH:=7424bc6c205466764f30f666c18187a0824077daf20b295c42f08aea2cb87d3f

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENCE.txt
PKG_MAINTAINER:=Hirokazu MORIKAWA <morikw2@gmail.com>

include ../pypi.mk
include $(INCLUDE_DIR)/package.mk
include ../python3-package.mk

PYTHON3_PKG_SETUP_ARGS:=

define Package/python3-RPi.GPIO
  SECTION:=lang
  CATEGORY:=Languages
  SUBMENU:=Python
  URL:=https://sourceforge.net/projects/raspberry-gpio-python/
  TITLE:=python3-RPi.GPIO
  DEPENDS:=+python3-light
endef

define Package/python3-RPi.GPIO/description
 A module to control Raspberry Pi GPIO channels
.
(Variant for Python3)
endef

$(eval $(call Py3Package,python3-RPi.GPIO))
$(eval $(call BuildPackage,python3-RPi.GPIO))
#$(eval $(call BuildPackage,python3-RPi.GPIO-src))
