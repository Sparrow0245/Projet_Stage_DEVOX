#!/bin/bash
# ==============================================================================
# Générateur de l'arborescence de monitoring — 3 versions de Sentinelle
#
# Ce script crée, sous /home/wassim/Bureau/STAGE_DEVOX/appli/monitoring :
#   01_sentinelle_multiscripts_original     -> "Modèle Fail2Ban multi-scripts"
#                                              du document original, AVEC
#                                              corrections des bugs identifiés
#                                              (détaillées dans son README)
#   02_sentinelle_version_simple_original   -> "Version simple" du document
#                                              original, AVEC corrections des
#                                              bugs identifiés (détaillées
#                                              dans son README)
#   03_sentinelle_unifiee_multijails_corrigee -> version corrigée livrée
#                                              précédemment (whitelist CIDR,
#                                              flock, persistance des bans,
#                                              systemd, logrotate)
#
# NOTE DE TRANSPARENCE :
# Le document original ne précisait pas dans quel sous-dossier
# (core/detection/response/security/performance/reporting/system) chaque
# script devait être placé. Le rangement ci-dessous est une interprétation
# basée sur le nom et le rôle de chaque script, PAS une donnée tirée du
# document source. Les dossiers performance/ et reporting/ restent vides,
# comme dans le document original (aucun script n'y était associé).
# ==============================================================================

set -e

MONITORING="/home/wassim/Bureau/STAGE_DEVOX/appli/monitoring"
mkdir -p "$MONITORING"

# ==============================================================================
# VERSION 1 — Modèle multi-scripts (reproduction exacte du document original)
# ==============================================================================
V1="$MONITORING/01_sentinelle_multiscripts_original"
mkdir -p "$V1"/opt_sentinelle/{core,detection,response,security,performance,reporting,system,config,data,logs}

cat > "$V1/README_rangement.md" << 'EOF'
# Note sur le rangement des fichiers - Version 1

Le document source (Proposition_1_de_solutions_de_monitoring_avancees.md)
donnait l'arborescence suivante :

    /opt/sentinelle/
    ├── core/
    ├── detection/
    ├── response/
    ├── security/
    ├── performance/
    ├── reporting/
    ├── system/
    ├── config/
    ├── data/
    ├── logs/

...mais ne précisait PAS explicitement dans quel sous-dossier chacun des
10 scripts numérotés devait être placé. Le rangement appliqué ici est une
interprétation d'après le nom/rôle de chaque script :

- installation.sh  -> racine (script d'installation, hors arborescence)
- sentinelle.sh     -> core/ (orchestrateur principal)
- detecteur.sh      -> detection/
- correlation.sh    -> detection/
- gestion_ban.sh    -> response/
- notification.sh   -> system/
- whitelist.sh      -> security/
- log.sh            -> system/
- scheduler.sh      -> system/
- quarantaine.sh    -> response/

Les dossiers performance/ et reporting/ restent vides : le document
original ne leur associait aucun script.

## Corrections apportées et raisonnement

1. core/sentinelle.sh — relisait tout /var/log/auth.log à chaque itération
   (toutes les 2s), ce qui recomptait indéfiniment les mêmes vieilles lignes
   -> correction : passage en lecture en flux (tail -Fn0), une ligne traitée
   une seule fois.

2. detection/correlation.sh — comptait les occurrences dans data/events.log,
   fichier que rien n'écrivait dans le script original -> le score restait
   toujours à 0 et aucun ban ne pouvait jamais se déclencher.
   Correction : sentinelle.sh écrit désormais chaque IP détectée dans
   events.log (avec timestamp), et correlation.sh calcule un score sur une
   fenêtre glissante (FENETRE_TEMPS) au lieu de compter sur toute la durée
   de vie du fichier.

3. Seuil de déclenchement — le script original comparait un score à 80,
   mais un score = nombre brut de tentatives (donc il aurait fallu 81
   échecs avant tout ban : beaucoup trop permissif pour du brute-force).
   Correction : score = nombre de tentatives dans la fenêtre * 20, avec
   SEUIL_SCORE=80 -> déclenchement après MAX_TENTATIVES=5 échecs par
   défaut (paramétrable dans config/sentinelle.conf, fichier ajouté car
   absent de l'original).

4. security/whitelist.sh — utilisait "grep -q" (correspondance partielle :
   "192.168.0.1" whitelistait aussi "192.168.0.100") -> correction :
   "grep -qxF" (correspondance exacte de ligne entière).

5. response/gestion_ban.sh — n'enregistrait pas de timestamp de ban et
   pouvait dupliquer une règle iptables si appelée deux fois pour la même
   IP -> correction : vérification d'idempotence + timestamp ajouté au
   format "ip;timestamp" (nécessaire pour permettre l'expiration).
   Une fonction unban_ip() et unban_expires() ont été ajoutées : sans elles,
   aucune IP bannie ne pouvait jamais être débannie automatiquement.

6. system/scheduler.sh — était un script vide (juste "true", aucun effet)
   -> correction : boucle appelant unban_expires() toutes les 60s. Sans ce
   script actif en tâche de fond, les corrections du point 5 restent sans
   effet (le ban ne serait jamais levé).

7. response/quarantaine.sh — ajout d'une vérification d'idempotence
   (évite d'empiler des règles iptables identiques à chaque appel).

## Non modifiés

- installation.sh (complété uniquement pour créer config/sentinelle.conf)
- system/notification.sh, system/log.sh, detection/detecteur.sh :
  aucun bug identifié, laissés tels quels.

## Point non vérifiable par moi

Je n'ai pas de moyen de savoir si l'intention originale de "correlation.sh"
était de combiner plusieurs signaux (pas seulement un compteur d'échecs) —
le document ne le précise pas. Je ne peux donc pas affirmer que le calcul
de score corrigé ci-dessus correspond à une intention initiale plus riche ;
je corrige seulement le fait que le score original ne pouvait jamais
dépasser 0 dans la pratique.
EOF

cat > "$V1/opt_sentinelle/installation.sh" << 'EOF'
#!/bin/bash

BASE="/opt/sentinelle"

mkdir -p $BASE/{core,detection,response,security,performance,reporting,system,config,data,logs}

touch $BASE/data/{events.log,alerts.log,ip_reputation.db,timeline.db,tentatives.db,bannis.db,etat.db,scores.db}

echo "127.0.0.1" > $BASE/config/liste_blanche.conf

cat > $BASE/config/sentinelle.conf << 'CONF'
MAX_TENTATIVES=5
FENETRE_TEMPS=600
DUREE_BAN=3600
SEUIL_SCORE=80
CONF

chown -R root:root $BASE
chmod -R 750 $BASE
EOF

cat > "$V1/opt_sentinelle/core/sentinelle.sh" << 'EOF'
#!/bin/bash
# CORRIGÉ : l'original relisait tout le journal à chaque itération (cat +
# boucle toutes les 2s), recomptant indéfiniment les mêmes lignes.
# Passage en lecture en flux (tail -Fn0) : chaque ligne n'est traitée
# qu'une seule fois, au moment où elle est écrite dans le journal.

BASE="/opt/sentinelle"

source $BASE/config/sentinelle.conf
source $BASE/detection/detecteur.sh
source $BASE/detection/correlation.sh
source $BASE/response/gestion_ban.sh
source $BASE/security/whitelist.sh

tail -Fn0 /var/log/auth.log | while read -r ligne; do
    ip=$(detecter_ips "$ligne")
    [ -z "$ip" ] && continue

    is_whitelisted "$ip" && continue

    # CORRIGÉ : l'original ne remplissait jamais events.log, donc
    # correlation.sh comptait toujours 0. On journalise ici chaque
    # détection avec un timestamp pour permettre un comptage réel.
    echo "$(date +%s) $ip" >> $BASE/data/events.log

    score=$(correlate "$ip" | cut -d':' -f2)

    if (( score > SEUIL_SCORE )); then
        ban_ip "$ip"
    fi
done
EOF

cat > "$V1/opt_sentinelle/detection/detecteur.sh" << 'EOF'
detecter_ips() {
    echo "$1" | grep -E "Failed password|Invalid user" \
    | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}"
}
EOF

cat > "$V1/opt_sentinelle/detection/correlation.sh" << 'EOF'
# CORRIGÉ : l'original comptait sur toute la durée de vie d'events.log
# (jamais réinitialisé) et retournait un compte brut comparé à un seuil
# de 80 dans sentinelle.sh -> il aurait fallu 81 échecs avant tout ban,
# beaucoup trop permissif. Ici : comptage sur une fenêtre glissante
# (FENETRE_TEMPS) et score = tentatives * 20, pour un déclenchement à
# MAX_TENTATIVES échecs (5 par défaut) avec SEUIL_SCORE=80.
correlate() {
    ip="$1"
    now=$(date +%s)
    cutoff=$((now - FENETRE_TEMPS))
    count=$(awk -v ip="$ip" -v c="$cutoff" '$2==ip && $1>=c' /opt/sentinelle/data/events.log | wc -l)
    score=$((count * 20))
    echo "$ip:$score"
}
EOF

cat > "$V1/opt_sentinelle/response/gestion_ban.sh" << 'EOF'
# CORRIGÉ : l'original n'enregistrait ni timestamp (donc aucune expiration
# possible) ni vérification d'idempotence (une règle iptables identique
# pouvait être empilée à chaque appel pour la même IP). Ajout de
# unban_ip() et unban_expires(), absentes de l'original : sans elles,
# une IP bannie l'était définitivement, sans aucun mécanisme de levée.

ban_ip() {
    ip="$1"

    grep -q "^$ip;" /opt/sentinelle/data/bannis.db 2>/dev/null && return

    iptables -C INPUT -s "$ip" -j DROP 2>/dev/null || iptables -A INPUT -s "$ip" -j DROP

    echo "$ip;$(date +%s)" >> /opt/sentinelle/data/bannis.db
}

unban_ip() {
    ip="$1"
    iptables -D INPUT -s "$ip" -j DROP 2>/dev/null
    sed -i "/^$ip;/d" /opt/sentinelle/data/bannis.db
}

unban_expires() {
    now=$(date +%s)
    [ -f /opt/sentinelle/data/bannis.db ] || return
    while IFS=";" read -r ip ts; do
        [ -z "$ip" ] && continue
        if (( now - ts > DUREE_BAN )); then
            unban_ip "$ip"
        fi
    done < /opt/sentinelle/data/bannis.db
}
EOF

cat > "$V1/opt_sentinelle/system/notification.sh" << 'EOF'
alert() {
    logger "[SENTINELLE] ALERT $1"
}
EOF

cat > "$V1/opt_sentinelle/security/whitelist.sh" << 'EOF'
# CORRIGÉ : l'original utilisait "grep -q" (correspondance partielle) :
# "192.168.0.1" dans la whitelist matchait aussi "192.168.0.100" ou
# "10.192.168.0.5" -> faille de bypass. "grep -qxF" impose une
# correspondance exacte de la ligne entière.
is_whitelisted() {
    grep -qxF "$1" /opt/sentinelle/config/liste_blanche.conf
}
EOF

cat > "$V1/opt_sentinelle/system/log.sh" << 'EOF'
log() {
    echo "$(date) $1 $2" >> /opt/sentinelle/logs/sentinelle.log
}
EOF

cat > "$V1/opt_sentinelle/system/scheduler.sh" << 'EOF'
#!/bin/bash
# CORRIGÉ : l'original était un no-op ("true", aucun effet). Sans lui actif
# en tâche de fond, les fonctions unban_ip/unban_expires de gestion_ban.sh
# ne sont jamais appelées et un ban devient définitif de fait.

BASE="/opt/sentinelle"
source $BASE/config/sentinelle.conf
source $BASE/response/gestion_ban.sh

while true; do
    unban_expires
    sleep 60
done
EOF

cat > "$V1/opt_sentinelle/response/quarantaine.sh" << 'EOF'
# CORRIGÉ : ajout d'une vérification d'idempotence, absente de l'original,
# qui empilait une règle iptables identique à chaque appel pour la même IP.
quarantine() {
    ip="$1"
    iptables -C INPUT -s "$ip" -j DROP 2>/dev/null || iptables -I INPUT -s "$ip" -j DROP
    echo "$ip;$(date +%s)" >> /opt/sentinelle/data/bannis.db
}
EOF

echo "Version 1 (multi-scripts, originale) créée dans $V1"

# ==============================================================================
# VERSION 2 — Version simple (reproduction exacte du document original)
# ==============================================================================
V2="$MONITORING/02_sentinelle_version_simple_original"
mkdir -p "$V2/opt_sentinelle"

cat > "$V2/README_corrections.md" << 'EOF'
# Corrections apportées - Version 2

## 1. ajouter_tentative() — bug de double timestamp

Original :
    ajouter_tentative() { echo "$1 $(date +%s)" >> /tmp/tentatives.tmp; }
    ...
    ajouter_tentative "$ip $(date +%s)"

L'appel passait déjà "$ip $(date +%s)" comme argument unique, et la
fonction ajoutait un second "$(date +%s)" -> chaque ligne de
tentatives.tmp avait 3 champs (ip, timestamp1, timestamp2) au lieu de 2.
compter_tentatives() utilise ensuite "awk '$1==ip && $2>=c'", qui
comparait le timestamp1 (et non l'IP) en $1 dans certains cas et cassait
le comptage -> le seuil MAX_TENTATIVES n'était plus fiable.

Correction : l'appel devient ajouter_tentative "$ip" (la fonction
génère elle-même son timestamp, comme prévu par sa définition).

## 2. est_whitelist() — correspondance partielle au lieu d'exacte

Original : grep -q "$1" "$LISTE_BLANCHE"
-> "192.168.0.1" dans la whitelist matchait aussi "192.168.0.100" ou
"10.192.168.0.5" (n'importe quelle ligne CONTENANT la chaîne).

Correction : grep -qxF "$1" "$LISTE_BLANCHE" (correspondance
exacte de la ligne entière, pas de sous-chaîne).

## Non modifié, limite connue et assumée

unban_expired() est appelée à chaque ligne de log lue (donc à chaque
tentative de connexion SSH), pas à intervalle régulier. Ce n'est pas un
bug de correction (le résultat reste correct), juste un choix
d'implémentation qui relit tout bannis.db plus souvent que nécessaire
sur un serveur à fort trafic SSH. Je ne l'ai pas modifié car ce n'était
pas une erreur fonctionnelle, seulement un point d'efficacité — je le
signale pour rester précis sur ce qui a été corrigé et ce qui ne l'a pas
été.
EOF

cat > "$V2/opt_sentinelle/configuration.conf" << 'EOF'
FICHIER_JOURNAL="/var/log/auth.log"

MAX_TENTATIVES=5
FENETRE_TEMPS=600
DUREE_BAN=3600

BASE_BAN="/opt/sentinelle/ip_bannies.db"
LISTE_BLANCHE="/opt/sentinelle/liste_blanche.conf"
LOG="/opt/sentinelle/sentinelle.log"
EOF

cat > "$V2/opt_sentinelle/sentinelle.sh" << 'EOF'
#!/bin/bash

source ./configuration.conf

mkdir -p /opt/sentinelle
touch "$BASE_BAN" /tmp/tentatives.tmp

log() {
    echo "$(date -Iseconds) [$1] $2" >> "$LOG"
}

est_whitelist() {
    # CORRIGÉ : grep -q faisait une correspondance partielle. -qxF impose
    # une correspondance exacte de la ligne entière.
    grep -qxF "$1" "$LISTE_BLANCHE"
}

est_banni() {
    grep -q "^$1;" "$BASE_BAN"
}

ajouter_tentative() {
    echo "$1 $(date +%s)" >> /tmp/tentatives.tmp
}

compter_tentatives() {
    ip="$1"
    now=$(date +%s)
    cutoff=$((now - FENETRE_TEMPS))

    awk -v ip="$ip" -v c="$cutoff" '$1==ip && $2>=c' /tmp/tentatives.tmp | wc -l
}

ban_ip() {
    ip="$1"

    est_banni "$ip" && return

    iptables -C INPUT -s "$ip" -j DROP 2>/dev/null || \
    iptables -A INPUT -s "$ip" -j DROP

    echo "$ip;$(date +%s)" >> "$BASE_BAN"

    log "WARN" "BAN IP $ip"
}

unban_expired() {
    now=$(date +%s)

    while IFS=";" read ip time; do
        if (( now - time > DUREE_BAN )); then
            iptables -D INPUT -s "$ip" -j DROP 2>/dev/null
            sed -i "\|$ip;|d" "$BASE_BAN"
            log "INFO" "UNBAN IP $ip"
        fi
    done < "$BASE_BAN"
}

tail -Fn0 "$FICHIER_JOURNAL" | while read line; do

    ip=$(echo "$line" | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")

    [ -z "$ip" ] && continue
    est_whitelist "$ip" && continue

    # CORRIGÉ : l'original passait déjà un timestamp dans l'argument alors
    # que la fonction en ajoute un second -> lignes à 3 champs, comptage
    # cassé. On ne passe que l'IP.
    ajouter_tentative "$ip"

    if [ "$(compter_tentatives "$ip")" -ge "$MAX_TENTATIVES" ]; then
        ban_ip "$ip"
    fi

    unban_expired

done
EOF

cat > "$V2/opt_sentinelle/liste_blanche.conf" << 'EOF'
127.0.0.1
192.168.0.1
EOF

cat > "$V2/opt_sentinelle/ip_bannies.db" << 'EOF'
# format : ip;timestamp
EOF

echo "Version 2 (simple, originale) créée dans $V2"

# --- Génération Version 3 : unifiée multi-jails (corrigée) ---
V3="$MONITORING/03_sentinelle_unifiee_multijails_corrigee"
mkdir -p "$V3"/{config,config/jails.d,lib,systemd}

cat > "$V3/README.md" << 'SENTINELLE_EOF'
# Sentinelle

Équivalent de Fail2Ban en Bash pur (aucune dépendance tierce), pour la
détection et le blocage automatique des tentatives de brute-force
(SSH par défaut, extensible à d'autres services).

## Ce que ça fait

- Surveillance temps réel des journaux (tail -F)
- Détection par expression régulière, par jail (un service = une jail)
- Comptage des échecs par IP dans une fenêtre glissante
- Ban via iptables (`DROP`) + expiration automatique
- Whitelist par IP exacte ou CIDR
- Persistance des bans après redémarrage (relecture de bannis.db au démarrage,
  sans toucher au reste du pare-feu)
- Écritures concurrentes protégées par `flock`
- Service systemd + rotation des logs

## Ce que ça NE fait PAS

- **Pas de protection anti-DDoS volumétrique** (flood SYN/UDP, amplification
  DNS/NTP, etc.). Un script qui lit des logs ligne par ligne ne réagit pas
  assez vite pour ce type d'attaque. Pour ça, il faut du rate-limiting au
  niveau kernel (`iptables`/`nftables` module `limit`, `SYNPROXY`) ou une
  protection en amont (CDN, scrubbing chez l'hébergeur/opérateur).
- Pas de support IPv6 dans l'extraction d'IP (regex IPv4 uniquement à ce
  stade — à étendre si besoin).
- Pas d'action autre que le DROP iptables (pas d'email, pas de webhook) —
  à ajouter dans `lib/ban.sh` si besoin (fonction `ban_ip`).

## Installation

```bash
tar xzf sentinelle.tar.gz
cd sentinelle
sudo ./install.sh
```

Puis vérifier/adapter :
- `/opt/sentinelle/config/jails.d/ssh.conf` (chemin réel du journal —
  `/var/log/auth.log` sur Debian/Ubuntu classique)
- `/opt/sentinelle/config/liste_blanche.conf` (ajouter ton IP d'admin
  AVANT de démarrer, pour ne pas te bannir toi-même)

Démarrage :
```bash
sudo systemctl start sentinelle
sudo systemctl status sentinelle
journalctl -u sentinelle -f
```

## Administration

```bash
sentinelle-ctl status        # liste les IP bannies
sentinelle-ctl ban 1.2.3.4   # ban manuel
sentinelle-ctl unban 1.2.3.4 # unban manuel
```

## Ajouter une jail (ex: nginx)

Copier `config/jails.d/nginx-auth.conf.exemple` en `.conf`, adapter
`JOURNAL` et `REGEX_ECHEC`, puis `sudo systemctl restart sentinelle`.

## Tests avant mise en prod recommandés

- Simuler des échecs SSH depuis une IP de test et vérifier :
  `sentinelle-ctl status` puis `sudo iptables -L INPUT -n | grep <ip>`
- Vérifier le unban après expiration (`DUREE_BAN`)
- Vérifier que ton IP d'admin whitelistée n'est jamais bannie
- Redémarrer le serveur et vérifier que les bans en cours sont réappliqués
- Vérifier la rotation des logs (`sudo logrotate -f /etc/logrotate.d/sentinelle`)

## Limites connues assumées

- Comptage des tentatives basé sur un fichier plat + `flock` : suffisant pour
  la charge d'un serveur unique, pas conçu pour du très haut débit
  d'authentification (des milliers de tentatives/seconde).
- La regex d'extraction IP ne valide pas strictement les octets 0-255
  (accepte par ex. `999.999.999.999` en théorie) — sans impact sécurité
  puisqu'elle ne sert qu'à extraire depuis des logs système fiables.
SENTINELLE_EOF

cat > "$V3/config/jails.d/nginx-auth.conf.exemple" << 'SENTINELLE_EOF'
# Exemple de jail pour un endpoint protégé par auth_basic sur nginx.
# Renommer en .conf pour l'activer, et adapter le chemin du journal.

NOM="nginx-auth"
JOURNAL="/var/log/nginx/error.log"
REGEX_ECHEC="user .* was not found in|password mismatch"
REGEX_IP="([0-9]{1,3}\.){3}[0-9]{1,3}"

MAX_TENTATIVES=5
FENETRE_TEMPS=600
DUREE_BAN=3600
SENTINELLE_EOF

cat > "$V3/config/jails.d/ssh.conf" << 'SENTINELLE_EOF'
# Jail SSH — équivalent du filtre sshd de Fail2Ban

NOM="ssh"
JOURNAL="/var/log/auth.log"
REGEX_ECHEC="Failed password|Invalid user|authentication failure|Connection closed by authenticating user"
REGEX_IP="([0-9]{1,3}\.){3}[0-9]{1,3}"

MAX_TENTATIVES=5
FENETRE_TEMPS=600
DUREE_BAN=3600
SENTINELLE_EOF

cat > "$V3/config/liste_blanche.conf" << 'SENTINELLE_EOF'
# Une IP ou un CIDR par ligne. Les lignes commençant par # sont ignorées.
127.0.0.1
::1
SENTINELLE_EOF

cat > "$V3/config/sentinelle.conf" << 'SENTINELLE_EOF'
# Configuration globale de Sentinelle

BASE_BAN="/opt/sentinelle/data/bannis.db"
LISTE_BLANCHE="/opt/sentinelle/config/liste_blanche.conf"
LOG_FICHIER="/opt/sentinelle/logs/sentinelle.log"

# Durée de ban par défaut (secondes) si non précisée dans la jail
DUREE_BAN=3600

# Intervalle de vérification des bans expirés (secondes)
INTERVALLE_UNBAN=60
SENTINELLE_EOF

cat > "$V3/install.sh" << 'SENTINELLE_EOF'
#!/bin/bash
# Installation de Sentinelle. À lancer depuis le dossier extrait de l'archive.
set -e

if [ "$EUID" -ne 0 ]; then
    echo "Ce script doit être exécuté en root (sudo ./install.sh)"
    exit 1
fi

DIR_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE="/opt/sentinelle"

mkdir -p "$BASE"/{config/jails.d,lib,data,logs}

cp -r "$DIR_SOURCE"/config/* "$BASE/config/"
cp -r "$DIR_SOURCE"/lib/* "$BASE/lib/"
cp "$DIR_SOURCE/sentinelle.sh" "$BASE/sentinelle.sh"
cp "$DIR_SOURCE/sentinelle-ctl.sh" "$BASE/sentinelle-ctl.sh"

touch "$BASE/data/bannis.db"

chmod +x "$BASE/sentinelle.sh" "$BASE/sentinelle-ctl.sh" "$BASE"/lib/*.sh
chown -R root:root "$BASE"
chmod -R 750 "$BASE"

ln -sf "$BASE/sentinelle-ctl.sh" /usr/local/bin/sentinelle-ctl

cp "$DIR_SOURCE/systemd/sentinelle.service" /etc/systemd/system/sentinelle.service
cp "$DIR_SOURCE/systemd/sentinelle.logrotate" /etc/logrotate.d/sentinelle

systemctl daemon-reload
systemctl enable sentinelle.service

echo ""
echo "Installation terminée dans ${BASE}"
echo ""
echo "Vérifie/adapte AVANT de démarrer :"
echo "  - ${BASE}/config/jails.d/ssh.conf  (chemin du journal auth.log)"
echo "  - ${BASE}/config/liste_blanche.conf"
echo ""
echo "Démarrer     : systemctl start sentinelle"
echo "Statut       : systemctl status sentinelle"
echo "Logs         : journalctl -u sentinelle -f"
echo "Bans actuels : sentinelle-ctl status"
SENTINELLE_EOF

cat > "$V3/lib/ban.sh" << 'SENTINELLE_EOF'
#!/bin/bash
# Gestion des bannissements : ajout/suppression de règles iptables,
# écriture verrouillée dans la base, expiration automatique et
# restauration des bans au démarrage (persistance après reboot).

est_banni() {
    local ip="$1"
    grep -q "^${ip};" "$BASE_BAN" 2>/dev/null
}

ecrire_ligne_ban() {
    local ip="$1" jail="$2"
    echo "${ip};$(date +%s);${jail}" >> "$BASE_BAN"
}

supprimer_ligne_ban() {
    local ip="$1"
    sed -i "/^${ip};/d" "$BASE_BAN"
}

ban_ip() {
    local ip="$1" jail="$2"

    est_whitelist "$ip" && return 0
    est_banni "$ip" && return 0

    iptables -C INPUT -s "$ip" -j DROP 2>/dev/null || iptables -I INPUT -s "$ip" -j DROP

    with_lock "${BASE_BAN}.lock" ecrire_ligne_ban "$ip" "$jail"

    sentinelle_log "WARN" "BAN ${ip} (jail=${jail})"
}

unban_ip() {
    local ip="$1"

    iptables -D INPUT -s "$ip" -j DROP 2>/dev/null

    with_lock "${BASE_BAN}.lock" supprimer_ligne_ban "$ip"

    sentinelle_log "INFO" "UNBAN ${ip}"
}

unban_expires() {
    local now ip ts jail duree
    now=$(date +%s)
    duree="${DUREE_BAN:-3600}"

    [ -f "$BASE_BAN" ] || return 0

    while IFS=";" read -r ip ts jail; do
        [ -z "$ip" ] && continue
        if (( now - ts > duree )); then
            unban_ip "$ip"
        fi
    done < "$BASE_BAN"
}

# Réapplique les règles iptables pour les IP encore bannies dans bannis.db.
# Ne touche à aucune autre règle du pare-feu (pas de iptables-restore global).
restaurer_bans() {
    [ -f "$BASE_BAN" ] || return 0
    local ip ts jail
    while IFS=";" read -r ip ts jail; do
        [ -z "$ip" ] && continue
        iptables -C INPUT -s "$ip" -j DROP 2>/dev/null || iptables -I INPUT -s "$ip" -j DROP
    done < "$BASE_BAN"
    sentinelle_log "INFO" "Règles restaurées au démarrage depuis ${BASE_BAN}"
}
SENTINELLE_EOF

cat > "$V3/lib/jail_runner.sh" << 'SENTINELLE_EOF'
#!/bin/bash
# Surveille en continu le journal d'une jail, extrait les IP en échec,
# compte les tentatives dans une fenêtre glissante et déclenche le ban.

ecrire_tentative() {
    local fichier="$1" ip="$2"
    echo "${ip} $(date +%s)" >> "$fichier"
}

demarrer_jail() {
    local fichier_conf="$1"
    # shellcheck disable=SC1090
    source "$fichier_conf"

    local fichier_tentatives="${BASE}/data/tentatives_${NOM}.db"
    touch "$fichier_tentatives"

    if [ ! -f "$JOURNAL" ]; then
        sentinelle_log "ERREUR" "Journal introuvable: ${JOURNAL} (jail=${NOM})"
        return 1
    fi

    tail -Fn0 "$JOURNAL" 2>/dev/null | while read -r ligne; do

        echo "$ligne" | grep -qE "$REGEX_ECHEC" || continue

        local ip
        ip=$(echo "$ligne" | grep -oE "$REGEX_IP" | head -n1)
        [ -z "$ip" ] && continue

        est_whitelist "$ip" && continue
        est_banni "$ip" && continue

        with_lock "${fichier_tentatives}.lock" ecrire_tentative "$fichier_tentatives" "$ip"

        local now cutoff nb
        now=$(date +%s)
        cutoff=$((now - FENETRE_TEMPS))
        nb=$(awk -v ip="$ip" -v c="$cutoff" '$1==ip && $2>=c' "$fichier_tentatives" | wc -l)

        if (( nb >= MAX_TENTATIVES )); then
            ban_ip "$ip" "$NOM"
        fi
    done
}
SENTINELLE_EOF

cat > "$V3/lib/lock.sh" << 'SENTINELLE_EOF'
#!/bin/bash
# Exécute une fonction sous verrou exclusif flock pour éviter
# la corruption des fichiers de données en cas d'écritures concurrentes.
#
# Usage : with_lock /chemin/vers/fichier.lock nom_fonction arg1 arg2 ...

with_lock() {
    local fichier_lock="$1"
    shift
    (
        flock -x -w 5 200 || { sentinelle_log "ERREUR" "Timeout verrou ${fichier_lock}"; return 1; }
        "$@"
    ) 200>"$fichier_lock"
}
SENTINELLE_EOF

cat > "$V3/lib/log.sh" << 'SENTINELLE_EOF'
#!/bin/bash
# Journalisation centralisée avec niveaux (INFO / WARN / ERREUR)

sentinelle_log() {
    local niveau="$1"
    local message="$2"
    local ts
    ts=$(date -Iseconds)
    echo "${ts} [${niveau}] ${message}" >> "${LOG_FICHIER:-/opt/sentinelle/logs/sentinelle.log}"
}
SENTINELLE_EOF

cat > "$V3/lib/purge.sh" << 'SENTINELLE_EOF'
#!/bin/bash
# Purge les tentatives plus vieilles que la plus grande fenêtre configurée,
# pour éviter que les fichiers tentatives_*.db ne grossissent indéfiniment.

purger_tentatives() {
    local fenetre_max=86400 # 24h, large marge par rapport aux FENETRE_TEMPS des jails
    local now cutoff
    now=$(date +%s)
    cutoff=$((now - fenetre_max))

    local fichier
    for fichier in "${BASE}"/data/tentatives_*.db; do
        [ -f "$fichier" ] || continue
        with_lock "${fichier}.lock" bash -c "awk -v c='${cutoff}' '\$2>=c' '${fichier}' > '${fichier}.tmp' && mv '${fichier}.tmp' '${fichier}'"
    done
}
SENTINELLE_EOF

cat > "$V3/lib/whitelist.sh" << 'SENTINELLE_EOF'
#!/bin/bash
# Vérification de whitelist par correspondance EXACTE ou CIDR
# (corrige le bug de "grep -q" du script d'origine, qui faisait
# une correspondance partielle et pouvait whitelister des IP non voulues)

ip_vers_entier() {
    local IFS=.
    local a b c d
    read -r a b c d <<< "$1"
    echo $(( (a << 24) + (b << 16) + (c << 8) + d ))
}

ip_dans_cidr() {
    local ip="$1" cidr="$2"
    local reseau masque
    IFS="/" read -r reseau masque <<< "$cidr"

    local ip_dec reseau_dec mask_dec
    ip_dec=$(ip_vers_entier "$ip")
    reseau_dec=$(ip_vers_entier "$reseau")
    mask_dec=$(( 0xFFFFFFFF << (32 - masque) & 0xFFFFFFFF ))

    (( (ip_dec & mask_dec) == (reseau_dec & mask_dec) ))
}

est_whitelist() {
    local ip="$1"
    local ligne

    [ -f "$LISTE_BLANCHE" ] || return 1

    while IFS= read -r ligne; do
        ligne="${ligne%%#*}"
        ligne="$(echo -n "$ligne" | xargs)"
        [ -z "$ligne" ] && continue

        if [[ "$ligne" == *"/"* ]]; then
            [[ "$ip" == *.* ]] && ip_dans_cidr "$ip" "$ligne" && return 0
        elif [[ "$ip" == "$ligne" ]]; then
            return 0
        fi
    done < "$LISTE_BLANCHE"

    return 1
}
SENTINELLE_EOF

cat > "$V3/sentinelle-ctl.sh" << 'SENTINELLE_EOF'
#!/bin/bash
# Outil d'administration : consulter, bannir ou débannir manuellement.
# Usage : sentinelle-ctl.sh {status|ban <ip>|unban <ip>}

BASE="/opt/sentinelle"
export BASE

source "$BASE/config/sentinelle.conf"
source "$BASE/lib/log.sh"
source "$BASE/lib/lock.sh"
source "$BASE/lib/whitelist.sh"
source "$BASE/lib/ban.sh"

case "$1" in
    status)
        echo "IP actuellement bannies (ip;timestamp_ban;jail) :"
        if [ -s "$BASE_BAN" ]; then
            column -t -s ";" "$BASE_BAN"
        else
            echo "Aucune"
        fi
        ;;
    ban)
        [ -z "$2" ] && { echo "Usage: $0 ban <ip>"; exit 1; }
        ban_ip "$2" "manuel"
        echo "IP $2 bannie."
        ;;
    unban)
        [ -z "$2" ] && { echo "Usage: $0 unban <ip>"; exit 1; }
        unban_ip "$2"
        echo "IP $2 débannie."
        ;;
    *)
        echo "Usage: $0 {status|ban <ip>|unban <ip>}"
        exit 1
        ;;
esac
SENTINELLE_EOF

cat > "$V3/sentinelle.sh" << 'SENTINELLE_EOF'
#!/bin/bash
# Sentinelle — équivalent de Fail2Ban en Bash pur, sans dépendance tierce.

BASE="/opt/sentinelle"
export BASE

source "$BASE/config/sentinelle.conf"
source "$BASE/lib/log.sh"
source "$BASE/lib/lock.sh"
source "$BASE/lib/whitelist.sh"
source "$BASE/lib/ban.sh"
source "$BASE/lib/jail_runner.sh"
source "$BASE/lib/purge.sh"

PIDS=()

nettoyer() {
    sentinelle_log "INFO" "Arrêt de Sentinelle, fin des jails..."
    for pid in "${PIDS[@]}"; do
        kill "$pid" 2>/dev/null
    done
    exit 0
}
trap nettoyer SIGTERM SIGINT

sentinelle_log "INFO" "Démarrage de Sentinelle"
restaurer_bans

for conf in "$BASE"/config/jails.d/*.conf; do
    [ -f "$conf" ] || continue
    ( demarrer_jail "$conf" ) &
    PIDS+=($!)
    sentinelle_log "INFO" "Jail démarrée: $(basename "$conf") (pid $!)"
done

if [ ${#PIDS[@]} -eq 0 ]; then
    sentinelle_log "ERREUR" "Aucune jail active dans config/jails.d/ — arrêt"
    exit 1
fi

while true; do
    unban_expires
    purger_tentatives
    sleep "${INTERVALLE_UNBAN:-60}"
done
SENTINELLE_EOF

cat > "$V3/systemd/sentinelle.logrotate" << 'SENTINELLE_EOF'
/opt/sentinelle/logs/sentinelle.log {
    weekly
    rotate 8
    compress
    missingok
    notifempty
    copytruncate
}
SENTINELLE_EOF

cat > "$V3/systemd/sentinelle.service" << 'SENTINELLE_EOF'
[Unit]
Description=Sentinelle - Protection anti brute-force locale (equivalent Fail2Ban en Bash)
After=network.target rsyslog.service

[Service]
Type=simple
ExecStart=/opt/sentinelle/sentinelle.sh
Restart=on-failure
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
SENTINELLE_EOF

cat > "$V3/uninstall.sh" << 'SENTINELLE_EOF'
#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]; then
    echo "Ce script doit être exécuté en root (sudo ./uninstall.sh)"
    exit 1
fi

BASE="/opt/sentinelle"

systemctl stop sentinelle.service 2>/dev/null || true
systemctl disable sentinelle.service 2>/dev/null || true
rm -f /etc/systemd/system/sentinelle.service
rm -f /etc/logrotate.d/sentinelle
rm -f /usr/local/bin/sentinelle-ctl
systemctl daemon-reload

if [ -f "$BASE/data/bannis.db" ]; then
    while IFS=";" read -r ip ts jail; do
        [ -z "$ip" ] && continue
        iptables -D INPUT -s "$ip" -j DROP 2>/dev/null || true
    done < "$BASE/data/bannis.db"
fi

read -p "Supprimer ${BASE} et toutes les données (bans, logs) ? [o/N] " reponse
if [[ "$reponse" == "o" || "$reponse" == "O" ]]; then
    rm -rf "$BASE"
    echo "Supprimé."
else
    echo "Fichiers conservés dans ${BASE}, service désactivé."
fi
SENTINELLE_EOF
echo "Version 3 (unifiée multi-jails, corrigée) créée dans $V3"

chmod +x "$V1/opt_sentinelle/installation.sh" "$V1"/opt_sentinelle/*/*.sh 2>/dev/null || true
chmod +x "$V2/opt_sentinelle/sentinelle.sh"
chmod +x "$V3/sentinelle.sh" "$V3/sentinelle-ctl.sh" "$V3/install.sh" "$V3/uninstall.sh" "$V3"/lib/*.sh

echo ""
echo "=== Terminé ==="
echo "Arborescence créée sous : $MONITORING"
find "$MONITORING" -maxdepth 1 -mindepth 1 -type d
