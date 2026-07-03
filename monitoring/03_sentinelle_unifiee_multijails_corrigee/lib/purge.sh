#!/bin/bash
# Purge les tentatives plus vieilles que la plus grande fenêtre configurée,
# pour éviter que les fichiers tentatives_*.db ne grossissent indéfiniment.

purger_tentatives() {
    local fenetre_max=86400 # 24h, large marge par rapport aux FENETRE_TEMPS des jails
    local now cutoff
    now=$(date +%s)
    cutoff=$((now - fenetre_max))

    local fichier
    for fichier in "${BASE}"/data/tentatives_*.db; do
        [ -f "$fichier" ] || continue
        with_lock "${fichier}.lock" bash -c "awk -v c='${cutoff}' '\$2>=c' '${fichier}' > '${fichier}.tmp' && mv '${fichier}.tmp' '${fichier}'"
    done
}
