#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Installation des dépendances système
###############################################################################

set -euo pipefail


echo "==============================================================="
echo " Installation des dépendances système"
echo "==============================================================="


###############################################################################
# Vérification utilisateur root
###############################################################################

if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Ce script doit être exécuté avec sudo."
    exit 1
fi



###############################################################################
# Vérification système
###############################################################################

if [[ ! -f /etc/os-release ]]; then
    echo "[ERREUR] Impossible de déterminer le système."
    exit 1
fi


source /etc/os-release


echo "[INFO] Système détecté : ${PRETTY_NAME}"


if [[ "${ID}" != "ubuntu" ]]; then
    echo "[AVERTISSEMENT] Ce script est prévu pour Ubuntu."
fi



###############################################################################
# Mise à jour des paquets
###############################################################################

echo
echo "[1/7] Mise à jour des dépôts"

apt update



echo
echo "[2/7] Mise à jour du système"

apt upgrade -y



###############################################################################
# Paquets de base
###############################################################################

echo
echo "[3/7] Installation outils système"


apt install -y \
    curl \
    wget \
    git \
    unzip \
    nano \
    vim \
    net-tools \
    lsof \
    ca-certificates \
    software-properties-common



###############################################################################
# Apache
###############################################################################

echo
echo "[4/7] Installation Apache"


apt install -y apache2


systemctl enable apache2

systemctl start apache2



###############################################################################
# PHP
###############################################################################

echo
echo "[5/7] Installation PHP"


apt install -y \
    php \
    php-cli \
    php-common \
    php-mysql \
    php-curl \
    php-json \
    php-mbstring \
    php-xml



php -v



###############################################################################
# MariaDB
###############################################################################

echo
echo "[6/7] Installation MariaDB"


apt install -y mariadb-server mariadb-client



systemctl enable mariadb

systemctl start mariadb



###############################################################################
# Vérifications
###############################################################################

echo
echo "[7/7] Vérification des services"



SERVICES=(
    "apache2"
    "mariadb"
)


for SERVICE in "${SERVICES[@]}"
do

    if systemctl is-active --quiet "${SERVICE}"
    then
        echo "[OK] ${SERVICE} actif"
    else
        echo "[ERREUR] ${SERVICE} non actif"
        exit 1
    fi

done



###############################################################################
# Activation sécurité MariaDB
###############################################################################

echo
echo "[INFO] Configuration minimale MariaDB"


mysql <<EOF

DELETE FROM mysql.user
WHERE User='';

FLUSH PRIVILEGES;

EOF



echo
echo "==============================================================="
echo " Dépendances installées avec succès"
echo "==============================================================="
