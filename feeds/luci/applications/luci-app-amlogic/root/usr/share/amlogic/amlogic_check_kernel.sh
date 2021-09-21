#!/bin/bash

# Set a fixed value
check_option=${1}
download_version=${2}
EMMC_NAME=$(lsblk | grep -oE '(mmcblk[0-9])' | sort | uniq)
KERNEL_DOWNLOAD_PATH="/mnt/${EMMC_NAME}p4/.tmp_upload"
TMP_CHECK_DIR="/tmp/amlogic"
AMLOGIC_SOC_FILE="/etc/flippy-openwrt-release"
START_LOG="${TMP_CHECK_DIR}/amlogic_check_kernel.log"
LOG_FILE="${TMP_CHECK_DIR}/amlogic.log"
LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
[[ -d ${TMP_CHECK_DIR} ]] || mkdir -p ${TMP_CHECK_DIR}
[[ -d ${KERNEL_DOWNLOAD_PATH} ]] || mkdir -p ${KERNEL_DOWNLOAD_PATH}

# Log function
tolog() {
    echo -e "${1}" >$START_LOG
    echo -e "${LOGTIME} ${1}" >>$LOG_FILE
    [[ -z "${2}" ]] || exit 1
}

# Current device model
MYDEVICE_NAME=$(cat /proc/device-tree/model | tr -d '\000')
if [[ -z "${MYDEVICE_NAME}" ]]; then
    tolog "Unknown device" "1"
elif [[ "$(echo ${MYDEVICE_NAME} | grep "Chainedbox L1 Pro")" != "" ]]; then
    MYDTB_FILE="rockchip"
elif [[ "$(echo ${MYDEVICE_NAME} | grep "BeikeYun")" != "" ]]; then
    MYDTB_FILE="rockchip"
elif [[ "$(echo ${MYDEVICE_NAME} | grep "V-Plus Cloud")" != "" ]]; then
    MYDTB_FILE="allwinner"
elif [[ -f "${AMLOGIC_SOC_FILE}" ]]; then
    MYDTB_FILE="amlogic"
else
    tolog "Unknown device: [ ${MYDEVICE_NAME} ], Not supported." "1"
fi
tolog "Current device: ${MYDEVICE_NAME} [ ${MYDTB_FILE} ]"
sleep 3

# Step 1: URL formatting start -----------------------------------------------------------
#
# 01. Download server version documentation
tolog "01. Start checking the kernel version."
server_firmware_url=$(uci get amlogic.config.amlogic_firmware_repo 2>/dev/null)
[[ ! -z "${server_firmware_url}" ]] || tolog "01.01 The custom kernel download repo is invalid." "1"
server_kernel_path=$(uci get amlogic.config.amlogic_kernel_path 2>/dev/null)
[[ ! -z "${server_kernel_path}" ]] || tolog "01.02 The custom kernel download path is invalid." "1"
#
# Supported format:
#
# server_firmware_url="https://github.com/ophub/amlogic-s9xxx-openwrt"
# server_firmware_url="ophub/amlogic-s9xxx-openwrt"
#
# server_kernel_path="https://github.com/ophub/amlogic-s9xxx-openwrt/tree/main/amlogic-s9xxx/amlogic-kernel"
# server_kernel_path="https://github.com/ophub/amlogic-s9xxx-openwrt/trunk/amlogic-s9xxx/amlogic-kernel"
# server_kernel_path="amlogic-s9xxx/amlogic-kernel"
#
if [[ ${server_firmware_url} == http* ]]; then
    server_firmware_url=${server_firmware_url#*com\/}
fi

if [[ ${server_kernel_path} == http* && $(echo ${server_kernel_path} | grep "tree") != "" ]]; then
    # Left part
    server_kernel_path_left=${server_kernel_path%\/tree*}
    server_kernel_path_left=${server_kernel_path_left#*com\/}
    server_firmware_url=${server_kernel_path_left}
    # Right part
    server_kernel_path_right=${server_kernel_path#*tree\/}
    server_kernel_path_right=${server_kernel_path_right#*\/}
    server_kernel_path=${server_kernel_path_right}
elif [[ ${server_kernel_path} == http* && $(echo ${server_kernel_path} | grep "trunk") != "" ]]; then
    # Left part
    server_kernel_path_left=${server_kernel_path%\/trunk*}
    server_kernel_path_left=${server_kernel_path_left#*com\/}
    server_firmware_url=${server_kernel_path_left}
    # Right part
    server_kernel_path_right=${server_kernel_path#*trunk\/}
    server_kernel_path=${server_kernel_path_right}
fi

server_kernel_url="https://api.github.com/repos/${server_firmware_url}/contents/${server_kernel_path}"
# Step 1: URL formatting end -----------------------------------------------------------

# Step 2: Check if there is the latest kernel version
check_kernel() {
    # 02. Query local version information
    tolog "02. Start checking the kernel version."
    # 02.01 Query the current version
    current_kernel_v=$(ls /lib/modules/  2>/dev/null | grep -oE '^[1-9].[0-9]{1,2}.[0-9]+')
    tolog "02.01 current version: ${current_kernel_v}"
    sleep 3

    # 02.02 Version comparison
    main_line_ver=$(echo "${current_kernel_v}" | cut -d '.' -f1)
    main_line_maj=$(echo "${current_kernel_v}" | cut -d '.' -f2)
    main_line_now=$(echo "${current_kernel_v}" | cut -d '.' -f3)
    main_line_version="${main_line_ver}.${main_line_maj}"

    # 02.03 Query the selected branch in the settings
    server_kernel_branch=$(uci get amlogic.config.amlogic_kernel_branch 2>/dev/null | grep -oE '^[1-9].[0-9]{1,3}')
    if [[ -n "${server_kernel_branch}" && "${server_kernel_branch}" != "${main_line_version}" ]]; then
        main_line_version="${server_kernel_branch}"
        main_line_now="0"
        tolog "02.02 Select branch: ${main_line_version}"
        sleep 3
    fi

    # Check the version on the server
    latest_version=$(curl -s "${server_kernel_url}" | grep "name" | grep -oE "${main_line_version}.[0-9]+"  | sed -e "s/${main_line_version}.//g" | sort -n | sed -n '$p')
    #latest_version="124"
    [[ ! -z "${latest_version}" ]] || tolog "02.03 Failed to get the version on the server." "1"
    tolog "02.03 current version: ${current_kernel_v}, Latest version: ${main_line_version}.${latest_version}"
    sleep 3

    if [[ "${latest_version}" -eq "${main_line_now}" ]]; then
        tolog "02.04 Already the latest version, no need to update." "1"
        sleep 5
        tolog ""
        exit 0
    else
        tolog '<input type="button" class="cbi-button cbi-button-reload" value="Download" onclick="return b_check_kernel(this, '"'download_${main_line_version}.${latest_version}'"')"/> Latest version: '${main_line_version}.${latest_version}''
        exit 0
    fi
}

# Step 3: Download the latest kernel version
download_kernel() {
    tolog "03. Start download the kernels."
    if [[ ${download_version} == download* ]]; then
        download_version=$(echo "${download_version}" | cut -d '_' -f2)
        tolog "03.01 The kernel version: ${download_version}, downloading..."
    else
        tolog "03.02 Invalid parameter" "1"
    fi

    # Delete other residual kernel files
    rm -f ${KERNEL_DOWNLOAD_PATH}/boot-*.tar.gz 2>/dev/null && sync
    rm -f ${KERNEL_DOWNLOAD_PATH}/dtb-*.tar.gz 2>/dev/null && sync
    rm -f ${KERNEL_DOWNLOAD_PATH}/modules-*.tar.gz 2>/dev/null && sync
    rm -f /mnt/${EMMC_NAME}p4/boot-*.tar.gz 2>/dev/null && sync
    rm -f /mnt/${EMMC_NAME}p4/dtb-*.tar.gz 2>/dev/null && sync
    rm -f /mnt/${EMMC_NAME}p4/modules-*.tar.gz 2>/dev/null && sync

    # Download boot file from the kernel directory under the path: ${server_kernel_url}/${download_version}/
    server_kernel_boot="$(curl -s "${server_kernel_url}/${download_version}" | grep "download_url" | grep -o "https.*/boot-${download_version}.*.tar.gz" | head -n 1)"
    # Download boot file from current path: ${server_kernel_url}/
    if [ -z "${server_kernel_boot}" ]; then
        server_kernel_boot="$(curl -s "${server_kernel_url}" | grep "download_url" | grep -o "https.*/boot-${download_version}.*.tar.gz" | head -n 1)"
    fi
    boot_file_name="${server_kernel_boot##*/}"
    server_kernel_boot_name="${boot_file_name//%2B/+}"
    wget -c "${server_kernel_boot}" -O "${KERNEL_DOWNLOAD_PATH}/${server_kernel_boot_name}" >/dev/null 2>&1 && sync
    if [[ "$?" -eq "0" && -s "${KERNEL_DOWNLOAD_PATH}/${server_kernel_boot_name}" ]]; then
        tolog "03.03 The boot file complete."
    else
        tolog "03.04 The boot file failed to download." "1"
    fi
    sleep 3

    # Download dtb file from the kernel directory under the path: ${server_kernel_url}/${download_version}/
    server_kernel_dtb="$(curl -s "${server_kernel_url}/${download_version}" | grep "download_url" | grep -o "https.*/dtb-${MYDTB_FILE}-${download_version}.*.tar.gz" | head -n 1)"
    # Download dtb file from current path: ${server_kernel_url}/
    if [ -z "${server_kernel_dtb}" ]; then
        server_kernel_dtb="$(curl -s "${server_kernel_url}" | grep "download_url" | grep -o "https.*/dtb-${MYDTB_FILE}-${download_version}.*.tar.gz" | head -n 1)"
    fi
    dtb_file_name="${server_kernel_dtb##*/}"
    server_kernel_dtb_name="${dtb_file_name//%2B/+}"
    wget -c "${server_kernel_dtb}" -O "${KERNEL_DOWNLOAD_PATH}/${server_kernel_dtb_name}" >/dev/null 2>&1 && sync
    if [[ "$?" -eq "0" && -s "${KERNEL_DOWNLOAD_PATH}/${server_kernel_dtb_name}" ]]; then
        tolog "03.05 The dtb file complete."
    else
        tolog "03.06 The dtb file failed to download." "1"
    fi
    sleep 3

    # Download modules file from the kernel directory under the path: ${server_kernel_url}/${download_version}/
    server_kernel_modules="$(curl -s "${server_kernel_url}/${download_version}" | grep "download_url" | grep -o "https.*/modules-${download_version}.*.tar.gz" | head -n 1)"
    # Download modules file from current path: ${server_kernel_url}/
    if [ -z "${server_kernel_modules}" ]; then
        server_kernel_modules="$(curl -s "${server_kernel_url}" | grep "download_url" | grep -o "https.*/modules-${download_version}.*.tar.gz" | head -n 1)"
    fi
    modules_file_name="${server_kernel_modules##*/}"
    server_kernel_modules_name="${modules_file_name//%2B/+}"
    wget -c "${server_kernel_modules}" -O "${KERNEL_DOWNLOAD_PATH}/${server_kernel_modules_name}" >/dev/null 2>&1 && sync
    if [[ "$?" -eq "0" && -s "${KERNEL_DOWNLOAD_PATH}/${server_kernel_modules_name}" ]]; then
        tolog "03.07 The modules file complete."
    else
        tolog "03.08 The modules file failed to download." "1"
    fi
    sleep 3

    tolog "04 The kernel is ready, you can update."
    sleep 3

    #echo '<a href="javascript:;" onclick="return amlogic_kernel(this)">Update</a>' >$START_LOG
    tolog '<input type="button" class="cbi-button cbi-button-reload" value="Update" onclick="return amlogic_kernel(this)"/>'

    exit 0
}

getopts 'cd' opts
case $opts in
    c | check)        check_kernel;;
    * | download)     download_kernel;;
esac
