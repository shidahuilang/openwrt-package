#!/bin/sh

# This is open source software, licensed under the MIT License.
#
# Copyright (C) 2024 BobbyUnknown
#
# Description:
# This software provides a tunneling application for OpenWrt using Mihomo core.
# The application allows users to configure and manage proxy rules, connections,
# and network traffic routing through a user-friendly web interface, enabling
# advanced networking capabilities and traffic control on OpenWrt routers.

CONFIG_FILE="/etc/insomclash/profile/config.yaml"
PROXY_DIR="/etc/insomclash/run/proxy"
RULE_DIR="/etc/insomclash/run/rule"
GEO_DIR="/etc/insomclash/run"

case "$1" in
  get)
    cat "$CONFIG_FILE"
    ;;
  set)
    echo "$2" > "$CONFIG_FILE"
    ;;
  get_proxy)
    cat "$PROXY_DIR/$2"
    ;;
  set_proxy)
    echo "$3" > "$PROXY_DIR/$2"
    ;;
  list_proxy)
    ls -1 "$PROXY_DIR"
    ;;
  upload_proxy)
    echo "Attempting to upload proxy: $2" >&2
    if [ ! -d "$PROXY_DIR" ]; then
      mkdir -p "$PROXY_DIR"
    fi
    echo "$3" > "$PROXY_DIR/$2"
    if [ $? -eq 0 ]; then
      chmod 644 "$PROXY_DIR/$2"
      echo "Proxy uploaded successfully" >&2
      exit 0
    else
      echo "Failed to save proxy file" >&2
      exit 1
    fi
    ;;
  list_rule)
    ls -1 "$RULE_DIR"
    ;;
  upload_rule)
    echo "Attempting to upload rule: $2" >&2
    if [ ! -d "$RULE_DIR" ]; then
      mkdir -p "$RULE_DIR"
    fi
    echo "$3" > "$RULE_DIR/$2"
    if [ $? -eq 0 ]; then
      chmod 644 "$RULE_DIR/$2"
      echo "Rule uploaded successfully" >&2
      exit 0
    else
      echo "Failed to save rule file" >&2
      exit 1
    fi
    ;;
  list_geo)
    ls -1 "$GEO_DIR" | grep -E '\.(dat|db|mmdb)$'
    ;;
  upload_geo)
    echo "Attempting to upload geo: $2" >&2
    if [ ! -d "$GEO_DIR" ]; then
      mkdir -p "$GEO_DIR"
    fi
    echo "$3" > "$GEO_DIR/$2"
    if [ $? -eq 0 ]; then
      chmod 644 "$GEO_DIR/$2"
      echo "Geo uploaded successfully" >&2
      exit 0
    else
      echo "Failed to save geo file" >&2
      exit 1
    fi
    ;;
  delete_rule)
    if [ -f "$RULE_DIR/$2" ]; then
      rm "$RULE_DIR/$2"
      if [ $? -eq 0 ]; then
        echo "Rule deleted successfully" >&2
        exit 0
      else
        echo "Failed to delete rule" >&2
        exit 1
      fi
    else
      echo "Rule file not found" >&2
      exit 1
    fi
    ;;
  delete_geo)
    if [ -f "$GEO_DIR/$2" ]; then
      rm "$GEO_DIR/$2"
      if [ $? -eq 0 ]; then
        echo "Geo deleted successfully" >&2
        exit 0
      else
        echo "Failed to delete geo" >&2
        exit 1
      fi
    else
      echo "Geo file not found" >&2
      exit 1
    fi
    ;;
esac
