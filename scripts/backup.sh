#!/bin/bash
set -x

date
mount /media/disk2

ARGS="-avxR --delete"
MAIL=/home/pi/cloudy/scripts/mail.sh
CLOUDY=/home/pi/cloudy
export COMPOSE_HTTP_TIMEOUT=240
ERRORS=""

source ${CLOUDY}/nextcloud/.env

cd /media/disk2/cloudy

AVAIL=$(df --output=avail -BG . | tail -n 1 | sed s/G//)
if (( AVAIL < 500 )); then
    ERRORS="${ERRORS}disk nearly full (${AVAIL}G free)\n"
fi

####################
# Stop services that need consistent snapshots
####################

cd ${CLOUDY}/nextcloud
docker compose down       || ERRORS="${ERRORS}nextcloud down failed\n"
cd ${CLOUDY}/influxdb
docker compose down       || ERRORS="${ERRORS}influxdb down failed\n"
cd ${CLOUDY}/paperless-ngx
docker compose down       || ERRORS="${ERRORS}paperless down failed\n"

####################
# Filesystem backup
####################

cd /media/disk2/cloudy

OLDBACKUP=$(/bin/ls -d1 latest* 2>/dev/null | tail -n 1)
NEWBACKUP=latest-$(date -I)
if [[ -n $OLDBACKUP && ! -d $NEWBACKUP ]]; then
    OLDBACKUP_MOVE=${OLDBACKUP/latest-/}
    mv ${OLDBACKUP} ${OLDBACKUP_MOVE}
    rsync ${ARGS} --link-dest=$(pwd)/${OLDBACKUP_MOVE} /etc /root /home/pi /media/disk /var/pihole /var/homeassistant /var/influxdb /var/nextcloud /var/sbfspot /var/paperless /var/wireguard ${NEWBACKUP} \
        || ERRORS="${ERRORS}rsync failed (exit $?)\n"
else
    ERRORS="${ERRORS}no previous backup or target already exists\n"
fi

####################
# Restart services
####################

cd ${CLOUDY}/nextcloud
docker compose up -d --wait   || ERRORS="${ERRORS}nextcloud up failed\n"
cd ${CLOUDY}/influxdb
docker compose up -d --wait   || ERRORS="${ERRORS}influxdb up failed\n"
cd ${CLOUDY}/paperless-ngx
docker compose up -d --wait   || ERRORS="${ERRORS}paperless up failed\n"

sleep 120

####################
# MariaDB dump
####################

docker exec nextcloud-nextcloud /var/www/html/occ maintenance:mode --on

SQLBACKUP=nextcloud-sqlbkp_$(date -I).backup
docker exec nextcloud-mariadb sh -c 'mariadb-dump --all-databases --default-character-set=utf8mb4 -uroot -p"${MARIADB_ROOT_PASSWORD}"' > /media/disk2/mariadb/${SQLBACKUP} \
    || ERRORS="${ERRORS}mariadb dump failed\n"

docker exec nextcloud-nextcloud /var/www/html/occ maintenance:mode --off

####################
# Paperless PostgreSQL dump
####################

docker exec paperless-db pg_dumpall -U paperless > /media/disk2/paperless/paperless-sqlbkp_$(date -I).backup \
    || ERRORS="${ERRORS}paperless pg_dump failed\n"

####################
# InfluxDB dump
####################

docker exec influxdb-influxdb influx backup /backup \
    || ERRORS="${ERRORS}influxdb dump failed\n"

INFLUXBACKUP=/media/disk2/influxdb2/influxdb_$(date -I)
mkdir -p ${INFLUXBACKUP}
mv /var/influxdb/backup/* ${INFLUXBACKUP}/

sync
sleep 10
umount /media/disk2

####################
# Summary mail
####################

if [[ -n $ERRORS ]]; then
    $MAIL "cloudy backup ERRORS: $(echo -e ${ERRORS})"
else
    $MAIL cloudy backup succeeded
fi

