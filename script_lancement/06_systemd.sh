#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Installation des services systemd Sentinelle
###############################################################################

set -euo pipefail


echo "==============================================================="
echo " Installation services systemd Sentinelle"
echo "==============================================================="


###############################################################################
# Variables
###############################################################################

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"


SYSTEMD_DIR="/etc/systemd/system"


SOURCE_SENTINELLE="${BASE_DIR}/monitoring/03_sentinelle_unifiee_multijails_corrigee/systemd"

SOURCE_COLLECTOR="${BASE_DIR}/monitoring/systemd"



###############################################################################
# Vérification root
###############################################################################

if [[ $EUID -ne 0 ]]; then

    echo "[ERREUR] Ce script doit être exécuté avec sudo."

    exit 1

fi



###############################################################################
# Vérification systemd
###############################################################################

echo "[INFO] Vérification systemd"



if ! command -v systemctl >/dev/null 2>&1
then

    echo "[ERREUR] systemd introuvable."

    exit 1

fi



###############################################################################
# Copie service Sentinelle
###############################################################################

echo
echo "[1/5] Installation service Sentinelle"



if [[ -f "${SOURCE_SENTINELLE}/sentinelle.service" ]]
then

    cp \
    "${SOURCE_SENTINELLE}/sentinelle.service" \
    "${SYSTEMD_DIR}/sentinelle.service"

    echo "[OK] sentinelle.service installé"

else

    echo "[ERREUR] sentinelle.service introuvable"

    exit 1

fi



###############################################################################
# Copie service collecteur
###############################################################################

echo
echo "[2/5] Installation collecteur métriques"



if [[ -f "${SOURCE_COLLECTOR}/sentinelle-collector.service" ]]
then

    cp \
    "${SOURCE_COLLECTOR}/sentinelle-collector.service" \
    "${SYSTEMD_DIR}/sentinelle-collector.service"


    echo "[OK] sentinelle-collector.service installé"

else

    echo "[ERREUR] Service collecteur absent"

    exit 1

fi



if [[ -f "${SOURCE_COLLECTOR}/sentinelle-collector.timer" ]]
then

    cp \
    "${SOURCE_COLLECTOR}/sentinelle-collector.timer" \
    "${SYSTEMD_DIR}/sentinelle-collector.timer"


    echo "[OK] sentinelle-collector.timer installé"

else

    echo "[ERREUR] Timer collecteur absent"

    exit 1

fi



###############################################################################
# Logrotate
###############################################################################

echo
echo "[3/5] Installation logrotate"



if [[ -f "${SOURCE_SENTINELLE}/sentinelle.logrotate" ]]
then

    cp \
    "${SOURCE_SENTINELLE}/sentinelle.logrotate" \
    "/etc/logrotate.d/sentinelle"


    echo "[OK] Configuration logrotate installée"

else

    echo "[INFO] Pas de fichier logrotate"

fi



###############################################################################
# Rechargement systemd
###############################################################################

echo
echo "[4/5] Rechargement systemd"



systemctl daemon-reload



###############################################################################
# Activation services
###############################################################################

echo
echo "[5/5] Activation services"



systemctl enable sentinelle.service


systemctl enable sentinelle-collector.timer



systemctl restart sentinelle.service || true


systemctl restart sentinelle-collector.timer || true



###############################################################################
# Vérifications
###############################################################################

echo
echo "Vérification état services"



SERVICES=(

"sentinelle.service"

"sentinelle-collector.timer"

)



for SERVICE in "${SERVICES[@]}"
do

    if systemctl is-enabled --quiet "${SERVICE}"
    then

        echo "[OK] ${SERVICE} activé"

    else

        echo "[ERREUR] ${SERVICE} non activé"

        exit 1

    fi

done



echo
echo "==============================================================="
echo " Services systemd installés"
echo "==============================================================="
