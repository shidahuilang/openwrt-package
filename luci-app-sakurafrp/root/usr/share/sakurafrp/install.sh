#!/bin/sh
APP_DIR="/usr/share/sakurafrp"
APP_FILE="$APP_DIR/frpc"

if [ -f "$APP_FILE" ]; then
  exit 0
fi

output() {
  time="$(date +%Y/%m/%d) $(date +%H:%M:%S)"
  echo "${time} $1"
}

FRPC_i386="https://getfrp.sh/d/frpc_linux_386"
FRPC_amd64="https://getfrp.sh/d/frpc_linux_amd64"
FRPC_arm_garbage="https://getfrp.sh/d/frpc_linux_arm_garbage"
FRPC_armv7="https://getfrp.sh/d/frpc_linux_armv7"
FRPC_arm64="https://getfrp.sh/d/frpc_linux_arm64"
FRPC_mips="https://getfrp.sh/d/frpc_linux_mips"
FRPC_mipsle="https://getfrp.sh/d/frpc_linux_mipsle"
FRPC_mips64="https://getfrp.sh/d/frpc_linux_mips64"
FRPC_mip64le="https://getfrp.sh/d/frpc_linux_mips64le"
FRPC_riscv64="https://getfrp.sh/d/frpc_linux_riscv64"

output "Installing frpc...."

arch=$(uname -m)
output "CPU arch is ${arch}"

mips=$(echo -n I | hexdump -o | awk '{print substr($2,6,1); exit}')
output "mips is ${mips}"

url=""

# Arch
if [ "$arch" == "x86_64" ]; then
  url=$FRPC_amd64
elif [ "$arch" == "i386" ] || [ "$arch" == "i686" ]; then
  url=$FRPC_i386
elif [ "$arch" == "arm" ] || [ "$arch" == "armel" ]; then
    url=$FRPC_arm_garbage
elif [ "$arch" == "armv7l" ] || [ "$arch" == "armhf" ]; then
      url=$FRPC_armv7
elif [ "$arch" == "aarch64" ] || [ "$arch" == "armv8l" ]; then
        url=$FRPC_arm64
elif [ "$arch" == "mips" ] && [ "$mips" == "0" ]; then
          url=$FRPC_mips
elif [ "$arch" == "mips" ] && [ "$mips" == "1" ]; then
          url=$FRPC_mipsle
elif [ "$arch" == "mips64" ] && [ "$mips" == "0" ]; then
          url=$FRPC_mips64
elif [ "$arch" == "mips64" ] && [ "$mips" == "1" ]; then
          url=$FRPC_mip64le
elif [ "$arch" == "riscv64" ]; then
  url=$FRPC_riscv64
fi

# Download
output "Downloading frpc from ${url}"
mkdir $APP_DIR > /dev/null 2>&1
wget -O $APP_FILE $url
chmod o+x $APP_FILE

output "Frpc installed to ${APP_FILE}"
