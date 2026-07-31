#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Script 06 - Configuration et activation des services Systemd
###############################################################################

set -euo pipefail

echo "==============================================================="
echo " [06/09] Configuration des services Systemd pour Sentinelle V4"
echo "==============================================================="

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONF_SRC="${BASE_DIR}/monitoring/04_sentinelle_supervision_securisee/config/sentinelle.cnf.example"
SERVICES_DIR="${BASE_DIR}/monitoring/04_sentinelle_supervision_securisee/systemd/services"

if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Ce script doit être exécuté avec sudo."
    exit 1
fi

# 1. Mise en place des identifiants MySQL (uniquement si le fichier n'existe pas déjà)
echo "[1/5] Vérification du fichier d'authentification /etc/mysql/sentinelle.cnf"
if [[ ! -f "/etc/mysql/sentinelle.cnf" ]] && [[ -f "${CONF_SRC}" ]]; then
    cp "${CONF_SRC}" /etc/mysql/sentinelle.cnf
    chmod 600 /etc/mysql/sentinelle.cnf
    chown root:root /etc/mysql/sentinelle.cnf
    echo "[OK] Fichier /etc/mysql/sentinelle.cnf créé depuis le modèle."
else
    echo "[OK] Fichier /etc/mysql/sentinelle.cnf déjà existant et conservé."
fi

# 2. Copie des unités de services Systemd
echo "[2/5] Copie des fichiers .service depuis systemd/services/"
if [[ -d "${SERVICES_DIR}" ]]; then
    cp "${SERVICES_DIR}/sentinelle-backend.service" /etc/systemd/system/ 2>/dev/null || true
    cp "${SERVICES_DIR}/sentinelle-monitor.service" /etc/systemd/system/ 2>/dev/null || true
    echo "[OK] Services copiés dans /etc/systemd/system/"
else
    echo "[ERREUR] Dossier introuvable : ${SERVICES_DIR}"
    exit 1
fi

# 3. Rechargement et activation des services
echo "[3/5] Activation et démarrage des services Systemd"
systemctl daemon-reload

if systemctl enable --now sentinelle-backend.service 2>/dev/null; then
    echo "[OK] Service sentinelle-backend activé."
fi

if systemctl enable --now sentinelle-monitor.service 2>/dev/null; then
    echo "[OK] Service sentinelle-monitor activé."
fi

# 4. Génération automatique du script enregistrer_metrics.sh manquant
echo "[4/5] Génération du script de collecte des métriques"
SCRIPT_DIR_1="${BASE_DIR}/script_lancement/monitoring/scripts"
SCRIPT_DIR_2="${BASE_DIR}/monitoring/scripts"

mkdir -p "${SCRIPT_DIR_1}"
mkdir -p "${SCRIPT_DIR_2}"

CREATE_METRICS_SCRIPT() {
    cat <<'EOF' > "$1"
#!/bin/bash
export LC_ALL=C

DB_USER="sentinelle"
DB_PASS="SentinelleSecurePass2026!"
DB_NAME="sentinelle"

CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}' 2>/dev/null || echo "0")
CPU_USAGE=$(echo "${CPU_USAGE}" | tr ',' '.' | awk '{printf "%.2f", $1}')

RAM_USAGE=$(free -m | awk '/Mem:/ {if ($2>0) printf "%.2f", $3/$2*100; else print 0}')
RAM_USAGE=$(echo "${RAM_USAGE}" | tr ',' '.')

DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%' | tr ',' '.')
SWAP_USAGE=$(free -m | awk '/Swap:/ {if ($2>0) printf "%.2f", $3/$2*100; else print 0}')
SWAP_USAGE=$(echo "${SWAP_USAGE}" | tr ',' '.')

CPU_USAGE=${CPU_USAGE:-0}
RAM_USAGE=${RAM_USAGE:-0}
DISK_USAGE=${DISK_USAGE:-0}
SWAP_USAGE=${SWAP_USAGE:-0}

mariadb -u"${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" -e \
"INSERT INTO metrics (cpu_usage, ram_usage, disk_usage, swap_usage) VALUES (${CPU_USAGE}, ${RAM_USAGE}, ${DISK_USAGE}, ${SWAP_USAGE});" 2>/dev/null \
|| mariadb -u root "${DB_NAME}" -e \
"INSERT INTO metrics (cpu_usage, ram_usage, disk_usage, swap_usage) VALUES (${CPU_USAGE}, ${RAM_USAGE}, ${DISK_USAGE}, ${SWAP_USAGE});"
EOF
    chmod +x "$1"
}

CREATE_METRICS_SCRIPT "${SCRIPT_DIR_1}/enregistrer_metrics.sh"
CREATE_METRICS_SCRIPT "${SCRIPT_DIR_2}/enregistrer_metrics.sh"
echo "[OK] Fichier enregistrer_metrics.sh créé."

# 5. Exécution initiale de la collecte et configuration du Cron
echo "[5/5] Première collecte et configuration du Cron"
bash "${SCRIPT_DIR_1}/enregistrer_metrics.sh" || true
(crontab -l 2>/dev/null | grep -v "enregistrer_metrics.sh" ; echo "* * * * * ${SCRIPT_DIR_1}/enregistrer_metrics.sh >/dev/null 2>&1") | crontab -
echo "[OK] Collecte initiale faite et tâche Cron activée."

echo "==============================================================="
echo " Service Systemd configuré avec succès !"
echo "==============================================================="
