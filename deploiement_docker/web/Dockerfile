###############################################################################
# Sentinelle V4 - Interface Web
###############################################################################

FROM php:8.3-apache

LABEL org.opencontainers.image.title="Sentinelle V4 Web"
LABEL org.opencontainers.image.description="Interface Web Apache PHP de Sentinelle"
LABEL org.opencontainers.image.version="4.0.0"

RUN docker-php-ext-install pdo pdo_mysql mysqli

RUN a2enmod \
    rewrite \
    proxy \
    proxy_http \
    headers

WORKDIR /var/www/html/sentinelle

COPY monitoring/04_sentinelle_supervision_securisee/web/ \
    /var/www/html/sentinelle/

COPY deploiement_docker/web/apache/sentinelle.conf \
    /etc/apache2/sites-available/sentinelle.conf

COPY deploiement_docker/web/entrypoint.sh \
    /usr/local/bin/sentinelle-web-entrypoint.sh

RUN chmod +x /usr/local/bin/sentinelle-web-entrypoint.sh && \
    a2dissite 000-default.conf && \
    a2ensite sentinelle.conf && \
    chown -R www-data:www-data /var/www/html/sentinelle

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/sentinelle-web-entrypoint.sh"]
