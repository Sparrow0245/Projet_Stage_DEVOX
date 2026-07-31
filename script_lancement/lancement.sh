#!/bin/bash

###############################################################################
# Projet Stage DEVOX - Script Maître de Déploiement
# Exécute la chaîne complète des scripts 01 à 08 + Amorce métriques
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# On définit la racine du projet par rapport à l'emplacement de ce script.
PROJECT_DIR="${SCRIPT_DIR}"

echo "==============================================================="
echo "   DÉPLOIEMENT AUTOMATISÉ - PLATAFORME SENTINELLE V4          "
echo "==============================================================="

if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Le script de lancement doit être exécuté avec sudo."
    exit 1
fi

SCRIPTS=(
    "01_dependances.sh"
    "02_mysql.sh"
    "03_deploiement_backend.sh"
    "04_deploiement_frontend.sh"
    "05_apache.sh"
    "06_systemd.sh"
    "07_permissions.sh"
    "08_tests.sh"
)

for script in "${SCRIPTS[@]}"; do
    SCRIPT_PATH="${SCRIPT_DIR}/${script}"
    if [[ -f "${SCRIPT_PATH}" ]]; then
        echo -e "\n>>> Execution de ${script}..."
        bash "${SCRIPT_PATH}"
    else
        echo -e "\n[ERREUR] Script manquant : ${script}"
        exit 1
    fi
done

echo -e "\n>>> Configuration de la tâche Cron pour la collecte des métriques..."
# Chemin vers le script d'enregistrement des métriques
METRICS_SCRIPT="${PROJECT_DIR}/monitoring/scripts/enregistrer_metrics.sh"

if [[ -f "${METRICS_SCRIPT}" ]]; then
    chmod +x "${METRICS_SCRIPT}"
    CAT_CRON="/etc/cron.d/sentinelle_cron"
    
    # Création du cron job (1 exécution par minute)
    echo "* * * * * root /bin/bash ${METRICS_SCRIPT} >/dev/null 2>&1" > "${CAT_CRON}"
    chmod 644 "${CAT_CRON}"
    
    # Redémarrage du service cron pour prendre en compte la nouvelle tâche
    systemctl restart cron
    echo "[SUCCÈS] Tâche Cron configurée (/etc/cron.d/sentinelle_cron)."

    # Amorce immédiate des métriques pour alimenter le dashboard dès le premier lancement
    echo ">>> Amorce immédiate de la collecte des métriques..."
    /bin/bash "${METRICS_SCRIPT}" || true
    echo "[SUCCÈS] Premier jeu de métriques inséré."
else
    echo "[ATTENTION] Le script ${METRICS_SCRIPT} est introuvable."
    echo "Vérifie le chemin dans la variable PROJECT_DIR de lancement.sh."
fi

echo -e "\n==============================================================="
echo " DÉPLOIEMENT TERMINÉ !"
echo " Interface publique : http://localhost:8080/"
echo " Console Admin     : http://localhost:8080/login.php"
echo " Identifiants Admin : admin / Admin2026! (Puis configuration A2F au 1er login)"
echo "==============================================================="
