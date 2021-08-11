# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=Flask-RESTful
PKG_VERSION:=0.3.8
PKG_RELEASE:=2

PYPI_NAME:=$(PKG_NAME)
PKG_HASH:=5ea9a5991abf2cb69b4aac19793faac6c032300505b325687d7c305ffaa76915

PKG_MAINTAINER:=[CTCGFW] Project OpenWrt
PKG_LICENSE:=GPLv3
PKG_LICENSE_FILES:=LICENSE

include ../pypi.mk
include $(INCLUDE_DIR)/package.mk
include ../python3-package.mk

define Package/python3-flask-restful
  SECTION:=lang
  CATEGORY:=Languages
  SUBMENU:=Python
  TITLE:=Simple framework for creating REST APIs
  URL:=https://github.com/flask-restful/flask-restful
  DEPENDS:=+python3-light +python3-flask
  VARIANT:=python3
endef

define Package/python3-flask-restful/description
  Flask-RESTful provides the building blocks for creating a great REST API.
endef

$(eval $(call Py3Package,python3-flask-restful))
$(eval $(call BuildPackage,python3-flask-restful))
$(eval $(call BuildPackage,python3-flask-restful-src))
