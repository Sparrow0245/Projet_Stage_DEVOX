#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../utils/logger.sh"
source "$DIR/../utils/mysql.sh"

USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
CORES=$(nproc)
FREQ=$(lscpu | grep "CPU MHz" | awk '{print $3}')
[ -z "$FREQ" ] && FREQ=0
LOAD=$(uptime | awk -F'load average:' '{ print $2 }')
L1=$(echo $LOAD | awk -F',' '{print $1}' | tr -d ' ')
L5=$(echo $LOAD | awk -F',' '{print $2}' | tr -d ' ')
L15=$(echo $LOAD | awk -F',' '{print $3}' | tr -d ' ')

execute_sql "INSERT INTO sentinelle.metrics_cpu (usage_percent, frequency_mhz, cores_count, load_1m, load_5m, load_15m) VALUES ($USAGE, $FREQ, $CORES, $L1, $L5, $L15);"
log_msg "INFO" "CPU Usage: $USAGE%"
