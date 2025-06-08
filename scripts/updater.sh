#!/bin/bash
date

# nextcloud
cd /home/pi/cloudy/nextcloud
docker-compose down
docker-compose pull
export COMPOSE_HTTP_TIMEOUT=240
docker-compose up -d

# influxdb
cd /home/pi/cloudy/influxdb
docker-compose down
docker-compose pull
export COMPOSE_HTTP_TIMEOUT=240
docker-compose up -d
