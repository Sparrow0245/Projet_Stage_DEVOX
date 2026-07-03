# CORRIGÉ : l'original comptait sur toute la durée de vie d'events.log
# (jamais réinitialisé) et retournait un compte brut comparé à un seuil
# de 80 dans sentinelle.sh -> il aurait fallu 81 échecs avant tout ban,
# beaucoup trop permissif. Ici : comptage sur une fenêtre glissante
# (FENETRE_TEMPS) et score = tentatives * 20, pour un déclenchement à
# MAX_TENTATIVES échecs (5 par défaut) avec SEUIL_SCORE=80.
correlate() {
    ip="$1"
    now=$(date +%s)
    cutoff=$((now - FENETRE_TEMPS))
    count=$(awk -v ip="$ip" -v c="$cutoff" '$2==ip && $1>=c' /opt/sentinelle/data/events.log | wc -l)
    score=$((count * 20))
    echo "$ip:$score"
}
