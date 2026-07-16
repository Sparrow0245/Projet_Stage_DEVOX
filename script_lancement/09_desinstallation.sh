#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Désinstallation complète de Sentinelle
###############################################################################

set -euo pipefail


echo "==============================================================="
echo " Désinstallation Sentinelle"
echo "==============================================================="


###############################################################################
# Variables
###############################################################################

SENTINELLE_DIR="/opt/sentinelle"

WEB_ROOT="/var/www/html/sentinelle"

SYSTEMD_DIR="/etc/systemd/system"

VHOST_NAME="sentinelle.conf"

VHOST_PATH="/etc/apache2/sites-available/${VHOST_NAME}"

DOMAIN="sentinelle.local"

DB_NAME="sentinelle"
DB_USER="sentinelle"
DB_PASSWORD="serveur"

PURGE_PACKAGES=0

for ARG in "$@"
do
    if [[ "${ARG}" == "--purge-packages" ]]; then
        PURGE_PACKAGES=1
    fi
done



###############################################################################
# Vérification root
###############################################################################

if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Ce script doit être exécuté avec sudo."
    exit 1
fi



###############################################################################
# Confirmation
###############################################################################

echo
echo "Ce script va supprimer :"
echo "  • Services systemd sentinelle / sentinelle-collector"
echo "  • VirtualHost Apache et entrée /etc/hosts (${DOMAIN})"
echo "  • Répertoire web ${WEB_ROOT}"
echo "  • Répertoire moteur ${SENTINELLE_DIR}"
echo "  • Base de données et utilisateur MySQL '${DB_NAME}'"

if [[ ${PURGE_PACKAGES} -eq 1 ]]; then
    echo "  • Paquets apache2, mariadb-server, php (--purge-packages activé)"
fi

echo
read -r -p "Confirmer la désinstallation ? (taper OUI) : " CONFIRM

if [[ "${CONFIRM}" != "OUI" ]]; then
    echo "[INFO] Désinstallation annulée."
    exit 0
fi



###############################################################################
# Arrêt et suppression des services systemd
###############################################################################

echo
echo "[1/7] Arrêt et suppression des services systemd"


SERVICES=(
    "sentinelle.service"
    "sentinelle-collector.timer"
    "sentinelle-collector.service"
)

for SERVICE in "${SERVICES[@]}"
do

    if systemctl list-unit-files | grep -q "^${SERVICE}"
    then

        systemctl stop "${SERVICE}" 2>/dev/null || true

        systemctl disable "${SERVICE}" 2>/dev/null || true

        echo "[OK] ${SERVICE} arrêté et désactivé"

    fi

done


for FILE in \
    "${SYSTEMD_DIR}/sentinelle.service" \
    "${SYSTEMD_DIR}/sentinelle-collector.service" \
    "${SYSTEMD_DIR}/sentinelle-collector.timer"
do

    if [[ -f "${FILE}" ]]; then

        rm -f "${FILE}"

        echo "[OK] Supprimé : ${FILE}"

    fi

done


if [[ -f "/etc/logrotate.d/sentinelle" ]]; then

    rm -f "/etc/logrotate.d/sentinelle"

    echo "[OK] Configuration logrotate supprimée"

fi


systemctl daemon-reload



###############################################################################
# Suppression VirtualHost Apache
###############################################################################

echo
echo "[2/7] Suppression configuration Apache"


if command -v a2dissite >/dev/null 2>&1 && [[ -f "/etc/apache2/sites-enabled/${VHOST_NAME}" ]]
then

    a2dissite "${VHOST_NAME}" >/dev/null 2>&1 || true

    echo "[OK] Site ${VHOST_NAME} désactivé"

fi


if [[ -f "${VHOST_PATH}" ]]; then

    rm -f "${VHOST_PATH}"

    echo "[OK] Supprimé : ${VHOST_PATH}"

fi


if command -v apache2ctl >/dev/null 2>&1; then

    if [[ -f "/etc/apache2/sites-available/000-default.conf" ]] && \
       [[ ! -e "/etc/apache2/sites-enabled/000-default.conf" ]]
    then

        a2ensite 000-default.conf >/dev/null 2>&1 || true

        echo "[INFO] Site par défaut réactivé"

    fi

    apache2ctl configtest 2>/dev/null && systemctl restart apache2 || true

fi



###############################################################################
# Suppression entrée /etc/hosts
###############################################################################

echo
echo "[3/7] Nettoyage /etc/hosts"


if grep -q "${DOMAIN}" /etc/hosts; then

    sed -i "/${DOMAIN}/d" /etc/hosts

    echo "[OK] Entrée ${DOMAIN} supprimée"

else

    echo "[INFO] Aucune entrée ${DOMAIN} trouvée"

fi



###############################################################################
# Suppression répertoire Web
###############################################################################

echo
echo "[4/7] Suppression interface Web"


if [[ -d "${WEB_ROOT}" ]]; then

    rm -rf "${WEB_ROOT}"

    echo "[OK] Supprimé : ${WEB_ROOT}"

else

    echo "[INFO] ${WEB_ROOT} déjà absent"

fi



###############################################################################
# Suppression moteur Sentinelle
###############################################################################

echo
echo "[5/7] Suppression moteur Sentinelle"


if [[ -d "${SENTINELLE_DIR}" ]]; then

    rm -rf "${SENTINELLE_DIR}"

    echo "[OK] Supprimé : ${SENTINELLE_DIR}"

else

    echo "[INFO] ${SENTINELLE_DIR} déjà absent"

fi



###############################################################################
# Suppression base de données
###############################################################################

echo
echo "[6/7] Suppression base de données MySQL"


if systemctl is-active --quiet mariadb 2>/dev/null; then

    mysql <<EOF

DROP DATABASE IF EXISTS ${DB_NAME};

DROP USER IF EXISTS '${DB_USER}'@'localhost';

FLUSH PRIVILEGES;

EOF

    echo "[OK] Base '${DB_NAME}' et utilisateur '${DB_USER}' supprimés"

else

    echo "[INFO] MariaDB non actif, étape ignorée"

fi



###############################################################################
# Purge optionnelle des paquets système
###############################################################################

echo
echo "[7/7] Paquets système"


if [[ ${PURGE_PACKAGES} -eq 1 ]]; then

    apt purge -y apache2 mariadb-server mariadb-client php php-cli php-common php-mysql php-curl php-json php-mbstring php-xml

    apt autoremove -y

    echo "[OK] Paquets système purgés"

else

    echo "[INFO] Paquets système conservés (utiliser --purge-packages pour les supprimer)"

fi


echo
echo "==============================================================="
echo " Désinstallation Sentinelle terminée"
echo "==============================================================="
