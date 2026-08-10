###############################################################################
# SENTINELLE V4
# Collector Bash Docker
###############################################################################

FROM ubuntu:24.04

LABEL org.opencontainers.image.title="Sentinelle Collector"
LABEL org.opencontainers.image.description="Collector Bash Sentinelle pour hôte Linux"
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
        mariadb-client \
        ca-certificates \
        curl \
        jq \
        openssh-client && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/sentinelle

###############################################################################
# COPIE DES SCRIPTS EXISTANTS
###############################################################################

COPY monitoring/04_sentinelle_supervision_securisee/bash \
    /opt/sentinelle/bash

COPY monitoring/04_sentinelle_supervision_securisee/config/thresholds.json \
    /opt/sentinelle/config/thresholds.json

###############################################################################
# OUTILS D'ADAPTATION A L'HOTE
###############################################################################

COPY deploiement_docker/collector/host-tools/df \
    /opt/sentinelle/host-tools/df

COPY deploiement_docker/collector/host-tools/systemctl \
    /opt/sentinelle/host-tools/systemctl

COPY deploiement_docker/collector/host-tools/journalctl \
    /opt/sentinelle/host-tools/journalctl

###############################################################################
# ENTRYPOINT
###############################################################################

COPY deploiement_docker/collector/entrypoint.sh \
    /opt/sentinelle/entrypoint.sh

RUN chmod +x /opt/sentinelle/entrypoint.sh && \
    chmod +x /opt/sentinelle/host-tools/* && \
    find /opt/sentinelle/bash \
        -type f \
        -name "*.sh" \
        -exec chmod +x {} \;

ENV PATH="/opt/sentinelle/host-tools:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

ENTRYPOINT ["/opt/sentinelle/entrypoint.sh"]
