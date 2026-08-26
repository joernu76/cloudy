#!/bin/bash
#
# Health check for all cloudy services.
# Run with -v for verbose output (prints OK checks too).
# As cron job: mails on failure, silent on success.

MAIL=/home/pi/cloudy/scripts/mail.sh
VERBOSE=false
[[ "$1" == "-v" ]] && VERBOSE=true

ERRORS=""

check() {
    local name="$1"; shift
    if "$@" >/dev/null 2>&1; then
        $VERBOSE && echo "OK   $name"
    else
        echo "FAIL $name"
        ERRORS="${ERRORS}${name}\n"
    fi
}

# Expected containers
for c in \
    homeassistant \
    influxdb-influxdb \
    nextcloud-collabora \
    nextcloud-fail2ban \
    nextcloud-mariadb \
    nextcloud-nextcloud \
    nextcloud-nginx \
    nextcloud-redis \
    paperless \
    paperless-broker \
    paperless-db \
    pihole \
    wireguard \
; do
    check "container: $c" docker inspect -f '{{.State.Running}}' "$c"
done

# Systemd services
check "systemd: hacomfoairmqtt" systemctl is-active --quiet hacomfoairmqtt.service

# Service-level checks
check "nextcloud: https"       curl -sfk --max-time 5 https://localhost:1124/status.php
check "homeassistant: http"    curl -sf  --max-time 5 http://localhost:8123/
check "influxdb: health"       curl -sf  --max-time 5 http://localhost:8086/health
check "paperless: http"        curl -sf  --max-time 5 http://localhost:8000/
check "pihole: dns"            dig +short +timeout=3 @localhost example.com
check "pihole: http"           curl -sf  --max-time 5 http://localhost:8090/admin/
check "mariadb: ping"          docker exec nextcloud-mariadb mariadb-admin ping
check "postgres: ready"        docker exec paperless-db pg_isready -U paperless
check "redis: ping"            docker exec nextcloud-redis redis-cli ping
check "mosquitto: pub"         mosquitto_pub -h localhost -t cloudy/healthcheck -m ok

if [[ -n $ERRORS ]]; then
    SUMMARY="$(echo -ne "$ERRORS" | wc -l) check(s) failed: $(echo -ne "$ERRORS" | tr '\n' ' ')"
    echo "$SUMMARY"
    $MAIL "cloudy health: $SUMMARY"
    exit 1
else
    $VERBOSE && echo "all checks passed"
    exit 0
fi
