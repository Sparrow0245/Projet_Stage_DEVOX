#!/bin/bash

#
# Nettoyage automatique des anciennes données
#

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$BASE_DIR/../config/database.conf"


mysql \
-u "$DB_USER" \
-p"$DB_PASSWORD" \
"$DB_NAME" <<EOF


DELETE FROM metrics
WHERE created_at < NOW() - INTERVAL 30 DAY;


DELETE FROM events
WHERE created_at < NOW() - INTERVAL 90 DAY;


DELETE FROM bans
WHERE created_at < NOW() - INTERVAL 180 DAY;


EOF
