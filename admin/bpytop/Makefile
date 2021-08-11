#
# Copyright (C) 2021 ImmortalWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=bpytop
PKG_VERSION:=1.0.67
PKG_RELEASE:=$(AUTORELEASE)

PYPI_NAME:=bpytop
PKG_HASH:=8b338e3627fa6e991e836bee61ef38988f6a7a3a37dc05c757a92ba4378f95bb

PKG_LICENSE:=Apache-2.0
PKG_LICENSE_FILES:=LICENSE

include ../../lang/python/pypi.mk
include $(INCLUDE_DIR)/package.mk
include ../../lang/python/python3-package.mk

define Package/bpytop
  SECTION:=admin
  CATEGORY:=Administration
  TITLE:=Python port of bashtop
  URL:=https://github.com/aristocratos/bpytop
  DEPENDS:=+python3-psutil +python3-setuptools
endef

define Package/bpytop/description
  Resource monitor that shows usage and stats for
  processor, memory, disks, network and processes.
endef

define Package/bpytop/install
	$(call Py3Package/$(PKG_NAME)/install,$(1))
	$(call Py3Package/ProcessFilespec,$(PKG_NAME),$(PKG_INSTALL_DIR),$(1))
	$(call Python3/CompileAll,$(1))
	$(call Python3/DeleteSourceFiles,$(1))
	$(call Python3/DeleteEmptyDirs,$(1))
	$(call Python3/FixShebang,$(1)/usr/bin/*)

	$(INSTALL_DIR) $(1)/usr/share
	$(CP) $(PKG_BUILD_DIR)/themes $(1)/usr/share/bpytop
endef

$(eval $(call Py3Package,bpytop))
$(eval $(call BuildPackage,bpytop))
#$(eval $(call BuildPackage,bpytop-src))
