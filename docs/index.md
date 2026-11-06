# Selfhost.md — Homelab Documentation & Architecture

Welcome to the central documentation portal for my personal homelab infrastructure. This site serves as the **Single Source of Truth (SSoT)** for hypervisors, network segmentation, LXC containers, Docker services, cloud storage mounts, and media automation pipelines.

---

## Quick Navigation

| Section | Description | Link |
| :--- | :--- | :--- |
| <img src="assets/icons/network.svg" width="18" height="18" alt="Network" style="vertical-align: middle;" /> **Infrastructure Map** | Topology diagrams, network bridges, and container layout | [View Map](infrastructure-map.md) |
| <img src="assets/icons/table.svg" width="18" height="18" alt="Table" style="vertical-align: middle;" /> **Inventory & Registry** | Central registry for IPs, Container IDs, exposed ports, and databases | [View Inventory](inventory.md) |
| <img src="assets/icons/storage.svg" width="18" height="18" alt="Storage" style="vertical-align: middle;" /> **Storage Architecture** | Multi-tier pipeline: GDrive, TAS, Rclone FUSE, SMB, and Bind Mounts | [View Pipeline](storage/architecture.md) |
| <img src="assets/icons/cloud.svg" width="18" height="18" alt="Cloud" style="vertical-align: middle;" /> **Network & Routing** | Subnet isolation, AdGuard DNS/DHCP, Cloudflare Tunnels, and VPN mesh | [View Network](network/topology.md) |

---

## Node Overview

| Node | ID / Hostname | Type | IP Address | Primary Roles |
| :--- | :--- | :--- | :--- | :--- |
| **pve01** | [`pve01`](nodes/pve01.md) | Bare Metal Host | `192.168.100.2` / `10.10.0.1` | Proxmox VE Hypervisor, Subnet Gateway, SMB Mounts |
| **AdGuard** | `adguard.lan` | LXC (CT 100) | `10.10.0.2` | Primary DNS (:53), DHCP Server, Ad-blocking (:3000) |
| **Cloudflared**| `cloudflared.lan`| LXC (CT 101) | `10.10.0.3` | Cloudflare Zero-Trust Tunnel Ingress & DoH Proxy |
| **Docker Host**| `docker.lan` | VM 102 (16GB) | DHCP (`10.10.0.x`) | OpenKOS, Firefly III, PodPDF, Steam-ish, Portainer |
| **Rclone** | `rclone.lan` | LXC (CT 103) | DHCP (`10.10.0.x`) | GDrive & Telegram (TAS) FUSE Mounts, Samba Server |
| **Plex** | `plex.lan` | LXC (CT 104) | DHCP (`10.10.0.x`) | Plex Media Server (:32400) |
| **qBittorrent**| [`qbit.lan`](containers/ct105-qbit.md) | LXC (CT 105) | DHCP (`10.10.0.x`) | Torrent Downloader (:8090, API Key Auth) |
| **PostgreSQL** | `postgresql.lan` | LXC (CT 106) | DHCP (`10.10.0.x`) | Central Database Server (:5432) & Adminer (:80/adminer) |
| **Sonarr** | `sonarr.lan` | LXC | DHCP (`10.10.0.x`) | TV Automation (:8989), Relocate Script Hooks |
| **Radarr** | `radarr.lan` | LXC (CT 109) | DHCP (`10.10.0.x`) | Movie Automation (:7878), Movie Library (/mnt/media/Movies) |
| **Prowlarr** | `prowlarr.lan` | LXC (CT 110) | DHCP (`10.10.0.x`) | Indexer Manager & Proxy (:9696), Sync to Sonarr/Radarr |
| **Bazarr** | `bazarr.lan` | LXC (CT 111) | DHCP (`10.10.0.x`) | Subtitle Automation (:6767), Sync to Sonarr/Radarr |
| **Seer** | `seer.lan` | LXC | DHCP (`10.10.0.x`) | Jellyseerr / Overseerr Media Requests (:5055) |
| **Cloud Mesh** | `openvpn-oracle`| Oracle VPS | `100.96.0.0/12` Mesh | Remote Access Mesh Node & Fallback Tunnel |

---

## Network at a Glance

- **Home Subnet:** `192.168.100.0/24` (ISP Router `192.168.100.1` has static route `10.10.0.0/24` via `192.168.100.2`).
- **Homelab Subnet:** `10.10.0.0/24` on Proxmox bridge `vmbr1` (Gateway `10.10.0.1`).
- **DNS & DHCP:** Handled entirely by AdGuard Home on CT 100 (`10.10.0.2`).
- **Ingress:** All external public traffic enters through Cloudflare Zero-Trust Tunnels via `cloudflared.lan` (CT 101) — no open inbound ports on the ISP router.

---

## Security & Git Hygiene

- This repository adheres to a **Zero Secrets Policy**.
- All passwords, private keys, tokens, and authorization headers are scrubbed and replaced with standardized placeholder tags (e.g. `<TOKEN>`).
