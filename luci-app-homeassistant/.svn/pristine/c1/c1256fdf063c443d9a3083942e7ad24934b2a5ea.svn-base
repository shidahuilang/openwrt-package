#!/bin/sh
# Author Xiaobao(xiaobao@linkease.com)

ACTION=${1}
WRLOCK=/var/lock/homeassistant.lock
LOGFILE=/var/log/homeassistant.log
LOGEND="XU6J03M6"
shift 1

IMAGE_NAME='homeassistant/home-assistant:latest'

check_params() {

  if [ -z "${WRLOCK}" ]; then
    echo "lock file not found"
    exit 1
  fi

  if [ -z "${LOGFILE}" ]; then
    echo "logger file not found"
    exit 1
  fi

}

lock_run() {
  local lock="$WRLOCK"
  exec 300>$lock
  flock -n 300 || return
  do_run
  flock -u 300
  return
}

run_action() {
  if check_params; then
    lock_run
  fi
}

get_image() {
  local version=`uci get homeassistant.@homeassistant[0].version 2>/dev/null`
  
  ARCH="arm64"
  if echo `uname -m` | grep -Eqi 'x86_64'; then
    ARCH='amd64'
  elif  echo `uname -m` | grep -Eqi 'aarch64'; then
    ARCH='arm64'
  else
    ARCH='arm64'
  fi

  IMAGE_NAME=linkease/desktop-homeassistant-${version}-${ARCH}:latest
}

do_install() {
  echo "docker pull ${IMAGE_NAME}" >${LOGFILE}
  docker pull ${IMAGE_NAME} >>${LOGFILE} 2>&1
  docker rm -f homeassistant

  docker run -d \
    --name=homeassistant \
    --dns=172.17.0.1 \
    --privileged \
    --restart=unless-stopped \
    -e TZ="Asia/Shanghai" \
    -v /root/homeassistant/config:/config \
    --network=host \
    ${IMAGE_NAME} >>${LOGFILE} 2>&1

  RET=$?
  if [ "${RET}" = "0" ]; then
    # mark END, remove the log file
    echo ${LOGEND} >> ${LOGFILE}
    sleep 5
    rm -f ${LOGFILE}
  else
    # reserve the log
    echo "docker run ${IMAGE_NAME} failed" >>${LOGFILE}
    echo ${LOGEND} >> ${LOGFILE}
  fi
  exit ${RET}
}

# run in lock
do_run() {
  case ${ACTION} in
    "install")
      do_install
    ;;
    "upgrade")
      do_install
    ;;
  esac
}

usage() {
  echo "usage: wxedge sub-command"
  echo "where sub-command is one of:"
  echo "      install                Install the homeassistant"
  echo "      upgrade                Upgrade the homeassistant"
  echo "      remove                 Remove the homeassistant"
}

case ${ACTION} in
  "install")
    run_action
  ;;
  "upgrade")
    run_action
  ;;
  "remove")
    docker rm -f homeassistant
  ;;
  *)
    usage
  ;;
esac

