#!/bin/bash

# Set a fixed value
EMMC_NAME=$(lsblk | grep -oE '(mmcblk[0-9])' | sort | uniq)
FIRMWARE_DOWNLOAD_PATH="/mnt/${EMMC_NAME}p4"
TMP_CHECK_DIR="/tmp/amlogic"
AMLOGIC_SOC_FILE="/etc/flippy-openwrt-release"
START_LOG="${TMP_CHECK_DIR}/amlogic_check_firmware.log"
LOG_FILE="${TMP_CHECK_DIR}/amlogic.log"
LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
[[ -d ${TMP_CHECK_DIR} ]] || mkdir -p ${TMP_CHECK_DIR}

# Log function
tolog() {
    echo -e "${1}" >$START_LOG
    echo -e "${LOGTIME} ${1}" >>$LOG_FILE
    [[ -z "${2}" ]] || exit 1
}

# Current device model
MYDEVICE_NAME=$(cat /proc/device-tree/model 2>/dev/null)
if [ -z "${MYDEVICE_NAME}" ]; then
    tolog "Unknown device" "1"
elif [ "${MYDEVICE_NAME}" == "Chainedbox L1 Pro" ]; then
    MYDTB_FILE="rockchip"
    SOC="l1pro"
elif [ "${MYDEVICE_NAME}" == "BeikeYun" ]; then
    MYDTB_FILE="rockchip"
    SOC="beikeyun"
elif [ "${MYDEVICE_NAME}" == "V-Plus Cloud" ]; then
    MYDTB_FILE="allwinner"
    SOC="vplus"
else
    MYDTB_FILE="amlogic"
    source ${AMLOGIC_SOC_FILE} 2>/dev/null
    SOC="${SOC}"
fi
[[ ! -z "${SOC}" ]] || tolog "The custom firmware soc is invalid." "1"
tolog "Current device: ${MYDEVICE_NAME} [ ${SOC} ]"
sleep 3

# 01. Query local version information
tolog "01. Query version information."
# 01.01 Query the current version
CURRENT_KERNEL_V=$(ls /lib/modules/  2>/dev/null | grep -oE '^[1-9].[0-9]{1,3}.[0-9]+')
tolog "01.01 current version: ${CURRENT_KERNEL_V}"
sleep 3

# 01.01 Version comparison
MAIN_LINE_VER=$(echo "${CURRENT_KERNEL_V}" | cut -d '.' -f1)
MAIN_LINE_MAJ=$(echo "${CURRENT_KERNEL_V}" | cut -d '.' -f2)
MAIN_LINE_VERSION="${MAIN_LINE_VER}.${MAIN_LINE_MAJ}"

# 01.02. Query the selected branch in the settings
SERVER_KERNEL_BRANCH=$(uci get amlogic.config.amlogic_kernel_branch 2>/dev/null | grep -oE '^[1-9].[0-9]{1,3}')
if [[ -n "${SERVER_KERNEL_BRANCH}" && "${SERVER_KERNEL_BRANCH}" != "${MAIN_LINE_VERSION}" ]]; then
    MAIN_LINE_VERSION="${SERVER_KERNEL_BRANCH}"
    tolog "01.02 Select branch: ${MAIN_LINE_VERSION}"
    sleep 3
fi


# 02. Download server version documentation
tolog "02. Start checking the firmware version."
SERVER_FIRMWARE_URL=$(uci get amlogic.config.amlogic_firmware_repo 2>/dev/null)
[[ ! -z "${SERVER_FIRMWARE_URL}" ]] || tolog "02.01 The custom firmware download repo is invalid." "1"
RELEASES_TAG_KEYWORDS=$(uci get amlogic.config.amlogic_firmware_tag 2>/dev/null)
[[ ! -z "${RELEASES_TAG_KEYWORDS}" ]] || tolog "02.02 The custom firmware tag keywords is invalid." "1"
FIRMWARE_SUFFIX=$(uci get amlogic.config.amlogic_firmware_suffix 2>/dev/null)
[[ ! -z "${FIRMWARE_SUFFIX}" ]] || tolog "02.03 The custom firmware suffix is invalid." "1"

# Supported format:
# SERVER_FIRMWARE_URL="https://github.com/ophub/amlogic-s9xxx-openwrt"
# SERVER_FIRMWARE_URL="ophub/amlogic-s9xxx-openwrt"
if [[ ${SERVER_FIRMWARE_URL} == http* ]]; then
    SERVER_FIRMWARE_URL=${SERVER_FIRMWARE_URL#*com\/}
fi

# 03. Version comparison
tolog "03. Download Openwrt firmware ..."
# Delete other residual firmware files
rm -f ${FIRMWARE_DOWNLOAD_PATH}/*${FIRMWARE_SUFFIX} && sync
rm -f ${FIRMWARE_DOWNLOAD_PATH}/*.img && sync

FIRMWARE_DOWNLOAD_URL="https:.*${RELEASES_TAG_KEYWORDS}.*${SOC}.*${MAIN_LINE_VERSION}.*${FIRMWARE_SUFFIX}"

FIRMWARE_RELEASES_PATH=$(curl -s "https://api.github.com/repos/${SERVER_FIRMWARE_URL}/releases" | grep "browser_download_url" | grep -o "${FIRMWARE_DOWNLOAD_URL}" | head -n 1)
FIRMWARE_DOWNLOAD_NAME="openwrt_${SOC}_k${MAIN_LINE_VERSION}_update${FIRMWARE_SUFFIX}"
wget -c "${FIRMWARE_RELEASES_PATH}" -O "${FIRMWARE_DOWNLOAD_PATH}/${FIRMWARE_DOWNLOAD_NAME}" >/dev/null 2>&1 && sync
if [[ "$?" -eq "0" && -s "${FIRMWARE_DOWNLOAD_PATH}/${FIRMWARE_DOWNLOAD_NAME}" ]]; then
    tolog "03.01 OpenWrt firmware download complete, you can update."
else
    tolog "03.02 Invalid firmware download." "1"
fi
sleep 3

#echo '<a href="javascript:;" onclick="return amlogic_update(this, '"'${FIRMWARE_DOWNLOAD_NAME}'"')">Update</a>' >$START_LOG
tolog '<input type="button" class="cbi-button cbi-button-reload" value="Update" onclick="return amlogic_update(this, '"'${FIRMWARE_DOWNLOAD_NAME}'"')"/>'

exit 0

