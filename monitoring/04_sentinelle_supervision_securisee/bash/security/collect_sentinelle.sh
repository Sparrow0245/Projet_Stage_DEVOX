#!/bin/bash

# Chargement de la configuration
source bash/utils/config.sh
source bash/utils/mysql.sh

# Détection des tentatives d'échec SSH
FAILED_SSH=$(journalctl -u ssh --since "5 minutes ago" | grep -c "Failed password")

if [ "$FAILED_SSH" -gt 3 ]; then
    QUERY="INSERT INTO alerts (category, message, priority, status, created_at) \
           VALUES ('SECURITY', 'Plus de 3 échecs de connexion SSH détectés', 'WARNING', 'NEW', NOW());"
    mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "$QUERY"
fi
