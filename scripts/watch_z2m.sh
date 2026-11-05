#!/usr/bin/env bash
set -euo pipefail

DIR=/home/pi/cloudy/zigbee2mqtt
SERVICE=zigbee2mqtt
GRACE=300
MAIL=/home/pi/cloudy/scripts/mail.sh

# Evidence from the frozen process; the restart below destroys it.
capture() {
    echo "=== $(date -Is) capture pid=$pid"
    grep -E '^(State|VmHWM|VmRSS|VmSwap|Threads)' "/proc/$pid/status"
    echo "wchan=$(cat "/proc/$pid/wchan") syscall=$(cat "/proc/$pid/syscall")"
    cat "/proc/$pid/stack"
    top -H -b -n 2 -d 3 -p "$pid" | tail -n 14
    nsenter -t "$pid" -n ss -tn
}

cd "$DIR"

cid=$(docker compose ps --status running -q "$SERVICE")
[[ -n "$cid" ]] || { docker compose up -d "$SERVICE"; exit 0; }

# tini is the container's main process, node its only child.
pid=$(pgrep -P "$(docker inspect -f '{{.State.Pid}}' "$cid")" || true)
echo "$(date -Is) rss_kb=$(awk '/^VmRSS/ {print $2}' "/proc/$pid/status" 2>/dev/null || true)"

started=$(date -d "$(docker inspect -f '{{.State.StartedAt}}' "$cid")" +%s)
(( $(date +%s) - started < GRACE )) && exit 0

payload=$(timeout 10 mosquitto_sub -h cloudy -t zigbee2mqtt/bridge/state -C 1)
state=$(jq -r '.state // empty' <<< "$payload" 2>/dev/null || true)
[[ -z "$state" ]] && state="$payload"

[[ "$state" == "online" ]] && exit 0

capture 2>&1 || true

# Restart first: a mail failure must not prevent the restart.
docker compose restart "$SERVICE"
$MAIL "restarted barry zigbee2mqtt: $payload" || true
