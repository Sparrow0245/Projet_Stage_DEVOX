#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../utils/logger.sh"
source "$DIR/../utils/mysql.sh"

df -BG | grep -E '^/dev/' | while read -r line; do
    MOUNT=$(echo "$line" | awk '{print $6}')
    TOTAL=$(echo "$line" | awk '{print $2}' | tr -d 'G')
    USED=$(echo "$line" | awk '{print $3}' | tr -d 'G')
    FREE=$(echo "$line" | awk '{print $4}' | tr -d 'G')
    PCT=$(echo "$line" | awk '{print $5}' | tr -d '%')
    execute_sql "INSERT INTO sentinelle.metrics_disk (mount_point, total_gb, used_gb, free_gb, usage_percent) VALUES ('$MOUNT', $TOTAL, $USED, $FREE, $PCT);"
done
