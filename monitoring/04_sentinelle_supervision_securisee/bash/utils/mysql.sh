#!/usr/bin/env bash
execute_sql() {
    local query="$1"
    mysql --defaults-extra-file=/etc/mysql/sentinelle.cnf -e "$query" 2>/dev/null
}
