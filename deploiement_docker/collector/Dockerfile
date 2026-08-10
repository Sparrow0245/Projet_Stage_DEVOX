###############################################################################
# Sentinelle V4 - Collector Bash
###############################################################################

FROM ubuntu:24.04

LABEL org.opencontainers.image.title="Sentinelle V4 Collector"
LABEL org.opencontainers.image.description="Collecteur Bash de supervision de l'hôte Linux"
LABEL org.opencontainers.image.version="4.0.0"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash \
        bc \
        coreutils \
        procps \
        sysstat \
        iproute2 \
        iputils-ping \
        net-tools \
        lsof \
        util-linux \
        systemd \
        systemd-sysv \
        mariadb-client \
        ca-certificates \
        curl \
        jq && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/sentinelle

COPY monitoring/04_sentinelle_supervision_securisee/bash \
    /opt/sentinelle/bash

COPY monitoring/04_sentinelle_supervision_securisee/config/thresholds.json \
    /opt/sentinelle/config/thresholds.json

COPY deploiement_docker/collector/entrypoint.sh \
    /opt/sentinelle/entrypoint.sh

RUN chmod +x /opt/sentinelle/entrypoint.sh && \
    find /opt/sentinelle/bash -type f -name "*.sh" -exec chmod +x {} \;

ENTRYPOINT ["/opt/sentinelle/entrypoint.sh"]
