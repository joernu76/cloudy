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

# Run the Nextcloud database/schema upgrade that the web UI otherwise
# demands via a manual button press.  No-op when versions already match.
cd "$CLOUDY/nextcloud"
echo "Waiting for nextcloud container to be ready..."
for i in $(seq 1 30); do
    if docker compose exec nextcloud php -r 'echo "ok";' >/dev/null 2>&1; then
        break
    fi
    sleep 5
done

echo "Running occ upgrade..."
if ! docker compose exec -u www-data nextcloud php occ upgrade 2>&1; then
    $MAIL "nextcloud occ upgrade failed — check manually"
fi
docker compose exec -u www-data nextcloud php occ maintenance:mode --off

# Restart the container to clear PHP's OPcache — stale bytecode from the
# pre-upgrade files causes Apache worker segfaults after a version bump.
docker compose restart nextcloud

update_stack influxdb
update_stack wireguard

# Check for Docker CE updates (don't install, just notify)
apt update -qq
DOCKER_UPDATE=$(apt list --upgradable 2>/dev/null | grep docker-ce || true)
if [ -n "$DOCKER_UPDATE" ]; then
    $MAIL "docker-ce update available: $DOCKER_UPDATE"
fi
