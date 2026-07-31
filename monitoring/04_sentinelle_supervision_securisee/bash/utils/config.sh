#!/bin/bash
# ===================================================
# Chargement de la Configuration Globale
# Emplacement GitHub : monitoring/04_sentinelle_supervision_securisee/bash/utils/config.sh
# ===================================================

# Fichiers de configuration système
MYSQL_CONF="/etc/mysql/sentinelle.cnf"
THRESHOLDS_FILE="/var/www/html/sentinelle/config/thresholds.json"
ENV_FILE="/var/www/html/sentinelle/config/.env"

# Hôte par défaut dans la BDD
HOST_ID=1
