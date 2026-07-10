#!/bin/bash

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$BASE_DIR/../config/database.conf"


DATA=$("$BASE_DIR/collect_systeme.sh")


CPU=$(echo "$DATA" | cut -d";" -f1)
RAM=$(echo "$DATA" | cut -d";" -f2)
DISK=$(echo "$DATA" | cut -d";" -f3)
LOAD=$(echo "$DATA" | cut -d";" -f4)


mysql \
-u "$DB_USER" \
-p"$DB_PASSWORD" \
"$DB_NAME" <<EOF

INSERT INTO metrics
(
cpu_usage,
ram_usage,
disk_usage,
load_average
)
VALUES
(
${CPU},
${RAM},
${DISK},
${LOAD}
);

EOF
