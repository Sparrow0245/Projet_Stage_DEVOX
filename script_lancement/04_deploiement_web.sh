#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Déploiement interface Web Sentinelle
###############################################################################

set -euo pipefail


echo "==============================================================="
echo " Déploiement interface Web Sentinelle"
echo "==============================================================="


###############################################################################
# Variables
###############################################################################

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"


SOURCE_WEB="${BASE_DIR}/monitoring/web"

WEB_ROOT="/var/www/html/sentinelle"



###############################################################################
# Vérification root
###############################################################################

if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Ce script doit être exécuté avec sudo."
    exit 1
fi



###############################################################################
# Vérification source web
###############################################################################

echo "[INFO] Vérification dossier web"


if [[ ! -d "${SOURCE_WEB}" ]]; then

    echo "[ERREUR] Dossier web introuvable : ${SOURCE_WEB}"
    exit 1

fi



###############################################################################
# Création répertoire Apache
###############################################################################

echo
echo "[1/5] Création répertoire web"


mkdir -p "${WEB_ROOT}"



###############################################################################
# Sauvegarde ancienne installation
###############################################################################

if [[ -d "${WEB_ROOT}" ]] && [[ "$(ls -A ${WEB_ROOT})" ]]; then

    echo "[INFO] Sauvegarde ancienne version"


    BACKUP="/var/backups/sentinelle_web_$(date +%Y%m%d_%H%M%S)"


    mkdir -p /var/backups


    cp -r "${WEB_ROOT}" "${BACKUP}"


    echo "[OK] Sauvegarde créée : ${BACKUP}"

fi



###############################################################################
# Copie fichiers
###############################################################################

echo
echo "[2/5] Copie fichiers interface"


cp -r \
"${SOURCE_WEB}/"* \
"${WEB_ROOT}/"



###############################################################################
# Permissions
###############################################################################

echo
echo "[3/5] Configuration permissions"


chown -R www-data:www-data "${WEB_ROOT}"


find "${WEB_ROOT}" -type d -exec chmod 755 {} \;


find "${WEB_ROOT}" -type f -exec chmod 644 {} \;



###############################################################################
# Vérification fichiers principaux
###############################################################################

echo
echo "[4/5] Vérification fichiers"



FILES_REQUIRED=(

"index.php"

"historique.php"

"api/metrics.php"

"api/events.php"

"config/database.php"

"assets/css/style.css"

"assets/js/dashboard.js"

)



for FILE in "${FILES_REQUIRED[@]}"
do

    if [[ -f "${WEB_ROOT}/${FILE}" ]]
    then

        echo "[OK] ${FILE}"

    else

        echo "[ERREUR] Fichier manquant : ${FILE}"
        exit 1

    fi

done



###############################################################################
# Préparation PHP
###############################################################################

echo
echo "[5/5] Vérification PHP"


php -v > /dev/null



systemctl reload apache2 || true



echo
echo "==============================================================="
echo " Interface Web installée"
echo " Chemin : ${WEB_ROOT}"
echo "==============================================================="
