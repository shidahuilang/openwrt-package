# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NPM_NAME:=aws-crt
PKG_NAME:=node-$(PKG_NPM_NAME)
PKG_VERSION:=1.5.2
PKG_RELEASE:=2

PKG_SOURCE:=$(PKG_NPM_NAME)-$(PKG_VERSION).tgz
PKG_SOURCE_URL:=https://mirrors.tencent.com/npm/$(PKG_NPM_NAME)/-/ \
                https://registry.npm.taobao.org/$(PKG_NPM_NAME)/-/ \
                https://registry.npmjs.org/$(PKG_NPM_NAME)/-/
PKG_HASH:=d8eeb11dc1d223c67b74b23af9d3e13cb3252ed3972a65d5b505655a4afa3529

PKG_MAINTAINER:=Hirokazu MORIKAWA <morikw2@gmail.com>
PKG_LICENSE:=Apache-2.0
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_DEPENDS:=node/host
PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/node-aws-crt
  SUBMENU:=Node.js
  SECTION:=lang
  CATEGORY:=Languages
  TITLE:=NodeJS bindings for the AWS Common Runtime
  URL:=https://www.npmjs.com/package/aws-crt
  DEPENDS:=+node @(i386||x86_64||aarch64||arm)
endef

define Package/node-aws-crt/description
 NodeJS/Browser bindings for the AWS Common Runtime
endef

TAR_OPTIONS+= --strip-components 1
TAR_CMD=$(HOST_TAR) -C $(1) $(TAR_OPTIONS)

NODEJS_CPU:=$(subst powerpc,ppc,$(subst aarch64,arm64,$(subst x86_64,x64,$(subst i386,ia32,$(ARCH)))))
TMPNPM:=$(shell mktemp -u XXXXXXXXXX)

TARGET_CFLAGS+=$(FPIC) -D_GNU_SOURCE $(if $(CONFIG_USE_MUSL),-Dpthread_attr_setaffinity_np=pthread_setaffinity_np)
TARGET_CPPFLAGS+=$(FPIC)

CMINC_PATH_LIST=$(STAGING_DIR)/usr/include
ifeq ($(CONFIG_USE_MUSL),y)
    CMINC_PATH_LIST+=$(TOOLCHAIN_DIR)/include/fortify
endif
CMINC_PATH_LIST+=$(TOOLCHAIN_DIR)/include
CMINC_PATH:=$(subst $(space),:,$(CMINC_PATH_LIST))

define Build/Compile
	rm -rf $(PKG_BUILD_DIR)/dist
	rm -rf $(PKG_BUILD_DIR)/dist.browser
	cd $(PKG_BUILD_DIR); \
	$(MAKE_VARS) \
	$(MAKE_FLAGS) \
	npm_config_nodedir=$(STAGING_DIR)/usr/ \
	npm_config_cache=$(TMP_DIR)/npm-cache-$(TMPNPM) \
	npm_config_tmp=$(TMP_DIR)/npm-tmp-$(TMPNPM) \
	CMAKE_INCLUDE_PATH="$(CMINC_PATH)" \
	CMAKE_LIBRARY_PATH="$(STAGING_DIR)/usr/lib:$(TOOLCHAIN_DIR)/lib" \
	npm install --production --global-style --no-save --omit=dev --no-package-lock --ignore-scripts --legacy-peer-deps
	cd $(PKG_BUILD_DIR); \
	$(MAKE_VARS) \
	$(MAKE_FLAGS) \
	npm_config_nodedir=$(STAGING_DIR)/usr/ \
	npm_config_cache=$(TMP_DIR)/npm-cache-$(TMPNPM) \
	npm_config_tmp=$(TMP_DIR)/npm-tmp-$(TMPNPM) \
	CMAKE_INCLUDE_PATH="$(CMINC_PATH)" \
	CMAKE_LIBRARY_PATH="$(STAGING_DIR)/usr/lib:$(TOOLCHAIN_DIR)/lib" \
	npm run install --production --global-style --no-save --omit=dev --no-package-lock --legacy-peer-deps --build-from-source --target_arch=$(NODEJS_CPU)
	rm -rf $(TMP_DIR)/npm-tmp-$(TMPNPM)
	rm -rf $(TMP_DIR)/npm-cache-$(TMPNPM)
	rm -f $(PKG_BUILD_DIR)/node_modules/.package-lock.json
	find $(PKG_BUILD_DIR)/node_modules -type d -empty -print0 | xargs -0 rmdir || true
endef

define Package/node-aws-crt/install
	$(INSTALL_DIR) $(1)/usr/lib/node/$(PKG_NPM_NAME)
	$(CP) $(PKG_BUILD_DIR)/{package.json,*.md} \
		$(1)/usr/lib/node/$(PKG_NPM_NAME)/
	$(CP) $(PKG_BUILD_DIR)/{LICENSE,NOTICE} \
		$(1)/usr/lib/node/$(PKG_NPM_NAME)/
	$(CP) $(PKG_BUILD_DIR)/node_modules \
		$(1)/usr/lib/node/$(PKG_NPM_NAME)/
	$(INSTALL_DIR) $(1)/usr/lib/node/$(PKG_NPM_NAME)/build/Release
	$(CP) $(PKG_BUILD_DIR)/build/Release/aws-crt-nodejs.node \
		$(1)/usr/lib/node/$(PKG_NPM_NAME)/build/Release/
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_BUILD_DIR)/build/lib/libs2n* \
		$(1)/usr/lib/
	$(CP) $(PKG_BUILD_DIR)/build/Release/libaws-c-* \
		$(1)/usr/lib/
	$(INSTALL_DIR) $(1)/usr/lib/node_modules
	$(LN) ../node/$(PKG_NPM_NAME) $(1)/usr/lib/node_modules/$(PKG_NPM_NAME)
endef

define Package/node-aws-crt/postrm
#!/bin/sh
rm /usr/lib/node_modules/aws-crt || true
rm -rf /usr/lib/node/aws-crt || true
endef

$(eval $(call BuildPackage,node-aws-crt))
