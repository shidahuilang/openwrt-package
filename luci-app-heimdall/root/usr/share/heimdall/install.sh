#!/bin/sh
# Author Xiaobao(xiaobao@linkease.com)

ACTION=${1}
WRLOCK=/var/lock/heimdall.lock
LOGFILE=/var/log/heimdall.log
LOGEND="XU6J03M6"
shift 1

IMAGE_NAME='lscr.io/linuxserver/heimdall:latest'

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
  local CONFIG_PATH=`uci get heimdall.@heimdall[0].config_path 2>/dev/null`
  local HTTP_PORT=`uci get heimdall.@heimdall[0].http_port 2>/dev/null`
  local HTTPS_PORT=`uci get heimdall.@heimdall[0].https_port 2>/dev/null`
  local LANG=`uci get heimdall.@heimdall[0].lang 2>/dev/null`
  if [ -z "${CONFIG_PATH}" ]; then
      echo "config path is empty!" >${LOGFILE}
      exit 1
  fi
  if [ -z "${HTTP_PORT}" ]; then
      HTTP_PORT=8088
  fi
  if [ -z "${HTTPS_PORT}" ]; then
      HTTPS_PORT=8089
  fi
  echo "docker pull ${IMAGE_NAME}" >${LOGFILE}
  docker pull ${IMAGE_NAME} >>${LOGFILE} 2>&1
  docker rm -f heimdall
  local mntv="/mnt:/mnt"
  mountpoint -q /mnt && mntv="$mntv:rslave"
  docker run -d \
    --name=heimdall \
    --dns=172.17.0.1 \
    -e TZ=Asia/Shanghai \
    -p ${HTTP_PORT}:80 \
    -p ${HTTPS_PORT}:443 \
    -v ${CONFIG_PATH}:/config -v ${mntv} \
    --restart unless-stopped \
    $IMAGE_NAME >>${LOGFILE} 2>&1

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
  echo "      install                Install the heimdall"
  echo "      upgrade                Upgrade the heimdall"
  echo "      remove                 Remove the heimdall"
}

case ${ACTION} in
  "install")
    run_action
  ;;
  "upgrade")
    run_action
  ;;
  "remove")
    docker rm -f heimdall
  ;;
  *)
    usage
  ;;
esac

