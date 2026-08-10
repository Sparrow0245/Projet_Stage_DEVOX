###############################################################################
# Sentinelle V4 - Backend Spring Boot
###############################################################################

FROM maven:3.9-eclipse-temurin-21 AS builder

WORKDIR /build

COPY monitoring/04_sentinelle_supervision_securisee/backend/pom.xml .

RUN mvn dependency:go-offline -B

COPY monitoring/04_sentinelle_supervision_securisee/backend/src ./src

RUN mvn clean package -DskipTests -B


###############################################################################
# IMAGE D'EXÉCUTION
###############################################################################

FROM eclipse-temurin:21-jre-jammy

LABEL org.opencontainers.image.title="Sentinelle V4 Backend"
LABEL org.opencontainers.image.description="Backend Spring Boot de supervision Sentinelle"
LABEL org.opencontainers.image.version="4.0.0"

WORKDIR /opt/sentinelle

RUN mkdir -p /opt/sentinelle/logs

COPY --from=builder \
    /build/target/sentinelle-backend-4.0.0.jar \
    /opt/sentinelle/sentinelle-backend.jar

COPY deploiement_docker/backend/entrypoint.sh \
    /opt/sentinelle/entrypoint.sh

RUN chmod +x /opt/sentinelle/entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/opt/sentinelle/entrypoint.sh"]
