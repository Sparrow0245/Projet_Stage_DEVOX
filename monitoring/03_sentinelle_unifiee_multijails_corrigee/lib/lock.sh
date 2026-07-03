#!/bin/bash
# Exécute une fonction sous verrou exclusif flock pour éviter
# la corruption des fichiers de données en cas d'écritures concurrentes.
#
# Usage : with_lock /chemin/vers/fichier.lock nom_fonction arg1 arg2 ...

with_lock() {
    local fichier_lock="$1"
    shift
    (
        flock -x -w 5 200 || { sentinelle_log "ERREUR" "Timeout verrou ${fichier_lock}"; return 1; }
        "$@"
    ) 200>"$fichier_lock"
}
