#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Script 09 - Désinstallation et nettoyage complet du projet
###############################################################################

set -euo pipefail

echo "==============================================================="
echo " [09/09] Suppression et réinitialisation de Sentinelle V4"
echo "==============================================================="

if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Ce script doit être exécuté avec sudo."
    exit 1
fi

read -p "Êtes-vous sûr de vouloir tout désinstaller (BDD, fichiers Web, services) ? (o/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Oo]$ ]]; then
    echo "Désinstallation annulée."
    exit 0
fi

# 1. Arrêt et suppression des services Systemd
echo "[1/4] Arrêt des services Systemd..."
systemctl stop sentinelle-backend.service sentinelle-monitor.service 2>/dev/null || true
systemctl disable sentinelle-backend.service sentinelle-monitor.service 2>/dev/null || true
rm -f /etc/systemd/system/sentinelle-backend.service /etc/systemd/system/sentinelle-monitor.service
systemctl daemon-reload

# 2. Suppression des fichiers Web
echo "[2/4] Nettoyage du répertoire Web /var/www/html/sentinelle..."
rm -rf /var/www/html/sentinelle

# 3. Suppression du fichier CNF MySQL
echo "[3/4] Suppression de /etc/mysql/sentinelle.cnf..."
rm -f /etc/mysql/sentinelle.cnf

# 4. Suppression de la base de données MariaDB
echo "[4/4] Suppression de la BDD et de l'utilisateur MySQL..."
mysql -e "DROP DATABASE IF EXISTS sentinelle;" 2>/dev/null || true
mysql -e "DROP USER IF EXISTS 'sentinelle'@'localhost';" 2>/dev/null || true

echo "==============================================================="
echo " Désinstallation terminée avec succès !"
echo "==============================================================="
