#
# Copyright (C) 2017 Steven Hessing
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=libyaml-cpp
PKG_VERSION:=0.6.3
PKG_RELEASE:=2

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/jbeder/yaml-cpp.git
PKG_SOURCE_DATE:=2021-01-05
PKG_SOURCE_VERSION:=a6bbe0e50ac4074f0b9b44188c28cf00caf1a723
PKG_MIRROR_HASH:=417066769c56737c0eecad039a64919006ae62a136fc5c8083f51fc483615e52

PKG_MAINTAINER:= Steven Hessing <steven.hessing@gmail.com>
PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE
PKG_CPE_ID:=cpe:/a:yaml-cpp_project:yaml-cpp

CMAKE_INSTALL:=1
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/libyaml-cpp
  SECTION:=development
  CATEGORY:=Libraries
  TITLE:=libyaml-cpp
  URL:=https://github.com/jbeder/yaml-cpp
  DEPENDS:=+libstdcpp
  ABI_VERSION:=0.6
endef

define Package/libyaml-cpp/description
  yaml-cpp is a YAML parser and emitter in C++ matching the YAML 1.2 spec.
endef

CMAKE_OPTIONS += \
	-DYAML_BUILD_SHARED_LIBS=ON \
	-DYAML_CPP_BUILD_TESTS=OFF \
	-DYAML_CPP_BUILD_TOOLS=OFF

define Package/libyaml-cpp/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_DATA) $(PKG_INSTALL_DIR)/usr/lib/libyaml-cpp.so.$(ABI_VERSION) $(1)/usr/lib/
endef

$(eval $(call BuildPackage,libyaml-cpp))
