include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_VERSION:=130.0.6723.40-5
PKG_RELEASE:=8

ARCH_PREBUILT:=$(ARCH_PACKAGES)

# intel 80386 & riscv64 & cortex-a76
ifeq ($(ARCH_PREBUILT),aarch64_cortex-a76)
  ARCH_PREBUILT:=aarch64_generic
else ifeq ($(ARCH_PREBUILT),i386_pentium-mmx)
  ARCH_PREBUILT:=x86
else ifeq ($(ARCH_PREBUILT),i386_pentium4)
  ARCH_PREBUILT:=x86
else ifeq ($(ARCH_PREBUILT),mipsel_24kc_24kf)
  ARCH_PREBUILT:=mipsel_24kc
else ifeq ($(ARCH_PREBUILT),mipsel_74kc)
  ARCH_PREBUILT:=mipsel_24kc
else ifeq ($(ARCH_PREBUILT),riscv64_riscv64)
  ARCH_PREBUILT:=riscv64
endif

PKG_SOURCE:=naiveproxy-v$(PKG_VERSION)-openwrt-$(ARCH_PREBUILT).tar.xz
PKG_SOURCE_URL:=https://github.com/klzgrad/naiveproxy/releases/download/v$(PKG_VERSION)/

ifeq ($(ARCH_PREBUILT),aarch64_cortex-a53)
  PKG_HASH:=skip
else ifeq ($(ARCH_PREBUILT),aarch64_cortex-a72)
  PKG_HASH:=skip
else ifeq ($(ARCH_PREBUILT),aarch64_generic)
  PKG_HASH:=skip
else ifeq ($(ARCH_PREBUILT),arm_arm1176jzf-s_vfp)
  PKG_HASH:=skip
else ifeq ($(ARCH_PREBUILT),arm_arm926ej-s)
  PKG_HASH:=skip
else ifeq ($(ARCH_PREBUILT),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=skip
else ifeq ($(ARCH_PREBUILT),arm_cortex-a5_vfpv4)
  PKG_HASH:=skip
else ifeq ($(ARCH_PREBUILT),arm_cortex-a7)
  PKG_HASH:=skip
else ifeq ($(ARCH_PREBUILT),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=skip
else ifeq ($(ARCH_PREBUILT),arm_cortex-a7_vfpv4)
  PKG_HASH:=skip
else ifeq ($(ARCH_PREBUILT),arm_cortex-a8_vfpv3)
  PKG_HASH:=skip
else ifeq ($(ARCH_PREBUILT),arm_cortex-a9)
  PKG_HASH:=skip
else ifeq ($(ARCH_PREBUILT),arm_cortex-a9_neon)
  PKG_HASH:=skip
else ifeq ($(ARCH_PREBUILT),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=skip
else ifeq ($(ARCH_PREBUILT),arm_mpcore)
  PKG_HASH:=skip
else ifeq ($(ARCH_PREBUILT),arm_xscale)
  PKG_HASH:=skip
else ifeq ($(ARCH_PREBUILT),mipsel_24kc)
  PKG_HASH:=skip
else ifeq ($(ARCH_PREBUILT),mipsel_mips32)
  PKG_HASH:=skip
else ifeq ($(ARCH_PREBUILT),riscv64)
  PKG_HASH:=skip
else ifeq ($(ARCH_PREBUILT),x86)
  PKG_HASH:=skip
else ifeq ($(ARCH_PREBUILT),x86_64)
  PKG_HASH:=skip
else
  PKG_HASH:=skip
endif

PKG_LICENSE:=BSD 3-Clause
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=sbwml <admin@cooluc.com>

PKG_BUILD_DIR:=$(BUILD_DIR)/naiveproxy-v$(PKG_VERSION)-openwrt-$(ARCH_PACKAGES)

include $(INCLUDE_DIR)/package.mk

define Package/naiveproxy
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=Make a fortune quietly
  URL:=https://github.com/klzgrad/naiveproxy
  DEPENDS:=@(aarch64||arm||i386||mipsel||riscv64||x86_64) +libatomic
endef

define Package/naiveproxy/description
  NaïveProxy uses Chrome's network stack to camouflage traffic with strong
  censorship resistance and low detectability. Reusing Chrome's stack also
  ensures best practices in performance and security.
endef

define Package/naiveproxy/conffiles
/etc/config/naiveproxy
endef

define Build/Prepare
	$(TAR) --strip-components=1 -C $(PKG_BUILD_DIR) -xJf $(DL_DIR)/naiveproxy-v$(PKG_VERSION)-openwrt-$(ARCH_PREBUILT).tar.xz
endef

define Build/Compile
endef

define Package/naiveproxy/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/naive $(1)/usr/bin/naive
	$(INSTALL_DIR) $(1)/etc/config $(1)/etc/init.d
	$(INSTALL_CONF) $(CURDIR)/files/naiveproxy.config $(1)/etc/config/naiveproxy
	$(INSTALL_BIN) $(CURDIR)/files/naiveproxy.init $(1)/etc/init.d/naiveproxy
endef

$(eval $(call BuildPackage,naiveproxy))
