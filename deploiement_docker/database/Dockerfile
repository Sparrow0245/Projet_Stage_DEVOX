###############################################################################
# SENTINELLE V4
# MariaDB
###############################################################################

FROM mariadb:11.4

LABEL org.opencontainers.image.title="Sentinelle Database"
LABEL org.opencontainers.image.description="MariaDB pour Sentinelle"
LABEL org.opencontainers.image.version="4.0.0"

COPY deploiement_docker/database/init/01-sentinelle.sql \
    /docker-entrypoint-initdb.d/01-sentinelle.sql
