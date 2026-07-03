#!/bin/bash
# CORRIGÉ : l'original était un no-op ("true", aucun effet). Sans lui actif
# en tâche de fond, les fonctions unban_ip/unban_expires de gestion_ban.sh
# ne sont jamais appelées et un ban devient définitif de fait.

BASE="/opt/sentinelle"
source $BASE/config/sentinelle.conf
source $BASE/response/gestion_ban.sh

while true; do
    unban_expires
    sleep 60
done
