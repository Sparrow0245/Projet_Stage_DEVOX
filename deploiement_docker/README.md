# Sentinelle V4 - Déploiement Docker

## Présentation

Ce dossier contient la couche de déploiement Docker de la solution
de monitoring Sentinelle.

L'objectif est de fournir un déploiement automatisé comparable au
script :

    ../script_lancement/lancement.sh

La solution Docker utilise plusieurs conteneurs :

- Collector Bash
- Apache + PHP
- MariaDB optionnelle

Le serveur hôte Linux reste la machine surveillée.

---

## Architecture

```text
                         SERVEUR LINUX
                              |
                         Docker Engine
                              |
              +---------------+---------------+
              |                               |
              v                               v
    sentinelle-collector               sentinelle-web
              |                               |
              |                               |
              +---------------+---------------+
                              |
                              v
                       MySQL / MariaDB
                              |
                    +---------+---------+
                    |                   |
              Docker local       Serveur externe
