#!/bin/bash
# Outil d'administration : consulter, bannir ou débannir manuellement.
# Usage : sentinelle-ctl.sh {status|ban <ip>|unban <ip>}

BASE="/opt/sentinelle"
export BASE

source "$BASE/config/sentinelle.conf"
source "$BASE/lib/log.sh"
source "$BASE/lib/lock.sh"
source "$BASE/lib/whitelist.sh"
source "$BASE/lib/ban.sh"

case "$1" in
    status)
        echo "IP actuellement bannies (ip;timestamp_ban;jail) :"
        if [ -s "$BASE_BAN" ]; then
            column -t -s ";" "$BASE_BAN"
        else
            echo "Aucune"
        fi
        ;;
    ban)
        [ -z "$2" ] && { echo "Usage: $0 ban <ip>"; exit 1; }
        ban_ip "$2" "manuel"
        echo "IP $2 bannie."
        ;;
    unban)
        [ -z "$2" ] && { echo "Usage: $0 unban <ip>"; exit 1; }
        unban_ip "$2"
        echo "IP $2 débannie."
        ;;
    *)
        echo "Usage: $0 {status|ban <ip>|unban <ip>}"
        exit 1
        ;;
esac
