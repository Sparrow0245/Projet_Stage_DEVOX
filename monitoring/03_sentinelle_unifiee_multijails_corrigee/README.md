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
