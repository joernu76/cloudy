# Dockerfile
FROM solarexplorer/sbfspot-sqlite
USER root
RUN echo "deb http://archive.debian.org/debian stretch main" > /etc/apt/sources.list && \
    echo "deb http://archive.debian.org/debian-security stretch/updates main" >> /etc/apt/sources.list && \
    apt-get update -o Acquire::Check-Valid-Until=false && \
    apt-get install -y mosquitto-clients && \
    rm -rf /var/lib/apt/lists/*
USER sbfspot
