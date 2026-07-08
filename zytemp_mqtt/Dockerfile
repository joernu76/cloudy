# Dockerfile — drop into the root of your zytemp_mqtt checkout.
# Matches `build: ./zytemp_mqtt` in the compose file (build context = the repo).
FROM python:3.12-slim

# hidapi is a C extension that links against libusb (your host's backend) and
# libudev. python:slim already ships the Python 3.12 headers, so we only add the
# C toolchain plus the libusb/udev dev + runtime libs. Installing both dev and
# runtime means the extension builds and loads whether pip finds a prebuilt
# wheel or has to compile — which matters when you rebuild on the arm64 Pi.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential pkg-config \
      libusb-1.0-0 libusb-1.0-0-dev libudev-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

# Install the app and its deps (hidapi, paho-mqtt, PyYAML).
# NOTE: paho-mqtt 2.x changed its callback API and can break apps written for
# 1.x. Pinning <2 reproduces the 1.5.x that already works on your Debian 11
# host. If the app turns out to support 2.x, drop the "paho-mqtt<2.0" arg.
RUN pip install --no-cache-dir . "paho-mqtt<2.0"

# `zytempmqtt` is the console_scripts entry point declared in setup.py.
# It reads config from $HOME/.config/zytempmqtt/config.yaml; HOME is /root here,
# so mount your config to /root/.config/zytempmqtt/config.yaml (see compose).
CMD ["zytempmqtt"]

