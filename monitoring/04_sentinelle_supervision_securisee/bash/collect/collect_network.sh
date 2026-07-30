#!/bin/bash
###############################################################################
# Sentinelle V4 - Collecte Trafic Réseau (RX / TX)
# Emplacement : monitoring/04_sentinelle_supervision_securisee/bash/collect/collect_network.sh
###############################################################################
set -euo pipefail

DB_CNF="/etc/mysql/sentinelle.cnf"

NET_DEV=$(ip route | grep default | awk '{print $5}' | head -n 1)
IFACE=${NET_DEV:-lo}

NET_RX=$(cat /sys/class/net/"${IFACE}"/statistics/rx_bytes 2>/dev/null || echo 0)
NET_TX=$(cat /sys/class/net/"${IFACE}"/statistics/tx_bytes 2>/dev/null || echo 0)

NET_RX_KB=$((NET_RX / 1024))
NET_TX_KB=$((NET_TX / 1024))

mysql --defaults-extra-file="${DB_CNF}" sentinelle -e \
"INSERT INTO metrics (host_id, cpu_usage, ram_usage, disk_usage, swap_usage, network_rx_kb, network_tx_kb) \
VALUES (1, 0, 0, 0, 0, ${NET_RX_KB}, ${NET_TX_KB});"
