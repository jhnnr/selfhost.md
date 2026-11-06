# CT 111: `bazarr.lan` (Bazarr Subtitle Automation) <img src="../assets/icons/terminal.svg" width="20" height="20" alt="Subtitles" style="vertical-align: middle;" />

This document details the configuration, storage mounts, and Arr integrations for the Bazarr subtitle management daemon.

---

## 1. Container Metadata

| Property | Value |
| :--- | :--- |
| **Container ID** | `CT 111` |
| **Hostname** | `bazarr.lan` |
| **IPv4 Address** | Dynamic via DHCP (`10.10.0.x`) with AdGuard DNS rewrite |
| **Network Bridge** | `vmbr1` (Homelab Subnet: `10.10.0.0/24`) |
| **Web UI Port** | `6767` (HTTP) |
| **Storage Bind Mount** | `/mnt/media` <-- Proxmox host `/mnt/pve/smb-rclone.lan/Media` |

---

## 2. Storage & Directory Layout

- **Bind Mount (`mp0`):**
  Host path `/mnt/pve/smb-rclone.lan/Media` is mounted inside the container at `/mnt/media` with read/write permissions to place `.srt` files alongside media.
- **Target Directories:**
  - `/mnt/media/TV` — Monitored TV series library.
  - `/mnt/media/Movies` — Monitored movie library.

---

## 3. Connected Applications

- **Sonarr (`sonarr.lan:8989`):** Scrapes monitored series, seasons, and episodes to discover missing subtitles.
- **Radarr (`radarr.lan:7878` / CT 109):** Scrapes monitored movies and audio formats to download matching subtitles.
