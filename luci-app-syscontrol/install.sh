#!/bin/sh

# Copyright (c) 2023 bobbyunknown
# https://github.com/bobbyunknown
# 
# Hak Cipta Dilindungi Undang-Undang
# https://rem.mit-license.org/

PACKAGE_NAME="luci-app-syscontrol"

get_latest_release_url() {
    REPO="bobbyunknown/luci-app-syscontrol"
    API_URL="https://api.github.com/repos/$REPO/releases/latest"
    DOWNLOAD_URL=$(curl -s "$API_URL" | grep "browser_download_url.*ipk" | cut -d '"' -f 4)
    
    if [ ! -z "$DOWNLOAD_URL" ]; then
        FILENAME=$(basename "$DOWNLOAD_URL")
        echo "$DOWNLOAD_URL|$FILENAME"
    else
        echo ""
    fi
}

check_system_resources() {
    FREE_SPACE=$(df -h /tmp | awk 'NR==2 {print $4}')
    echo "Ruang disk tersedia di /tmp: $FREE_SPACE"
}

install_package() {
    check_system_resources
    echo "Menginstal $PACKAGE_NAME..."
    opkg update 
    
    RELEASE_INFO=$(get_latest_release_url)
    if [ -z "$RELEASE_INFO" ]; then
        echo "Gagal mendapatkan informasi rilis. Silakan coba lagi nanti."
        read -p "Tekan Enter untuk melanjutkan..."
        return 1
    fi
    
    DOWNLOAD_URL=$(echo "$RELEASE_INFO" | cut -d'|' -f1)
    FILENAME=$(echo "$RELEASE_INFO" | cut -d'|' -f2)
    
    echo "Mengunduh $FILENAME..."
    if ! curl -L -o "/tmp/$FILENAME" "$DOWNLOAD_URL"; then
        echo "Gagal mengunduh file. Silakan periksa koneksi internet Anda."
        read -p "Tekan Enter untuk melanjutkan..."
        return 1
    fi
    
    if [ ! -f "/tmp/$FILENAME" ]; then
        echo "File tidak ditemukan setelah unduhan. Silakan coba lagi."
        read -p "Tekan Enter untuk melanjutkan..."
        return 1
    fi
    
    echo "File yang diunduh: /tmp/$FILENAME"
    ls -l "/tmp/$FILENAME"
    
    echo "Menginstal paket..."
    if ! opkg install "/tmp/$FILENAME"; then
        echo "Gagal menginstal paket. Silakan coba opsi force install."
        rm -f "/tmp/$FILENAME"
        read -p "Tekan Enter untuk melanjutkan..."
        return 1
    fi
    
    rm -f "/tmp/$FILENAME"
    echo "Instalasi $PACKAGE_NAME selesai."
    read -p "Tekan Enter untuk melanjutkan..."
}

force_install_package() {
    check_system_resources
    echo "Melakukan force install $PACKAGE_NAME..."
    opkg update
    
    RELEASE_INFO=$(get_latest_release_url)
    if [ -z "$RELEASE_INFO" ]; then
        echo "Gagal mendapatkan informasi rilis. Silakan coba lagi nanti."
        read -p "Tekan Enter untuk melanjutkan..."
        return 1
    fi
    
    DOWNLOAD_URL=$(echo "$RELEASE_INFO" | cut -d'|' -f1)
    FILENAME=$(echo "$RELEASE_INFO" | cut -d'|' -f2)
    
    echo "Mengunduh $FILENAME..."
    if ! curl -L -o "/tmp/$FILENAME" "$DOWNLOAD_URL"; then
        echo "Gagal mengunduh file. Silakan periksa koneksi internet Anda."
        read -p "Tekan Enter untuk melanjutkan..."
        return 1
    fi
    
    if [ ! -f "/tmp/$FILENAME" ]; then
        echo "File tidak ditemukan setelah unduhan. Silakan coba lagi."
        read -p "Tekan Enter untuk melanjutkan..."
        return 1
    fi
    
    echo "File yang diunduh: /tmp/$FILENAME"
    ls -l "/tmp/$FILENAME"
    
    echo "Melakukan force install paket..."
    if ! opkg install --force-reinstall "/tmp/$FILENAME"; then
        echo "Gagal melakukan force install paket."
        rm -f "/tmp/$FILENAME"
        read -p "Tekan Enter untuk melanjutkan..."
        return 1
    fi
    
    rm -f "/tmp/$FILENAME"
    echo "Force install $PACKAGE_NAME selesai."
    read -p "Tekan Enter untuk melanjutkan..."
}

uninstall_package() {
    echo "Menghapus $PACKAGE_NAME..."
    opkg remove "$PACKAGE_NAME"
    find / -type d -name "*syscontrol*" -exec rm -rf {} + 2>/dev/null
    find / -type f -name "*syscontrol*" -delete 2>/dev/null
    echo "Paket $PACKAGE_NAME dan file-file terkait berhasil dihapus."
    read -p "Tekan Enter untuk melanjutkan..."
}

while true; do
    clear
    echo "┌─────────────────────────────────────┐"
    echo "│    luci-app-syscontrol Installer    │"
    echo "│     github.com/bobbyunknown         │"
    echo "├─────────────────────────────────────┤"
    echo "│                                     │"
    echo "│  1. Install syscontrol              │"
    echo "│  2. Force Install syscontrol        │"
    echo "│  3. Uninstall syscontrol            │"
    echo "│  4. Keluar                          │"
    echo "│                                     │"
    echo "└─────────────────────────────────────┘"
    echo
    read -p "Pilihan Anda [1-4]: " choice
    echo

    case $choice in
        1)
            install_package
            ;;
        2)
            force_install_package
            ;;
        3)
            uninstall_package
            ;;
         4)
            echo "Keluar dari program."
            exit 0
            ;;
        *)
            echo "Pilihan tidak valid. Silakan coba lagi."
            ;;
    esac

    echo "Operasi selesai."
    echo
done
