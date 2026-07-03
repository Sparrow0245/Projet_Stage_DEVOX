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
