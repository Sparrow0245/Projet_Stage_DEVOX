#!/bin/bash
# ===================================================
# Utilitaire de Journalisation Syslog
# Emplacement GitHub : monitoring/04_sentinelle_supervision_securisee/bash/utils/logger.sh
# ===================================================

log_info() {
    logger -t "sentinelle-v4" "[INFO] $1"
}

log_warning() {
    logger -t "sentinelle-v4" "[WARNING] $1"
}

log_error() {
    logger -t "sentinelle-v4" "[ERROR] $1"
}
