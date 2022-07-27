#!/bin/sh
# Author Xiaobao(xiaobao@linkease.com)

ACTION=${1}
WRLOCK=/var/lock/wxedge.lock
LOGFILE=/var/log/wxedge.log
LOGEND="XU6J03M6"
shift 1

IMAGE_NAME=registry.hub.docker.com/onething1/wxedge

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
  local CACHE_PATH=`uci get wxedge.@wxedge[0].cache_path 2>/dev/null`
  if [ -z "${CACHE_PATH}"]; then
    echo "cache path is empty!" >>${LOGFILE}
    exit 1
  fi
    
  echo "docker pull ${IMAGE_NAME}" >>${LOGFILE}
  docker pull ${IMAGE_NAME} >>${LOGFILE} 2>&1
  docker rm -f wxedge

  # -e NIC=eth0
  # -e LISTEN_ADDR="0.0.0:18888"
  docker run -d --name=wxedge \
    --dns=172.17.0.1 \
    -e PLACE=CTKS --privileged \
    --network=host --tmpfs /run --tmpfs /tmp \
    -v ${CACHE_PATH}:/storage:rw -v ${CACHE_PATH}/containerd:/var/lib/containerd \
    --restart=unless-stopped ${IMAGE_NAME} >>${LOGFILE} 2>&1

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
  echo "      install                Install the wxedge"
  echo "      upgrade                Upgrade the wxedge"
  echo "      remove                 Remove the wxedge"
}

case ${ACTION} in
  "install")
    run_action
  ;;
  "upgrade")
    run_action
  ;;
  "remove")
    docker rm -f wxedge
  ;;
  *)
    usage
  ;;
esac
