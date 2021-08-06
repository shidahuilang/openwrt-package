#!/bin/bash
cd `dirname $0`
eval $(ps -ef | grep "[0-9] python3 server\\.py a" | awk '{print "kill "$2}')
ulimit -n 512000
nohup python3 server.py a >> ssserver.log 2>&1 &
