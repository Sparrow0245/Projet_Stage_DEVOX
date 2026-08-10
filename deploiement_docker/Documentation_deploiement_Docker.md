# Documentation déploiement de la solution Sentinelle avec Docker

___

# Sentinelle V4 - Déploiement Docker

## 1. Présentation

Ce dossier contient la couche de déploiement Docker de la solution de
monitoring Sentinelle V4.

L'objectif est de fournir une méthode de déploiement aussi simple que le
script :

    Projet_Stage_DEVOX/script_lancement/lancement.sh

La différence est que Docker prend en charge l'isolation et le déploiement
des différents composants de la solution.

---

## 2. Architecture

La solution Docker est composée de plusieurs conteneurs :

- `sentinelle-collector`
  - Collecte les informations du serveur Linux hôte.
  - Utilise les scripts Bash présents dans la V4.
  - Enregistre les données dans MySQL/MariaDB.

- `sentinelle-backend`
  - Application Spring Boot.
  - Java 21.
  - API REST.
  - Port interne 8080.

- `sentinelle-web`
  - Apache.
  - PHP.
  - Interface Web Sentinelle.
  - Reverse proxy vers le backend.

- `sentinelle-db`
  - MariaDB.
  - Utilisé uniquement lorsque `DB_MODE=local`.

---

## 3. Base de données

Deux modes sont disponibles.

### Mode local

La base MariaDB est déployée automatiquement par Docker.

Dans `.env` :

    DB_MODE=local

La base utilise le volume Docker :

    sentinelle-db-data

---

### Mode externe

Une base MySQL/MariaDB déjà existante peut être utilisée.

Dans `.env` :

    DB_MODE=external

Puis renseigner :

    EXTERNAL_DB_HOST=
    EXTERNAL_DB_PORT=3306
    EXTERNAL_DB_NAME=sentinelle
    EXTERNAL_DB_USER=sentinelle
    EXTERNAL_DB_PASSWORD=

Dans ce mode, le conteneur MariaDB local n'est pas démarré.

---

## 4. Installation

Depuis le serveur Linux :

    cd Projet_Stage_DEVOX/deploiement_docker

Créer la configuration :

    cp .env.example .env

Modifier ensuite `.env`.

Il est notamment nécessaire de modifier :

    DB_PASSWORD
    JWT_SECRET
    MYSQL_ROOT_PASSWORD

---

## 5. Déploiement

Lancer :

    ./scripts/lancement-docker.sh

Le script :

1. vérifie Docker ;
2. vérifie Docker Compose ;
3. vérifie la configuration ;
4. construit les images ;
5. démarre les conteneurs ;
6. affiche l'état des services.

---

## 6. Accès

Interface Web :

    http://localhost:8080

Backend :

    http://localhost:8080/api

Les ports peuvent être modifiés dans `.env`.

---

## 7. Gestion

Afficher l'état :

    ./scripts/statut-docker.sh

Afficher les logs :

    ./scripts/logs-docker.sh

Afficher les logs du collector :

    ./scripts/logs-docker.sh sentinelle-collector

Redémarrer :

    ./scripts/redemarrage-docker.sh

Arrêter :

    ./scripts/arret-docker.sh

---

## 8. Persistance

La base MariaDB locale utilise le volume :

    sentinelle-db-data

La commande :

    docker compose down

ne supprime pas ce volume.

Pour supprimer également les données :

    docker compose down -v

Cette opération est destructive pour la base Docker locale.

---

## 9. Surveillance de l'hôte

Le collector doit pouvoir observer le serveur Linux sur lequel Docker
est exécuté.

Pour cette raison, le conteneur collector utilise notamment :

- le namespace PID de l'hôte ;
- le réseau de l'hôte ;
- des montages en lecture seule de `/`, `/proc`, `/sys`, `/run`,
  `/var/log` et `/etc`.

Le collector dispose également de privilèges élevés.

Ces paramètres sont nécessaires pour reproduire le comportement attendu
d'une solution qui surveille directement le serveur hôte.

---

## 10. Sécurité

Les secrets ne doivent pas être stockés directement dans les Dockerfiles.

Le fichier `.env` est utilisé pour fournir :

- les identifiants de base de données ;
- le secret JWT ;
- les paramètres de connexion.

Le fichier `.env` ne doit pas être versionné dans Git.

Le fichier `.env.example` peut être versionné.

---

## 11. Compatibilité

La couche Docker est conçue pour être exécutée sur un serveur Linux
disposant de Docker et Docker Compose.

Le serveur hôte doit être capable d'exécuter des conteneurs Linux.

Le déploiement ne dépend pas d'un fournisseur Cloud particulier.

---

## 12. Structure

    deploiement_docker/
    ├── .dockerignore
    ├── .env.example
    ├── compose.yml
    ├── README.md
    │
    ├── backend/
    │   ├── Dockerfile
    │   └── entrypoint.sh
    │
    ├── collector/
    │   ├── Dockerfile
    │   └── entrypoint.sh
    │
    ├── database/
    │   ├── Dockerfile
    │   └── init/
    │       └── 01-init.sql
    │
    ├── web/
    │   ├── Dockerfile
    │   ├── entrypoint.sh
    │   └── apache/
    │       └── sentinelle.conf
    │
    └── scripts/
        ├── lancement-docker.sh
        ├── arret-docker.sh
        ├── redemarrage-docker.sh
        ├── statut-docker.sh
        └── logs-docker.sh
