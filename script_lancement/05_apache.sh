#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Script 05 - Configuration et activation d'Apache2 pour Sentinelle V4
###############################################################################

set -euo pipefail

echo "==============================================================="
echo " [05/09] Configuration du serveur Web Apache2"
echo "==============================================================="

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APACHE_CONF_SRC="${BASE_DIR}/monitoring/04_sentinelle_supervision_securisee/config/sentinelle.conf"
APACHE_DEST="/etc/apache2/conf-available/sentinelle.conf"

if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Ce script doit être exécuté avec sudo."
    exit 1
fi

# 1. Copie du fichier de configuration Apache
echo "[1/3] Déploiement de sentinelle.conf vers Apache..."
if [[ -f "${APACHE_CONF_SRC}" ]]; then
    cp "${APACHE_CONF_SRC}" "${APACHE_DEST}"
    echo "[OK] Fichier copié vers ${APACHE_DEST}"
else
    echo "[ERREUR] Configuration Apache introuvable : ${APACHE_CONF_SRC}"
    exit 1
fi

# 2. Activation des modules et de la configuration
echo "[2/3] Activation des modules Apache (headers, rewrite, alias)..."
a2enmod headers rewrite alias &>/dev/null || true
a2enconf sentinelle &>/dev/null || true

# 3. Validation et rechargement
echo "[3/3] Test de syntaxe Apache et rechargement..."
if apache2ctl configtest &>/dev/null; then
    systemctl reload apache2
    echo "[OK] Apache2 rechargé avec succès."
else
    echo "[ERREUR] Erreur de syntaxe dans la configuration Apache !"
    exit 1
fi

echo "==============================================================="
echo " Serveur Web Apache2 configuré avec succès !"
echo "==============================================================="
