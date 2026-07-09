#!/bin/bash

DB_USER="sentinelle"
DB_PASS="mot_de_passe"
DB_NAME="sentinelle"


DATA=$(/opt/sentinelle/scripts/collecte_systeme.sh)


CPU=$(echo "$DATA" | cut -d";" -f1)
RAM=$(echo "$DATA" | cut -d";" -f2)
DISK=$(echo "$DATA" | cut -d";" -f3)
LOAD=$(echo "$DATA" | cut -d";" -f4)


mysql \
-u "$DB_USER" \
-p"$DB_PASS" \
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
$CPU,
$RAM,
$DISK,
$LOAD
);

EOF
