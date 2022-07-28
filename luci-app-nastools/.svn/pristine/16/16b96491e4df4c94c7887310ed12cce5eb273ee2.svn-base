#!/bin/sh
# Author Xiaobao(xiaobao@linkease.com)

ACTION=${1}
WRLOCK=/var/lock/nastools.lock
LOGFILE=/var/log/nastools.log
LOGEND="XU6J03M6"
shift 1

IMAGE_NAME='jxxghp/nas-tools'

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
  local CONFIG_PATH=`uci get nastools.@nastools[0].config_path 2>/dev/null`
  local HTTP_PORT=`uci get nastools.@nastools[0].http_port 2>/dev/null`
  local AUTO_UPDATE=`uci get nastools.@nastools[0].auto_upgrade 2>/dev/null`
  if [ -z "${CONFIG_PATH}" ]; then
      echo "config path is empty!" >${LOGFILE}
      exit 1
  fi
  if [ -z "${HTTP_PORT}" ]; then
      HTTP_PORT=3003
  fi
  if [ -z "${AUTO_UPDATE}" ]; then
    AUTO_UPDATE=0
  fi
  UPDATE_BOOL=false
  if [ "${AUTO_UPDATE}" = "1" ]; then
    UPDATE_BOOL=true
  fi
  echo "docker pull ${IMAGE_NAME}" >${LOGFILE}
  docker pull ${IMAGE_NAME} >>${LOGFILE} 2>&1
  docker rm -f nastools
  local mntv="/mnt:/mnt"
  mountpoint -q /mnt && mntv="$mntv:rslave"
  docker run -d \
    --name=nastools \
    --dns=172.17.0.1 \
    --hostname nastools \
    -p ${HTTP_PORT}:3000 \
    -v ${CONFIG_PATH}:/config -v ${mntv} \
    -e UMASK=000 \
    -e NASTOOL_AUTO_UPDATE=${UPDATE_BOOL} \
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
  echo "      install                Install the nastools"
  echo "      upgrade                Upgrade the nastools"
  echo "      remove                 Remove the nastools"
}

case ${ACTION} in
  "install")
    run_action
  ;;
  "upgrade")
    run_action
  ;;
  "remove")
    docker rm -f nastools
  ;;
  *)
    usage
  ;;
esac

