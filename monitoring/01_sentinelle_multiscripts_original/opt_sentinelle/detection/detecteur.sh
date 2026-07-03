detecter_ips() {
    echo "$1" | grep -E "Failed password|Invalid user" \
    | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}"
}
