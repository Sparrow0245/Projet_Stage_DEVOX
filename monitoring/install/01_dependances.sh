#!/bin/bash

set -e

echo "[+] Mise à jour des paquets"

apt update

echo "[+] Installation des dépendances"

apt install -y \
bash \
coreutils \
grep \
awk \
sed \
systemd \
mysql-client

echo "[+] Dépendances installées"
