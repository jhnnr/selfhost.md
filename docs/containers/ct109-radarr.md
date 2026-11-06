# CT 109: `radarr.lan` (Radarr Movie Automation) <img src="../assets/icons/play.svg" width="20" height="20" alt="Play" style="vertical-align: middle;" />

This document details the configuration, storage bindings, and integration workflow for the Radarr movie automation daemon.

---

## 1. Container Metadata

| Property | Value |
| :--- | :--- |
| **Container ID** | `CT 109` |
| **Hostname** | `radarr.lan` |
| **IPv4 Address** | Dynamic via DHCP (`10.10.0.x`) with AdGuard DNS rewrite |
| **Network Bridge** | `vmbr1` (Homelab Subnet: `10.10.0.0/24`) |
| **Web UI Port** | `7878` (HTTP) |
| **Storage Bind Mount** | `/mnt/media` <-- Proxmox host `/mnt/pve/smb-rclone.lan/Media` |
| **Movie Library Path** | `/mnt/media/Movies` |

---

## 2. Storage & Directory Layout

- **Bind Mount (`mp0`):**
  Host path `/mnt/pve/smb-rclone.lan/Media` is mounted inside the container at `/mnt/media`.
- **Target Directories:**
  - `/mnt/media/Movies` — Final root folder for imported movie files.
  - Remote path mappings translate qBittorrent download locations into local container paths.

---

## 3. Integrations

- **Download Client:** Connects to `qbit.lan:8090` (CT 105) using WebAPI bearer authentication under category `movies` or `radarr`.
- **Indexer Management:** Synchronized automatically by `prowlarr.lan:9696` (CT 110).
- **Subtitles:** Integrates with `bazarr.lan:6767` (CT 111) to automatically source subtitles for imported movies.
- **Media Discovery:** Receives movie request commands from `seer.lan:5055` (Jellyseerr).
- **Plex Library Refresh:** Triggers Plex Media Server on `plex.lan:32400` Section `2` (Movies) upon import.
