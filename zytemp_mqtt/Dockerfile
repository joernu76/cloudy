# Builds patrislav1/zytemp_mqtt straight from GitHub — no local checkout needed.
FROM python:3.12-slim

# hidapi is a C extension that links against libusb (your host's backend) and
# libudev. python:slim already ships the Python 3.12 headers, so we only add the
# C toolchain plus the libusb/udev dev + runtime libs. Installing both dev and
# runtime means the extension builds and loads whether pip finds a prebuilt
# wheel or has to compile — which matters when you rebuild on the arm64 Pi.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      git build-essential pkg-config \
      libusb-1.0-0 libusb-1.0-0-dev libudev-dev \
 && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 https://github.com/patrislav1/zytemp_mqtt.git /app
WORKDIR /app

# Install the app and its deps (hidapi, paho-mqtt, PyYAML).
# NOTE: paho-mqtt 2.x removed the 1.x callback signature that zytempmqtt/mqtt.py
# uses (mqtt.Client(client_id=...) + on_connect(client, userdata, flags, rc)), so
# it must stay pinned below 2.0.
RUN pip install --no-cache-dir . "paho-mqtt<2.0"

# `zytempmqtt` is the console_scripts entry point declared in setup.py.
# It reads config from $HOME/.config/zytempmqtt/config.yaml; HOME is /root here,
# so mount your config to /root/.config/zytempmqtt/config.yaml (see compose).
CMD ["zytempmqtt"]

