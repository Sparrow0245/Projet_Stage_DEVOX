#!/bin/bash
# ===================================================
# Master Orchestrateur de Collecte - Sentinelle V4
# Emplacement GitHub : monitoring/04_sentinelle_supervision_securisee/bash/collector.sh
# Destination VM     : /opt/sentinelle/bash/collector.sh
# ===================================================

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Chargement des sous-modules utilitaires
source "$BASE_DIR/utils/config.sh"
source "$BASE_DIR/utils/logger.sh"
source "$BASE_DIR/utils/mysql.sh"

log_info "Début du cycle de collecte..."

# 1. Récupération des métriques système via les scripts de collect/
CPU_USAGE=$(bash "$BASE_DIR/collect/collect_cpu.sh")
RAM_USAGE=$(bash "$BASE_DIR/collect/collect_ram.sh" ram)
SWAP_USAGE=$(bash "$BASE_DIR/collect/collect_ram.sh" swap)
DISK_USAGE=$(bash "$BASE_DIR/collect/collect_disk.sh")

# 2. Insertion des métriques dans la BDD
METRICS_QUERY="INSERT INTO metrics (host_id, cpu_usage, ram_usage, disk_usage, swap_usage) VALUES (${HOST_ID}, ${CPU_USAGE}, ${RAM_USAGE}, ${DISK_USAGE}, ${SWAP_USAGE});"
execute_query "$METRICS_QUERY"

# 3. Vérification des services
SERVICES=("apache2" "mariadb" "ssh")

for SVC in "${SERVICES[@]}"; do
    STATUS=$(bash "$BASE_DIR/collect/collect_service.sh" "$SVC")
    
    # Mise à jour de l'état du service dans la table services_status
    SVC_QUERY="INSERT INTO services_status (host_id, service_name, status) VALUES (${HOST_ID}, '$SVC', '$STATUS') ON DUPLICATE KEY UPDATE status='$STATUS', updated_at=NOW();"
    execute_query "$SVC_QUERY"

    # Enregistrement d'un événement si le service est inactif
    if [ "$STATUS" != "active" ]; then
        log_warning "Le service $SVC est inactif !"
        EVENT_QUERY="INSERT INTO events (host_id, type, message) VALUES (${HOST_ID}, 'CRITICAL', 'Le service $SVC est inactif !');"
        execute_query "$EVENT_QUERY"
    fi
done

# 4. Détection des échecs SSH excessifs
FAILED_SSH=$(bash "$BASE_DIR/collect/collect_ssh.sh")
if [ "$FAILED_SSH" -gt 5 ]; then
    log_warning "Alerte Sécurité : $FAILED_SSH tentatives d'authentification SSH échouées détectées."
    SSH_EVENT_QUERY="INSERT INTO events (host_id, type, message) VALUES (${HOST_ID}, 'WARNING', 'Détection de $FAILED_SSH échecs de connexion SSH.');"
    execute_query "$SSH_EVENT_QUERY"
fi

log_info "Cycle de collecte terminé avec succès."
exit 0
