#!/bin/bash
# ===================================================
# Wrapper d'Exécution des Requêtes MariaDB / MySQL
# Emplacement GitHub : monitoring/04_sentinelle_supervision_securisee/bash/utils/mysql.sh
# ===================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/logger.sh"

execute_query() {
    local QUERY="$1"
    
    if [ ! -f "$MYSQL_CONF" ]; then
        log_error "Fichier $MYSQL_CONF introuvable pour la connexion MySQL."
        return 1
    fi

    mysql --defaults-extra-file="$MYSQL_CONF" sentinelle -e "$QUERY" 2>/dev/null
    return $?
}
