#!/bin/bash

#################################################
# Création de l'arborescence Sentinelle Monitoring
#################################################

set -e

BASE_DIR="$(pwd)"

echo "=============================================="
echo " Création de l'arborescence Monitoring"
echo " Emplacement : $BASE_DIR"
echo "=============================================="


#############################################
# Dossiers principaux du projet
#############################################

echo "[+] Création des dossiers principaux"


mkdir -p api
mkdir -p dashboard
mkdir -p assets/css
mkdir -p assets/js
mkdir -p database
mkdir -p scripts
mkdir -p services
mkdir -p config
mkdir -p logs
mkdir -p tests
mkdir -p documentation


#############################################
# Dossier déploiement
#############################################

echo "[+] Création du dossier déploiement"


mkdir -p deploiement/scripts
mkdir -p deploiement/logs



#############################################
# Fichiers de déploiement
#############################################

echo "[+] Création des scripts de déploiement"


touch deploiement/mise_en_place.sh

touch deploiement/scripts/01_dependances.sh
touch deploiement/scripts/02_arborescence.sh
touch deploiement/scripts/03_base_donnees.sh
touch deploiement/scripts/04_configuration.sh
touch deploiement/scripts/05_scripts_monitoring.sh
touch deploiement/scripts/06_api_web.sh
touch deploiement/scripts/07_dashboard.sh
touch deploiement/scripts/08_services_systemd.sh
touch deploiement/scripts/09_apache.sh
touch deploiement/scripts/10_permissions.sh
touch deploiement/scripts/11_tests.sh



#############################################
# Fichiers application
#############################################

echo "[+] Création des fichiers application"


# Configuration

touch config/sentinelle.conf


# Base de données

touch database/sentinelle.sql


# API PHP

touch api/config.php
touch api/database.php
touch api/login.php
touch api/logout.php
touch api/metrics.php
touch api/alerts.php



# Dashboard

touch dashboard/index.php
touch dashboard/login.php
touch dashboard/logout.php



# CSS / JS

touch assets/css/style.css
touch assets/js/dashboard.js



# Scripts monitoring

touch scripts/monitoring.sh
touch scripts/analyse_logs.sh
touch scripts/alertes.sh
touch scripts/nettoyage.sh



# Services

touch services/sentinelle.service
touch services/sentinelle.timer



#############################################
# Documentation
#############################################

echo "[+] Création documentation"


touch README.md
touch documentation/installation.md
touch documentation/utilisation.md
touch documentation/architecture.md



#############################################
# Tests

echo "[+] Création tests"


touch tests/test_bdd.sh
touch tests/test_monitoring.sh
touch tests/test_api.sh



#############################################
# Permissions initiales
#############################################

chmod +x deploiement/mise_en_place.sh
chmod +x deploiement/scripts/*.sh

chmod +x scripts/*.sh
chmod +x tests/*.sh



echo ""
echo "=============================================="
echo " Arborescence créée avec succès"
echo "=============================================="
