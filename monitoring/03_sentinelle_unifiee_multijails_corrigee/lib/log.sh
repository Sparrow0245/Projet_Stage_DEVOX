#!/bin/bash
# Journalisation centralisée avec niveaux (INFO / WARN / ERREUR)

sentinelle_log() {
    local niveau="$1"
    local message="$2"
    local ts
    ts=$(date -Iseconds)
    echo "${ts} [${niveau}] ${message}" >> "${LOG_FICHIER:-/opt/sentinelle/logs/sentinelle.log}"
}
