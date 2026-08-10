###############################################################################
# Sentinelle V4 - MariaDB
###############################################################################

FROM mariadb:11.4

LABEL org.opencontainers.image.title="Sentinelle V4 Database"
LABEL org.opencontainers.image.description="MariaDB pour Sentinelle V4"
LABEL org.opencontainers.image.version="4.0.0"

COPY deploiement_docker/database/init/01-init.sql \
    /docker-entrypoint-initdb.d/01-init.sql
