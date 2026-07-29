#!/usr/bin/env bash
source "$(dirname "$0")/config.sh"

log_msg() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] $message" >> "${LOG_PATH}/monitor.log"
    logger -t "sentinelle" "[$level] $message"
}
