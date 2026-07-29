#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../utils/logger.sh"
source "$DIR/../utils/mysql.sh"

TOTAL=$(free -m | awk '/Mem:/ {print $2}')
USED=$(free -m | awk '/Mem:/ {print $3}')
FREE=$(free -m | awk '/Mem:/ {print $4}')
CACHED=$(free -m | awk '/Mem:/ {print $6}')
SWAP_TOT=$(free -m | awk '/Swap:/ {print $2}')
SWAP_USE=$(free -m | awk '/Swap:/ {print $3}')

execute_sql "INSERT INTO sentinelle.metrics_ram (total_mb, used_mb, free_mb, cached_mb, swap_total_mb, swap_used_mb) VALUES ($TOTAL, $USED, $FREE, $CACHED, $SWAP_TOT, $SWAP_USE);"
log_msg "INFO" "RAM Used: ${USED}MB / ${TOTAL}MB"
