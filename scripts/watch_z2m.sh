#!/usr/bin/env bash
set -euo pipefail

DIR=/home/pi/cloudy/zigbee2mqtt
SERVICE=zigbee2mqtt
GRACE=300
MAIL=/home/pi/cloudy/scripts/mail.sh

cd "$DIR"

cid=$(docker compose ps --status running -q "$SERVICE")
[[ -n "$cid" ]] || { docker compose up -d "$SERVICE"; exit 0; }

started=$(date -d "$(docker inspect -f '{{.State.StartedAt}}' "$cid")" +%s)
(( $(date +%s) - started < GRACE )) && exit 0

payload=$(timeout 10 mosquitto_sub -h cloudy -t zigbee2mqtt/bridge/state -C 1)
state=$(jq -r '.state // empty' <<< "$payload" 2>/dev/null || true)
[[ -z "$state" ]] && state="$payload"

[[ "$state" == "online" ]] && exit 0

# Restart first: a mail failure must not prevent the restart.
docker compose restart "$SERVICE"
$MAIL "restarted barry zigbee2mqtt: $payload" || true
