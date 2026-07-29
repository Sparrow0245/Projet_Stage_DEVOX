#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../utils/logger.sh"
source "$DIR/../utils/mysql.sh"

cat /proc/net/dev | tail -n +3 | while read -r line; do
    IFACE=$(echo "$line" | awk -F':' '{print $1}' | tr -d ' ')
    if [ "$IFACE" != "lo" ]; then
        RX=$(echo "$line" | awk -F':' '{print $2}' | awk '{print $1}')
        TX=$(echo "$line" | awk -F':' '{print $2}' | awk '{print $9}')
        execute_sql "INSERT INTO sentinelle.metrics_network (interface_name, rx_bytes, tx_bytes) VALUES ('$IFACE', $RX, $TX);"
    fi
done
