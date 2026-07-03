# CORRIGÉ : l'original utilisait "grep -q" (correspondance partielle) :
# "192.168.0.1" dans la whitelist matchait aussi "192.168.0.100" ou
# "10.192.168.0.5" -> faille de bypass. "grep -qxF" impose une
# correspondance exacte de la ligne entière.
is_whitelisted() {
    grep -qxF "$1" /opt/sentinelle/config/liste_blanche.conf
}
