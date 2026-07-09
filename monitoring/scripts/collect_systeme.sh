#!/bin/bash

# Collecte des métriques système Sentinelle


CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')

RAM=$(free | awk '/Mem:/ {printf "%.2f", $3/$2*100}')

DISK=$(df / | awk 'NR==2 {print $5}' | tr -d '%')

LOAD=$(cat /proc/loadavg | awk '{print $1}')


echo "$CPU;$RAM;$DISK;$LOAD"
