# WireGuard VPN on cloudy

WireGuard VPN running as a Docker container on cloudy (192.168.178.71).
Clients tunnel all traffic through the home network when away.

## Prerequisites

The host kernel needs the WireGuard module. On Debian 11+/Ubuntu 22.04+ it is built-in.
Verify with:

```bash
sudo modprobe wireguard && echo "ok"
```

Create the persistent data directory:

```bash
sudo mkdir -p /var/wireguard/config
```

## 1. Configure DynDNS on FritzBox 7360

The FritzBox must be reachable from the internet by a stable hostname.

1. Open **http://fritz.box** → **Internet** → **MyFRITZ!-Konto**
2. Register a MyFRITZ! account (or log in if you already have one)
3. Note your hostname — it looks like `xxxxxxxxxx.myfritz.net`
4. Put this hostname into `.env` as `WG_SERVERURL`

## 2. Port Forwarding on FritzBox 7360

Forward UDP port 51820 to cloudy:

1. Open **http://fritz.box** → **Internet** → **Freigaben** (Port Forwarding)
2. Click **Neue Portfreigabe** (New Port Forwarding)
3. Select **Andere Anwendungen** (Other applications)
4. Fill in:
   - **Bezeichnung**: WireGuard
   - **Protokoll**: UDP
   - **Port an Gerät**: 51820
   - **Port extern gewünscht**: 51820
   - **An Computer**: cloudy (or select 192.168.178.71)
5. Click **OK**, then **Übernehmen** (Apply)

> **Note:** The FritzBox 7360 does not support WireGuard natively (that
> requires Fritz!OS 7.50+ on newer models like 7590). That's why we run
> WireGuard on cloudy and only forward the port.

## 3. Start WireGuard

```bash
cd ~/src/cloudy/wireguard
docker compose up -d
```

The first start generates keys and peer configs automatically.

## 4. Get Client Configs (QR Codes)

Each peer listed in `WG_PEERS` gets a config + QR code:

```bash
# Show QR code for a peer in the terminal
docker exec wireguard /app/show-peer androidjoern
docker exec wireguard /app/show-peer iphonejoern
```

Or find the config files directly:

```
/var/wireguard/config/peer_androidjoern/peer_androidjoern.conf
/var/wireguard/config/peer_androidjoern/peer_androidjoern.png   # QR code image
```

## 5. Install on Android

1. Install **WireGuard** from Google Play Store
2. Open the app → tap **+** → **Scan from QR code**
3. Scan the QR code shown by `docker exec wireguard /app/show-peer androidjoern`
4. Name the tunnel (e.g. "Home")
5. Toggle the tunnel on — you're connected

## 6. Install on iOS (iPhone/iPad)

1. Install **WireGuard** from the App Store
2. Open the app → tap **+** → **Create from QR code**
3. Scan the QR code shown by `docker exec wireguard /app/show-peer iphonejoern`
4. Name the tunnel (e.g. "Home") and allow the VPN configuration when prompted
5. Toggle the tunnel on — you're connected

## 7. Install on Linux (MATE / GNOME / any NetworkManager desktop)

1. Add a peer for your desktop on cloudy (see [Adding More Peers](#adding-more-peers) below)
2. Copy the generated config to your desktop:
   ```bash
   scp cloudy:/var/wireguard/config/peer_matejoern/peer_matejoern.conf ~/wg-home.conf
   ```
3. Install WireGuard and import the connection:
   ```bash
   sudo apt install wireguard
   nmcli connection import type wireguard file ~/wg-home.conf
   ```
4. The VPN appears in the NetworkManager applet in the panel — toggle it under **VPN Connections**

From the terminal:

```bash
nmcli connection up wg-home      # connect
nmcli connection down wg-home    # disconnect
```

## Adding More Peers

1. Edit `.env` and add the new peer name to `WG_PEERS` (comma-separated, **alphanumeric only** — no hyphens or special characters)
2. Recreate the container:
   ```bash
   docker compose up -d --force-recreate
   ```
3. Scan the new peer's QR code on the device

## Verifying the Connection

From the phone (with VPN active), visit https://whatismyipaddress.com —
it should show your home IP. You can also reach local devices
(e.g. http://192.168.178.71:8123 for Home Assistant).

On the server, check connected peers:

```bash
docker exec wireguard wg show
```

## DNS

`PEERDNS` is set to `172.17.0.1` (Docker host bridge) so VPN clients use Pi-hole
for DNS resolution, getting ad-blocking while on VPN. Change to
`192.168.178.1` to use the FritzBox DNS instead, or `1.1.1.1` for
Cloudflare.

## Troubleshooting

| Problem | Check |
|---|---|
| Can't connect from outside | Is UDP 51820 forwarded in FritzBox? `sudo nmap -sU -p 51820 <your-dyndns>` from outside |
| Handshake but no traffic | Check `net.ipv4.ip_forward=1` on the host: `sysctl net.ipv4.ip_forward` |
| DNS not resolving | Try changing `PEERDNS` to `1.1.1.1` to rule out Pi-hole issues |
| Container won't start | Check `sudo modprobe wireguard` succeeds on the host |

## Setup Notes

- **Peer names must be alphanumeric only.** The linuxserver image silently skips names with hyphens or special characters (e.g. `android-joern` fails, `androidjoern` works).
- **PEERDNS must use the Docker bridge IP (`172.17.0.1`), not the host's WiFi IP (`192.168.178.71`).** Containers on the default bridge network cannot reach the host via its WiFi/LAN address. Pi-hole listens on all interfaces including docker0, so `172.17.0.1` works.
- **Cannot test from the home WiFi.** The FritzBox 7360 does not support hairpin NAT, so VPN connections from inside the LAN back to the public IP will fail. Test over mobile data instead.
- **Avoid "Always-on VPN" + "Block connections without VPN" on Android** unless you only use the phone on mobile data. On networks where the tunnel can't connect (including the home WiFi), all internet access is blocked.
- **The official WireGuard app is not on F-Droid.** On GrapheneOS, install it via Aurora Store.
- **After changing PEERDNS or PEERS**, delete old peer configs and regenerate:
  ```bash
  docker compose down
  sudo rm -rf /var/wireguard/config/peer_*
  docker compose up -d
  ```
  Then re-scan the QR codes on all devices.
