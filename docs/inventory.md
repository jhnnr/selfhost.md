# Homelab Inventory & Registry <img src="assets/icons/table.svg" width="20" height="20" alt="Inventory" style="vertical-align: middle;" />

This file is the **Single Source of Truth** for IP addresses, Container/VM IDs, port allocations, databases, and storage mounts.
All modifications to the homelab infrastructure **must** be recorded here to prevent collisions.

---

## 1. Node & Compute Inventory

| ID | Hostname | Type | IPv4 Address | MAC / Interface | CPU / RAM | Primary Role |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| — | `pve01` | Bare Metal | `192.168.100.2`<br>`10.10.0.1` | `vmbr0`<br>`vmbr1` | Host hardware | Proxmox VE 8.x Hypervisor & Gateway |
| **CT 100** | `adguard.lan` | LXC | `10.10.0.2` (Static) | `vmbr1` | 1 vCPU / 512MB | Primary DNS, DHCP & Ad-blocking |
| **CT 101** | `cloudflared.lan` | LXC | `10.10.0.3` (Static) | `vmbr1` | 1 vCPU / 512MB | Cloudflare Tunnel Ingress & DoH |
| **VM 102** | `docker.lan` | VM | DHCP (`10.10.0.x`) | `vmbr1` | 4 vCPU / 16GB RAM | Docker Host (OpenKOS, Firefly, PodPDF, Steam-ish, Portainer) |
| **CT 103** | `rclone.lan` | LXC | DHCP (`10.10.0.x`) | `vmbr1` | 2 vCPU / 2GB RAM | Rclone FUSE (GDrive, TAS), Samba server |
| **CT 104** | `plex.lan` | LXC | DHCP (`10.10.0.x`) | `vmbr1` | 4 vCPU / 4GB RAM | Plex Media Server |
| **CT 105** | `qbit.lan` | LXC | DHCP (`10.10.0.x`) | `vmbr1` | 2 vCPU / 2GB RAM | qBittorrent Downloader |
| **CT 106** | `postgresql.lan`| LXC | DHCP (`10.10.0.x`) | `vmbr1` | 2 vCPU / 2GB RAM | Shared PostgreSQL & Adminer |
| — | `sonarr.lan` | LXC | DHCP (`10.10.0.x`) | `vmbr1` | 2 vCPU / 1GB RAM | Sonarr TV Show Automation |
| **CT 109** | `radarr.lan` | LXC | DHCP (`10.10.0.x`) | `vmbr1` | 2 vCPU / 1GB RAM | Radarr Movie Automation |
| **CT 110** | `prowlarr.lan` | LXC | DHCP (`10.10.0.x`) | `vmbr1` | 1 vCPU / 512MB RAM | Prowlarr Indexer Proxy & Sync |
| **CT 111** | `bazarr.lan` | LXC | DHCP (`10.10.0.x`) | `vmbr1` | 1 vCPU / 512MB RAM | Bazarr Subtitle Automation |
| — | `seer.lan` | LXC | DHCP (`10.10.0.x`) | `vmbr1` | 2 vCPU / 1GB RAM | Jellyseerr / Overseerr Discovery |
| — | `openvpn-oracle`| Remote VPS | `100.96.0.0/12` (Mesh)| Cloud Mesh | 1 OCPU / 1GB RAM | Remote Access Cloud Mesh Node |

---

## 2. Port Allocation Registry

### Homelab Host & Container Ports

| Port | Proto | Host / Container | Service | Access / Ingress |
| :--- | :--- | :--- | :--- | :--- |
| **53** | TCP/UDP | `adguard.lan` (CT 100) | DNS Server | Internal (`10.10.0.0/24`) |
| **80** | TCP | `postgresql.lan` (CT 106) | Adminer DB Web UI (`/adminer`) | Internal LAN |
| **800** | TCP | `docker.lan` (VM 102) | Firefly III Core Web UI | Internal / Cloudflare Tunnel |
| **810** | TCP | `docker.lan` (VM 102) | Firefly III Data Importer | Internal LAN |
| **1025** | TCP | `docker.lan` (VM 102) | OpenKOS Mailpit SMTP | Internal Docker Stack |
| **2873** | TCP | `docker.lan` (VM 102) | PodPDF (Privacy-First PDF) | Internal / Cloudflare Tunnel |
| **3000** | TCP | `adguard.lan` (CT 100) | AdGuard Home Admin UI | Internal LAN |
| **3112** | TCP | `docker.lan` (VM 102) | Steam-ish Gaming Web UI | Internal LAN |
| **5055** | TCP | `seer.lan` (LXC) | Jellyseerr / Overseerr Web UI | Internal / Cloudflare Tunnel |
| **5432** | TCP | `postgresql.lan` (CT 106) | PostgreSQL Database Service | Internal (`10.10.0.0/24`) |
| **6379** | TCP | `docker.lan` (VM 102) | OpenKOS Redis Cache | Internal Docker Stack |
| **6767** | TCP | `bazarr.lan` (CT 111) | Bazarr Subtitle Management Web UI | Internal LAN |
| **7878** | TCP | `radarr.lan` (CT 109) | Radarr Movie Automation Web UI & API | Internal LAN |
| **8000** | TCP | `docker.lan` (VM 102) | Portainer Edge Agent / HTTP | Internal LAN |
| **8025** | TCP | `docker.lan` (VM 102) | OpenKOS Mailpit Web UI | Internal LAN |
| **8090** | TCP | `qbit.lan` (CT 105) | qBittorrent Web UI & WebAPI | Internal LAN |
| **8181** | TCP | `docker.lan` (VM 102) | OpenKOS Web Platform | Internal / Cloudflare Tunnel |
| **8989** | TCP | `sonarr.lan` (LXC) | Sonarr Web UI & API | Internal LAN |
| **9443** | TCP | `docker.lan` (VM 102) | Portainer Server HTTPS UI | Internal LAN |
| **9696** | TCP | `prowlarr.lan` (CT 110) | Prowlarr Indexer Proxy Web UI & API | Internal LAN |
| **32400**| TCP | `plex.lan` (CT 104) | Plex Media Server UI & Streaming | Internal / Plex Direct |

---

## 3. Database Registry (`postgresql.lan` / CT 106)

| Database Name | Owner / User | Port | Host Application | Backup Strategy |
| :--- | :--- | :--- | :--- | :--- |
| `openkos` | `openkos` | `5432` | OpenKOS Suite on `docker.lan` | Daily pg_dump / Proxmox backup |
| `firefly` | `firefly` | `5432` | Firefly III Core on `docker.lan` | Daily pg_dump / Proxmox backup |

---

## 4. Storage & Filesystem Mount Registry

| Mount Source | Protocol / Mechanism | Mount Target (Host / CT) | Purpose |
| :--- | :--- | :--- | :--- |
| `remote:plex` | Rclone FUSE | `rclone.lan`:`/mnt/gdrive/plex` | Google Drive cloud media storage |
| Telegram Bot / Chat | TAS FUSE Daemon | `rclone.lan`:`/mnt/tas` | Telegram as Storage filesystem |
| `//rclone.lan/gdrive` | Samba (SMB) | `pve01`:`/mnt/pve/smb-rclone.lan/Media` | Host-level Proxmox storage mount via `/etc/fstab` |
| `/mnt/pve/smb-rclone.lan/Media` | Proxmox Bind Mount | `plex.lan`:`/mnt/media` | Final Plex library files (Movies ID 2, TV ID 3) |
| `/mnt/pve/smb-rclone.lan/Media` | Proxmox Bind Mount | `qbit.lan`:`/mnt/media` | Torrent download seeding and target destination |
| `/mnt/pve/smb-rclone.lan/Media` | Proxmox Bind Mount | `radarr.lan`:`/mnt/media` | Movie library directory (`/mnt/media/Movies`) |
| `/mnt/pve/smb-rclone.lan/Media` | Proxmox Bind Mount | `bazarr.lan`:`/mnt/media` | Subtitle file read/write access |
| `/mnt/media/TV` | Local / NFS / Bind | `sonarr.lan`:`/mnt/media/TV` | Sonarr root TV library folder |
