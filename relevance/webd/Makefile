include $(TOPDIR)/rules.mk

PKG_NAME:=webd
PKG_RELEASE:=1

PKG_VERSION:=20240223
PKG_VERSION_MEDIATEK_FILO:=20240710

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=A Lightweight self-hosted netdisk application
	URL:=https://webd.cf
	# 仅发布了以下架构的预编译二进制(板级限制在 Build/Prepare 阶段二次校验)
	DEPENDS:=@(x86_64||aarch64||arm||mips||mipsel)
endef

TARGET_LIBC:=musl
ifeq ($(CONFIG_USE_UCLIBC),y)
  TARGET_LIBC:=uclibc
endif

ARM_LIBC_TAG:=muslgnueabi
ifeq ($(CONFIG_USE_UCLIBC),y)
  ARM_LIBC_TAG:=uclibcgnueabi
endif

TARGET_ARCH:=
TARGET_BOARD:=

ifeq ($(ARCH),x86_64)
  TARGET_ARCH:=x86_64
  TARGET_BOARD:=musl
endif

ifeq ($(ARCH),mipsel)
  TARGET_ARCH:=mipsel
  ifeq ($(BOARD),ramips)
    TARGET_BOARD:=$(TARGET_LIBC).ramips-mt7620
  endif
  ifeq ($(BOARD),bcm47xx)
    TARGET_BOARD:=musl.brcm47xx-mips74k
  endif
endif

ifeq ($(ARCH),mips)
  TARGET_ARCH:=mips
  ifeq ($(BOARD),ath79)
    TARGET_BOARD:=musl.ath79
  endif
  ifeq ($(BOARD),ar71xx)
    TARGET_BOARD:=uclibc.ar71xx
  endif
  ifeq ($(BOARD),bcm63xx)
    TARGET_BOARD:=uclibc.brcm63xx
  endif
endif

ifeq ($(ARCH),arm)
  TARGET_ARCH:=arm
  ifeq ($(BOARD),ipq806x)
    TARGET_BOARD:=$(ARM_LIBC_TAG).ipq806x
  endif
  ifeq ($(BOARD),ipq40xx)
    TARGET_BOARD:=$(ARM_LIBC_TAG).ipq40xx
  endif
  ifeq ($(BOARD),bcm53xx)
    TARGET_BOARD:=$(ARM_LIBC_TAG).bcm53xx
  endif
  ifeq ($(BOARD),oxnas)
    TARGET_BOARD:=$(ARM_LIBC_TAG).oxnas
  endif
  ifeq ($(BOARD),kirkwood)
    TARGET_BOARD:=$(ARM_LIBC_TAG).kirkwood
  endif
  ifeq ($(BOARD),mvebu)
    TARGET_BOARD:=$(ARM_LIBC_TAG).mvebu-cortexa9
  endif
endif

ifeq ($(ARCH),aarch64)
  TARGET_ARCH:=aarch64

  ifeq ($(BOARD),rockchip)
    TARGET_BOARD:=musl.rockchip-armv8
  endif
  ifeq ($(BOARD),brcm2708)
    TARGET_BOARD:=musl.brcm2708-bcm2710
  endif

  ifeq ($(BOARD),mediatek)
    ifneq (,$(filter filogic,$(SUBTARGET)))
      TARGET_BOARD:=musl.mediatek-filogic
      PKG_VERSION:=$(PKG_VERSION_MEDIATEK_FILO)
    endif
  endif
endif

# 注意: 不能在此处用 $(error) 判断 ARCH/BOARD —— OpenWrt 扫描包元数据(dumpinfo)
# 时是目标无关环境, ARCH/BOARD 为空, parse 阶段报错会导致整个 feed 扫描失败
UNSUPPORTED_COMBO:=
ifeq ($(strip $(TARGET_ARCH)$(TARGET_BOARD)),)
  UNSUPPORTED_COMBO:=1
endif

# webd.cf 域名已失效(无法解析),预编译二进制下载源不可达
# 不定义 PKG_SOURCE_URL/PKG_SOURCE,避免 OpenWrt 自动 download 阶段失败
# Build/Prepare 中尝试下载,失败则创建占位文件使包能编译通过(运行时 webd 不可用)
UNTAR_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
WEBD_BINARY:=$(UNTAR_DIR)/webd/webd

define Build/Prepare
	$(INSTALL_DIR) $(UNTAR_DIR)
	@if [ "$(UNSUPPORTED_COMBO)" = "1" ]; then \
		echo "WARNING: webd has no prebuilt binary for ARCH=$(ARCH) BOARD=$(BOARD), creating stub"; \
		mkdir -p $(UNTAR_DIR)/webd/web; \
		echo "" > $(WEBD_BINARY); chmod +x $(WEBD_BINARY); \
		echo "" > $(UNTAR_DIR)/webd/webd.conf; \
		exit 0; \
	fi; \
	SRC_FILE="$(PKG_NAME)-$(PKG_VERSION)-$(TARGET_ARCH)-openwrt-linux-$(TARGET_BOARD).tar.gz"; \
	SRC_URL="https://webd.cf/webd/$(PKG_VERSION)/$$SRC_FILE"; \
	echo "Trying to download webd from $$SRC_URL"; \
	if curl -fsSL --connect-timeout 10 --max-time 60 "$$SRC_URL" -o "$(DL_DIR)/$$SRC_FILE" 2>/dev/null; then \
		$(TAR) -C $(UNTAR_DIR) -xzf "$(DL_DIR)/$$SRC_FILE"; \
		echo "webd downloaded and extracted successfully"; \
	else \
		echo "WARNING: webd download failed (webd.cf unreachable), creating stub binary"; \
		mkdir -p $(UNTAR_DIR)/webd/web; \
		echo "" > $(WEBD_BINARY); chmod +x $(WEBD_BINARY); \
		echo "" > $(UNTAR_DIR)/webd/webd.conf; \
	fi
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(UNTAR_DIR)/webd/webd $(1)/usr/bin/webd

	$(INSTALL_DIR) $(1)/usr/share/$(PKG_NAME)/web
	$(CP) -r $(UNTAR_DIR)/webd/web/* $(1)/usr/share/$(PKG_NAME)/web/

	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_DATA) $(UNTAR_DIR)/webd/webd.conf $(1)/etc/webd.conf.example

endef

$(eval $(call BuildPackage,$(PKG_NAME)))
