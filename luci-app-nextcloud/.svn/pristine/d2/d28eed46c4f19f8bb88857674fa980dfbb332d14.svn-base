#!/bin/sh
# Author Xiaobao(xiaobao@linkease.com)

ACTION=${1}
WRLOCK=/var/lock/nextcloud.lock
LOGFILE=/var/log/nextcloud.log
LOGEND="XU6J03M6"
shift 1

IMAGE_NAME='nextcloud'

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

do_install() {
  echo "docker pull ${IMAGE_NAME}" >${LOGFILE}
  docker pull ${IMAGE_NAME} >>${LOGFILE} 2>&1
  docker rm -f nextcloud

  local port=`uci get nextcloud.@nextcloud[0].port 2>/dev/null`
  if [ -z "${port}" ]; then 
    port=8082
  fi

  local mntv="/mnt:/mnt"
  mountpoint -q /mnt && mntv="$mntv:rslave"

  docker run -d \
    --name nextcloud \
    --dns=172.17.0.1 \
    --restart=unless-stopped \
    -p ${port}:80 \
    -v /mnt:/mnt:rslave \
    -e TZ="Asia/Shanghai" \
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
  echo "usage: nextcloud sub-command"
  echo "where sub-command is one of:"
  echo "      install                Install the nextcloud"
  echo "      upgrade                Upgrade the nextcloud"
  echo "      remove                 Remove the nextcloud"
}

case ${ACTION} in
  "install")
    run_action
  ;;
  "upgrade")
    run_action
  ;;
  "remove")
    docker rm -f nextcloud
  ;;
  *)
    usage
  ;;
esac

