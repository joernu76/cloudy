#!/bin/bash
set -x

date
mount /media/disk2

ARGS="-avxR --delete"
MAIL=/home/pi/cloudy/scripts/mail.sh

source /home/pi/cloudy/nextcloud/.env

####################
# NextCloud backup
####################

cd /home/pi/cloudy/nextcloud
docker-compose down
cd /home/pi/cloudy/influxdb
docker-compose down

cd /media/disk2/cloudy

AVAIL=`df --output=avail -BG . | tail -n 1 | sed s/G//`
if (( $AVAIL < 500 )); then
    $MAIL disk nearly full
fi

OLDBACKUP=`/bin/ls -d1 latest* | tail -n 1`
NEWBACKUP=latest-`date -I`
if [[ -d $OLDBACKUP && ! -d $NEWBACKUP ]]; then
    OLDBACKUP_MOVE=${OLDBACKUP/latest-/}
    mv ${OLDBACKUP} ${OLDBACKUP_MOVE}
    rsync ${ARGS} --link-dest=`pwd`/${OLDBACKUP_MOVE} /home/pi /media/disk /var/influxdb /var/nextcloud /var/sbfspot ${NEWBACKUP}
    $MAIL cloudy backup succeeded
else
    $MAIL cloudy backup failed
fi

export COMPOSE_HTTP_TIMEOUT=240
cd /home/pi/cloudy/nextcloud
docker-compose up -d
cd /home/pi/cloudy/influxdb
docker-compose up -d

sleep 120  # let everything start properly

####################
# MariaDB backup
####################

docker exec nextcloud-nextcloud /var/www/html/occ maintenance:mode --on

SQLBACKUP=nextcloud-sqlbkp_`date -I`.backup
docker exec nextcloud-mariadb sh -c "mariadb-dump --all-databases --default-character-set=utf8mb4 -uroot -p${STANDARD_PASSWORD} > /var/lib/mysql/$SQLBACKUP"
mv /var/nextcloud/mariadb/$SQLBACKUP /media/disk2/mariadb

docker exec nextcloud-nextcloud /var/www/html/occ maintenance:mode --off


####################
# Influxdb backup
####################

cd /home/pi/cloudy/influxdb
docker exec influxdb-influxdb influx backup /backup 

INFLUXBACKUP=/media/disk2/influxdb2/influxdb_`date -I`
mkdir ${INFLUXBACKUP}
mv /var/influxdb/backup/* ${INFLUXBACKUP}/

sync

sleep 10s

umount /media/disk2

