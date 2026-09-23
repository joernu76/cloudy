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

# Run occ inside the container; on failure, mail the message plus the last
# lines of the command's output.  Output is also echoed for the log.
occ_or_mail() {
    local msg=$1; shift
    local out
    if out=$(docker compose exec -T -u www-data nextcloud php occ "$@" 2>&1); then
        echo "$out"
    else
        echo "$out"
        $MAIL "$msg"$'\n\n'"\$ occ $*"$'\n'"$(echo "$out" | tail -n 40)"
    fi
}

# Ready means: the image's entrypoint has finished (it copies new files and
# may run its own upgrade before exec'ing apache as PID 1) AND occ can boot,
# which requires a database connection.
nextcloud_ready() {
    [ "$(docker compose exec -T nextcloud cat /proc/1/comm 2>/dev/null)" = "apache2" ] &&
        docker compose exec -T -u www-data nextcloud php occ status >/dev/null 2>&1
}

echo "Waiting for nextcloud container to be ready..."
ready=false
for i in $(seq 1 60); do
    if nextcloud_ready; then
        ready=true
        break
    fi
    sleep 5
done

if ! $ready; then
    STATUS=$(docker compose exec -T -u www-data nextcloud php occ status 2>&1 | tail -n 40)
    $MAIL "nextcloud not ready after 5 minutes — check manually"$'\n\n'"\$ occ status"$'\n'"$STATUS"
else
    echo "Running occ upgrade..."
    occ_or_mail "nextcloud occ upgrade failed — check manually" upgrade
    occ_or_mail "nextcloud maintenance:mode --off failed — check manually" maintenance:mode --off

    # Restart the container to clear PHP's OPcache — stale bytecode from the
    # pre-upgrade files causes Apache worker segfaults after a version bump.
    docker compose restart nextcloud
fi

update_stack influxdb
update_stack wireguard

# Check for Docker CE updates (don't install, just notify)
apt update -qq
DOCKER_UPDATE=$(apt list --upgradable 2>/dev/null | grep docker-ce || true)
if [ -n "$DOCKER_UPDATE" ]; then
    $MAIL "docker-ce update available: $DOCKER_UPDATE"
fi
