#!/bin/bash
# Sentinelle — équivalent de Fail2Ban en Bash pur, sans dépendance tierce.

BASE="/opt/sentinelle"
export BASE

source "$BASE/config/sentinelle.conf"
source "$BASE/lib/log.sh"
source "$BASE/lib/lock.sh"
source "$BASE/lib/whitelist.sh"
source "$BASE/lib/ban.sh"
source "$BASE/lib/jail_runner.sh"
source "$BASE/lib/purge.sh"

PIDS=()

nettoyer() {
    sentinelle_log "INFO" "Arrêt de Sentinelle, fin des jails..."
    for pid in "${PIDS[@]}"; do
        kill "$pid" 2>/dev/null
    done
    exit 0
}
trap nettoyer SIGTERM SIGINT

sentinelle_log "INFO" "Démarrage de Sentinelle"
restaurer_bans

for conf in "$BASE"/config/jails.d/*.conf; do
    [ -f "$conf" ] || continue
    ( demarrer_jail "$conf" ) &
    PIDS+=($!)
    sentinelle_log "INFO" "Jail démarrée: $(basename "$conf") (pid $!)"
done

if [ ${#PIDS[@]} -eq 0 ]; then
    sentinelle_log "ERREUR" "Aucune jail active dans config/jails.d/ — arrêt"
    exit 1
fi

while true; do
    unban_expires
    purger_tentatives
    sleep "${INTERVALLE_UNBAN:-60}"
done
