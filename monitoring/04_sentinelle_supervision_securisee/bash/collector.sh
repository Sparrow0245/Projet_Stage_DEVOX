#!/bin/bash
# ===================================================
# Master Orchestrateur de Collecte Temps Réel - Sentinelle V4
# Emplacement GitHub : monitoring/04_sentinelle_supervision_securisee/bash/collector.sh
# ===================================================

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Chargement des sous-modules utilitaires
source "$BASE_DIR/utils/config.sh"
source "$BASE_DIR/utils/logger.sh"
source "$BASE_DIR/utils/mysql.sh"

log_info "Démarrage du service de collecte Sentinelle Temps Réel..."

# Valeur par défaut pour HOST_ID si non défini dans config.sh
HOST_ID=${HOST_ID:-1}

while true; do
    # 1. Récupération des métriques système via les scripts de collect/
    CPU_USAGE=$(bash "$BASE_DIR/collect/collect_cpu.sh" 2>/dev/null | tr ',' '.')
    RAM_USAGE=$(bash "$BASE_DIR/collect/collect_ram.sh" ram 2>/dev/null | tr ',' '.')
    SWAP_USAGE=$(bash "$BASE_DIR/collect/collect_ram.sh" swap 2>/dev/null | tr ',' '.')
    DISK_USAGE=$(bash "$BASE_DIR/collect/collect_disk.sh" 2>/dev/null | tr ',' '.')

    # Valeurs par défaut si retour vide
    CPU_USAGE=${CPU_USAGE:-0.00}
    RAM_USAGE=${RAM_USAGE:-0.00}
    SWAP_USAGE=${SWAP_USAGE:-0.00}
    DISK_USAGE=${DISK_USAGE:-0.00}

    # 2. Insertion des métriques dans la BDD
    METRICS_QUERY="INSERT INTO metrics (host_id, cpu_usage, ram_usage, disk_usage, swap_usage) VALUES (${HOST_ID}, ${CPU_USAGE}, ${RAM_USAGE}, ${DISK_USAGE}, ${SWAP_USAGE});"
    execute_query "$METRICS_QUERY"

    # 3. Vérification des services
    SERVICES=("apache2" "mariadb" "ssh")

    for SVC in "${SERVICES[@]}"; do
        STATUS=$(bash "$BASE_DIR/collect/collect_service.sh" "$SVC" 2>/dev/null)
        STATUS=${STATUS:-inactive}
        
        SVC_QUERY="INSERT INTO services_status (host_id, service_name, status) VALUES (${HOST_ID}, '$SVC', '$STATUS') ON DUPLICATE KEY UPDATE status='$STATUS', updated_at=NOW();"
        execute_query "$SVC_QUERY"

        if [ "$STATUS" != "active" ]; then
            log_warning "Le service $SVC est inactif !"
            EVENT_QUERY="INSERT INTO events (host_id, type, status, message) VALUES (${HOST_ID}, 'CRITICAL', 'active', 'Le service $SVC est inactif !');"
            execute_query "$EVENT_QUERY"
        fi
    done

    # 4. Détection des échecs SSH excessifs
    FAILED_SSH=$(bash "$BASE_DIR/collect/collect_ssh.sh" 2>/dev/null | tr -cd '0-9')
    FAILED_SSH=${FAILED_SSH:-0}

    if [ "$FAILED_SSH" -gt 5 ]; then
        log_warning "Alerte Sécurité : $FAILED_SSH tentatives d'authentification SSH échouées détectées."
        SSH_EVENT_QUERY="INSERT INTO events (host_id, type, status, message) VALUES (${HOST_ID}, 'WARNING', 'active', 'Détection de $FAILED_SSH échecs de connexion SSH.');"
        execute_query "$SSH_EVENT_QUERY"
    fi

    # Intervalle Temps Réel (2 secondes)
    sleep 2
done
