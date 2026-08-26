#!/bin/bash
date
export COMPOSE_HTTP_TIMEOUT=240

MAIL=/home/pi/cloudy/scripts/mail.sh
CLOUDY=/home/pi/cloudy

update_stack() {
    cd "$CLOUDY/$1"
    docker compose pull -q
    docker compose down
    docker compose up -d
}

update_stack nextcloud
update_stack influxdb
update_stack wireguard

# Check for Docker CE updates (don't install, just notify)
apt update -qq
DOCKER_UPDATE=$(apt list --upgradable 2>/dev/null | grep docker-ce || true)
if [ -n "$DOCKER_UPDATE" ]; then
    $MAIL "docker-ce update available: $DOCKER_UPDATE"
fi
