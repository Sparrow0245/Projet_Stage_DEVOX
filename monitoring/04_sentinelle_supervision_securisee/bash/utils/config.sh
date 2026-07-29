#!/usr/bin/env bash
CONFIG_FILE="/opt/sentinelle/config/sentinelle.conf"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    INSTALL_PATH="/opt/sentinelle"
    LOG_PATH="/var/log/sentinelle"
    TMP_PATH="/tmp/sentinelle"
fi
