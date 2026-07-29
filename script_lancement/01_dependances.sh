#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Installation des dépendances système V4
###############################################################################

set -euo pipefail

echo "==============================================================="
echo " Installation des dépendances système (Java 21, Node.js, MySQL)"
echo "==============================================================="

if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Ce script doit être exécuté avec sudo."
    exit 1
fi

if [[ ! -f /etc/os-release ]]; then
    echo "[ERREUR] Impossible de déterminer le système."
    exit 1
fi

source /etc/os-release
echo "[INFO] Système détecté : ${PRETTY_NAME}"

if [[ "${ID}" != "ubuntu" ]]; then
    echo "[AVERTISSEMENT] Ce script est prévu pour Ubuntu."
fi

echo
echo "[1/6] Mise à jour des dépôts"
apt update

echo
echo "[2/6] Mise à jour du système"
apt upgrade -y

echo
echo "[3/6] Installation outils système & compilation"
apt install -y \
    curl wget git unzip nano vim net-tools lsof \
    ca-certificates software-properties-common \
    bc sysstat lm-sensors ufw apparmor qrencode jq

echo
echo "[4/6] Installation Stack Java 21 & Node.js"
apt install -y openjdk-21-jdk maven nodejs npm

echo
echo "[5/6] Installation Apache & MariaDB/MySQL"
apt install -y apache2 mariadb-server mariadb-client

systemctl enable apache2
systemctl start apache2
systemctl enable mariadb
systemctl start mariadb

echo
echo "[6/6] Vérification des services de base"
SERVICES=("apache2" "mariadb")

for SERVICE in "${SERVICES[@]}"
do
    if systemctl is-active --quiet "${SERVICE}"; then
        echo "[OK] ${SERVICE} actif"
    else
        echo "[ERREUR] ${SERVICE} non actif"
        exit 1
    fi
done

echo
echo "==============================================================="
echo " Dépendances installées avec succès"
echo "==============================================================="
