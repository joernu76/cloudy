#!/bin/bash
date
export COMPOSE_HTTP_TIMEOUT=240

# nextcloud
cd /home/pi/cloudy/nextcloud
docker-compose down
docker-compose pull
docker-compose up -d

# influxdb
cd /home/pi/cloudy/influxdb
docker-compose down
docker-compose pull
docker-compose up -d
