#!/bin/bash
# Copyright (C) 2023 muink https://github.com/muink
#
# depends curl jsonfilter

CURL="$(command -v natmap-curl)"

# JSON_EXPORT <json>
JSON_EXPORT() {
	for k in $ALL_PARAMS; do
		jsonfilter -qs "$1" -e "$k=@['$k']"
	done
}

# INIT_GLOBAL_VAR <var1> [var2] [var3] ...
INIT_GLOBAL_VAR() {
	for _key in "$@"; do
		eval "$_key=''"
	done
}
