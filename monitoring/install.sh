#!/bin/bash

set -e

PROJECT_NAME="Sentinelle"

echo "=========================================="
echo " Installation de $PROJECT_NAME"
echo "=========================================="

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[1/4] Installation des dépendances"
sudo bash "$BASE_DIR/install/01_dependances.sh"

echo "[2/4] Création de l'arborescence"
sudo bash "$BASE_DIR/install/02_arborescence.sh"

echo "[3/4] Installation des services"
sudo bash "$BASE_DIR/install/03_services.sh"

echo "[4/4] Tests"
sudo bash "$BASE_DIR/install/04_tests.sh"

echo ""
echo "=========================================="
echo " Installation terminée"
echo "=========================================="
