# Homelab Infrastructure Map

This document serves as the high-level architecture overview and network topology map for the homelab environment hosted on Proxmox VE.

---

## Visual Architecture & Network Topology

<div style="text-align: center; margin: 1.5rem 0;">
  <img src="assets/network-topology.svg" alt="Homelab Network Topology Digraph" class="zoomable-image" style="max-width: 100%; height: auto; border-radius: 8px; border: 1px solid #334155;" />
</div>

### ASCII Topology Diagram

```text
[ Public Internet ]
         |
 +-------+-----------------------+
 |                               |
 v                               v
[ Home ISP Router ]   [ Cloudflare Edge / Mesh ]
(br0: 192.168.100.1/24) (Mesh 100.96.0.0/12)
Static Route: 10.10.0.0/24       |
via 192.168.100.2                +-----------------------------+
 |                               |                             |
 |                               v                             v
 |                  [ openvpn-oracle VPS ]          [CT 101] cloudflared
 |                  (Cloud Mesh Node)               (10.10.0.3 / cloudflared.lan)
 |                                                             |
 v                                                             |
+----------------------------------------+                     |
| Proxmox Host (pve01)                   |                     |
| vmbr0: 192.168.100.2                   |                     |
| vmbr1: 10.10.0.1 (GW)                  |<--------------------+
+-------------------+--------------------+
                    |
====================+================================================ vmbr1
10.10.0.0/24 Subnet | (DHCP & DNS via 10.10.0.2)
====================+================================================
                    |
+--> [CT 100] adguard (10.10.0.2 / adguard.home.server)
|    +-- Primary DNS (:53), DHCP Server, Web UI (:3000)
|
+--> [CT 101] cloudflared (10.10.0.3 / cloudflared.lan)
|    +-- Forwards DoH & Tunnel traffic to 10.10.0.0/24
|
+--> [VM 102] docker (DHCP / docker.lan) [16GB RAM]
|    |-- OpenKOS Suite -----------------------------> [Uses CT 106 DB :5432]
|    |-- Firefly III Suite --------------------------> [Uses CT 106 DB :5432]
|    |-- PodPDF (:2873 -> :8080)
|    |-- Steam-ish (:3112 -> :3000)
|    +-- Portainer (:9443 / :8000)
|
+--> [CT 103] rclone (DHCP / rclone.lan)
|    +-- Rclone FUSE (gdrive, TAS) + Samba Server (//rclone.lan/gdrive)
|
+--> [CT 104] plex (DHCP / plex.lan)
|    +-- Bind Mount: /mnt/media <--- Host SMB (/mnt/pve/smb-rclone.lan/Media)
|
+--> [CT 105] qbit (DHCP / qbit.lan)
|    +-- Bind Mount: /mnt/media <--- Host SMB (/mnt/pve/smb-rclone.lan/Media)
|    +-- WebUI (:8090, Bearer Auth)
|
+--> [CT 106] postgresql (DHCP / postgresql.lan)
|    +-- Shared PostgreSQL (:5432) & Adminer (:80/adminer)
|    +-- Databases: openkos, firefly
|
+--> [CT 107] seer (DHCP / seer.lan)
|    +-- Jellyseerr / Overseerr (:5055)
|
+--> [CT 108] sonarr (DHCP / sonarr.lan)
|    +-- TV Automation (:8989)
|    +-- Bind Mount: /mnt/media <--- Host SMB (/mnt/pve/smb-rclone.lan/Media)
|
+--> [CT 109] radarr (DHCP / radarr.lan)
|    +-- Movie Automation (:7878)
|    +-- Bind Mount: /mnt/media <--- Host SMB (/mnt/pve/smb-rclone.lan/Media)
|
+--> [CT 110] prowlarr (DHCP / prowlarr.lan)
|    +-- Indexer Manager & Proxy (:9696)
|
+--> [CT 111] bazarr (DHCP / bazarr.lan)
     +-- Subtitle Automation (:6767)
     +-- Bind Mount: /mnt/media <--- Host SMB (/mnt/pve/smb-rclone.lan/Media)
```

---

## Node Details & Responsibilities

### 1. `pve01` (Proxmox VE Host) <img src="assets/icons/server.svg" width="18" height="18" alt="Server" style="vertical-align: middle;" />
- **Role:** Bare-metal hypervisor host running Proxmox VE.
- **Network Interfaces:**
  - `vmbr0`: Bridged exclusively to the physical Home ISP Router (`192.168.100.2/24`).
  - `vmbr1`: Isolated internal bridge serving the `10.10.0.0/24` homelab subnet (`10.10.0.1` gateway).
- **Storage Integration:** SMB mounts are managed directly at the host level.
- **Key Files:**
  - `/etc/fstab` — Handles mount points on boot, mounting `//rclone.lan/gdrive` at `/mnt/pve/smb-rclone.lan/Media`.

---

### 2. `adguard.lan` (CT 100) <img src="assets/icons/shield.svg" width="18" height="18" alt="Shield" style="vertical-align: middle;" />
- **Role:** Primary local DNS server, DHCP daemon, and ad-blocking gateway.
- **IP:** `10.10.0.2` (Static / `adguard.home.server`)
- **Services & Ports:**
  - DNS Server: Port `53` (TCP/UDP)
  - Web UI: Port `3000` (HTTP)
  - DHCP Server for `10.10.0.0/24` subnet.

---

### 3. `cloudflared.lan` (CT 101) <img src="assets/icons/cloud.svg" width="18" height="18" alt="Cloud" style="vertical-align: middle;" />
- **Role:** Cloudflare Zero-Trust Tunnel gateway connected directly to Cloudflare Edge / Mesh (`100.96.0.0/12`), providing secure external ingress without opening inbound ports on the ISP router.
- **IP:** `10.10.0.3` (Static)
- **Features:** Forwards DNS-over-HTTPS (DoH) and tunnel traffic to the `10.10.0.0/24` subnet.

---

### 4. `docker.lan` (VM 102) <img src="assets/icons/docker.svg" width="18" height="18" alt="Docker" style="vertical-align: middle;" />
- **Role:** Dedicated Docker VM with 16GB RAM.
- **Hosted Projects:**
  - **OpenKOS** (Uses CT 106 PostgreSQL)
  - **Firefly III** (Uses CT 106 PostgreSQL)
  - **PodPDF**
  - **Steam-ish**
  - **Portainer**

---

### 5. `rclone.lan` (CT 103) <img src="assets/icons/storage.svg" width="18" height="18" alt="Storage" style="vertical-align: middle;" />
- **Role:** Manages cloud storage synchronization and mounting (Google Drive & Telegram as Storage - TAS) and triggers automated library scanning when files change.
- **Systemd Services:**
  - `/etc/systemd/system/plex-watcher.service` — Daemon process managing automatic starts and stops for the watcher script.
  - `/etc/systemd/system/rclone-gdrive.service` — Daemon process for mounting the `gdrive` remote from rclone.
  - `/etc/systemd/system/tas-mount.service` — Daemon process for mounting Telegram as Storage (TAS) locally.
  - `/etc/systemd/system/tas-sync.service` — Daemon process managing automated synchronization jobs for TAS.
- **Mount Points:**
  - `/mnt/gdrive/plex` — Google Drive rclone mount.
  - `/mnt/tas` — Telegram as Storage (TAS) FUSE mount point.
- **Network Share:**
  - Samba server exporting `//rclone.lan/gdrive` to `pve01`.

---

### 6. `plex.lan` (CT 104) <img src="assets/icons/play.svg" width="18" height="18" alt="Play" style="vertical-align: middle;" />
- **Role:** Media server running Plex Media Server.
- **Port:** `32400`
- **Storage Path:** `/mnt/media` (LXC bind mount from `pve01`'s `/mnt/pve/smb-rclone.lan/Media`).
- **Plex Section IDs:**
  - **Movies:** Section ID `2`
  - **TV Shows:** Section ID `3`

---

### 7. `qbit.lan` (CT 105) <img src="assets/icons/download.svg" width="18" height="18" alt="Download" style="vertical-align: middle;" />
- **Documentation:** [`containers/ct105-qbit.md`](containers/ct105-qbit.md)
- **Role:** Torrent downloader handling television and movie file transfers.
- **Port:** `8090`
- **Storage:**
  - Bind mount: `/mnt/media` <-- Host SMB (`/mnt/pve/smb-rclone.lan/Media`)
- **Key Configurations:**
  - **WebAPI v2.14+ API Key Auth:** Generates bearer tokens for passwordless external scripts.
  - **Torrent Completion Hook:** Executes `/root/.config/qBittorrent/discord_qbit_notification.sh` to trigger direct Plex library scans (Movies ID 2, TV ID 3) and send rich Discord notifications for non-Arr downloads.

---

### 8. `postgresql.lan` (CT 106) <img src="assets/icons/database.svg" width="18" height="18" alt="Database" style="vertical-align: middle;" />
- **Role:** Dedicated shared database server running PostgreSQL and Adminer.
- **Default Port:** `5432`
- **Adminer Port:** `80` (access at `http://postgresql.lan/adminer`)
- **Hosted Databases:**
  - `openkos` — Primary database for the OpenKOS platform.
  - `firefly` — Primary database for the Firefly III Budgeting App.

---

### 9. `seer.lan` (CT 107) <img src="assets/icons/search.svg" width="18" height="18" alt="Search" style="vertical-align: middle;" />
- **Role:** Media request and discovery platform (Jellyseerr / Overseerr).
- **Port:** `5055`
- **Integrations:**
  - **Sonarr Connection:** Connects to `sonarr.lan` (CT 108) to push TV requests into Sonarr's queue.
  - **Radarr Connection:** Connects to `radarr.lan` (CT 109) to push movie requests into Radarr's queue.
  - **Plex Connection:** Scrapes `plex.lan` (CT 104) to verify media availability.

---

### 10. `sonarr.lan` (CT 108) <img src="assets/icons/tv.svg" width="18" height="18" alt="TV" style="vertical-align: middle;" />
- **Role:** Smart TV episode automation daemon. Tracks, grabs, and manages library importing for TV shows.
- **Port:** `8989`
- **Storage Bindings:**
  - Bind mount: `/mnt/media` <-- Host SMB (`/mnt/pve/smb-rclone.lan/Media`)
  - Library Root: `/mnt/media/TV`
- **Integrations & Hooks:**
  - **Download Client:** Connects to `qbit.lan:8090` (CT 105) using a native Bearer Token API Key.
  - **Custom Post-Import Script:** Executes `/root/scripts/qbit-relocate.sh` on download/import events to rename/relocate files in qBittorrent, cleanup local source duplicates, and resume seeding.
- **Key Settings:**
  - `Create Empty Series Folders` enabled to generate root show directories immediately on add.

---

### 11. `radarr.lan` (CT 109) <img src="assets/icons/play.svg" width="18" height="18" alt="Movie" style="vertical-align: middle;" />
- **Documentation:** [`containers/ct109-radarr.md`](containers/ct109-radarr.md)
- **Role:** Smart movie automation and collection manager.
- **Port:** `7878`
- **Mounts / Paths:**
  - Bind mount: `/mnt/media` <-- Host SMB (`/mnt/pve/smb-rclone.lan/Media`)
  - Library Root: `/mnt/media/Movies`
- **Integrations:**
  - Connects to `qbit.lan:8090` (CT 105) to grab movie releases.
  - Syncs with `prowlarr.lan` (CT 110) for indexers.
  - Triggers Plex Section 2 (Movies) on import.

---

### 12. `prowlarr.lan` (CT 110) <img src="assets/icons/search.svg" width="18" height="18" alt="Search" style="vertical-align: middle;" />
- **Documentation:** [`containers/ct110-prowlarr.md`](containers/ct110-prowlarr.md)
- **Role:** Centralized indexer proxy and manager for all Arr services.
- **Port:** `9696`
- **Integrations:**
  - Automatically synchronizes Usenet and Torrent indexers with Sonarr (CT 108) and Radarr (CT 109).

---

### 13. `bazarr.lan` (CT 111) <img src="assets/icons/terminal.svg" width="18" height="18" alt="Subtitles" style="vertical-align: middle;" />
- **Documentation:** [`containers/ct111-bazarr.md`](containers/ct111-bazarr.md)
- **Role:** Companion subtitle automation daemon for TV shows and movies.
- **Port:** `6767`
- **Mounts / Paths:**
  - Bind mount: `/mnt/media` <-- Host SMB (`/mnt/pve/smb-rclone.lan/Media`)
  - Target Folders: `/mnt/media/TV` and `/mnt/media/Movies`
- **Integrations:**
  - Integrates with Sonarr (CT 108) and Radarr (CT 109) to automatically fetch matching subtitles.

---

### 14. `openvpn-oracle` (Oracle Cloud VPS) <img src="assets/icons/cloud.svg" width="18" height="18" alt="VPN" style="vertical-align: middle;" />
- **Role:** Remote cloud node on Oracle Cloud Infrastructure, connected directly through the Cloudflare Edge / Mesh network (`100.96.0.0/12`) to provide secure remote offsite ingress.
