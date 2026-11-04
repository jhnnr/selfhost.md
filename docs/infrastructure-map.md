# Homelab Infrastructure Map

This document serves as the high-level architecture overview and network topology map for the homelab environment hosted on Proxmox VE.

---

## Visual Architecture & Network Topology

### ASCII Topology Diagram

```text
[ Public Internet / Mobile Data ]
             |
 +-----------+-----------+
 |                       |
 v                       v
[ Home ISP Router ]   [ Cloudflare Edge / Mesh ]
(br0: 192.168.100.1/24) (Mesh 100.96.0.0/12)
Static Route: 10.10.0.0/24
via 192.168.100.2
 +-----------+-----------+
 |                       |
 |                       v
 |             +-------------------------+
 |             | [ openvpn-oracle VPS ]  |
 |             | (Cloud Mesh Node)       |
 |             +------------+------------+
 |                          |
 v                          v
+----------------------------------------+
| Proxmox Host (pve01)                   |
| vmbr0: 192.168.100.2                   |
| vmbr1: 10.10.0.1 (GW)                  |
+-------------------+--------------------+
                    |
====================+======================================== vmbr1
10.10.0.0/24 Subnet | (DHCP & DNS via 10.10.0.2)
====================+========================================
                    |
                    v
+--> [CT 101] cloudflared (10.10.0.3 / cloudflared.lan)
|    |-- Forwards DoH & Tunnel traffic to 10.10.0.0/24
|
+--> [CT 100] adguard (10.10.0.2 / adguard.home.server)
|    |-- Primary DNS (:53), DHCP Server, Web UI (:3000)
|
+--> [VM 102] docker (DHCP / docker.lan) [16GB RAM]
|    |-- OpenKOS Suite -------------------> [Uses CT 106]
|    |   |-- openkos-web-1 (:8181 -> :8080)
|    |   |-- openkos-queue-1 & openkos-scheduler-1
|    |   |-- openkos-redis-1 (:6379)
|    |   +-- openkos-mailpit-1 (:8025 / :1025)
|    |-- Firefly III Suite ---------------> [Uses CT 106]
|    |   |-- firefly_iii_core (:800 -> :8080)
|    |   |-- firefly_iii_importer (:810 -> :8080)
|    |   +-- firefly_iii_cron
|    |-- Privacy-First PDF
|    |   +-- podpdf (:2873 -> :8080)
|    |-- Gaming & Administration
|    |   |-- steam-ish (:3112 -> :3000)
|    |   +-- portainer (:9443 / :8000)
|    +-- System Management
|
+--> [CT 106] postgresql (DHCP / postgresql.lan)
|    +-- Shared PostgreSQL (:5432) & Adminer (:80/adminer)
|
+--> [CT 103] rclone (DHCP / rclone.lan)
|    +-- Rclone FUSE (gdrive:plex) + Samba Server (//rclone.lan/gdrive)
|
+--> [CT 104] plex (DHCP / plex.lan)
|    +-- Bind Mount: /mnt/media <--- Host SMB (/mnt/pve/smb-rclone.lan/Media)
|
+--> [CT 105] qbit (DHCP / qbit.lan)
     +-- Bind Mount: /mnt/media <--- Host SMB (/mnt/pve/smb-rclone.lan/Media)
```

### Mermaid Architecture Diagram

```mermaid
graph TD
    subgraph External["External / Cloud"]
        WAN[Public Internet / Mobile Data]
        CF[Cloudflare Edge / Tunnel]
        VPS[Oracle VPS: openvpn-oracle<br>Mesh: 100.96.0.0/12]
        WAN --> CF
        WAN --> VPS
    end

    subgraph Physical["Physical Network"]
        Router[ISP Router<br>192.168.100.1/24<br>Static Route: 10.10.0.0/24 via 192.168.100.2]
    end

    subgraph Host["Proxmox VE Host (pve01)"]
        VMBR0[vmbr0: 192.168.100.2]
        VMBR1[vmbr1: 10.10.0.1 Gateway]
        HostSMB["/mnt/pve/smb-rclone.lan/Media<br>(Host SMB Mount)"]
    end

    Router --> VMBR0
    CF --> CT101
    VPS --> VMBR0

    subgraph Subnet["Homelab Subnet (10.10.0.0/24)"]
        CT100["[CT 100] adguard.lan<br>10.10.0.2<br>DNS :53 | DHCP | UI :3000"]
        CT101["[CT 101] cloudflared.lan<br>10.10.0.3<br>Tunnel & DoH"]
        VM102["[VM 102] docker.lan<br>16GB RAM<br>OpenKOS, Firefly, PodPDF, Portainer"]
        CT106["[CT 106] postgresql.lan<br>PostgreSQL :5432 | Adminer :80"]
        CT103["[CT 103] rclone.lan<br>FUSE GDrive & TAS<br>Samba: //rclone.lan/gdrive"]
        CT104["[CT 104] plex.lan<br>Plex Media Server :32400"]
        CT105["[CT 105] qbit.lan<br>qBittorrent :8090"]
        Sonarr["sonarr.lan<br>TV Automation :8989"]
        Seer["seer.lan<br>Overseerr/Jellyseerr :5055"]
    end

    VMBR1 --> CT100
    VMBR1 --> CT101
    VMBR1 --> VM102
    VMBR1 --> CT106
    VMBR1 --> CT103
    VMBR1 --> CT104
    VMBR1 --> CT105
    VMBR1 --> Sonarr
    VMBR1 --> Seer

    %% Storage & Service Links
    CT103 -- "Samba Export" --> HostSMB
    HostSMB -- "Bind Mount /mnt/media" --> CT104
    HostSMB -- "Bind Mount /mnt/media" --> CT105
    VM102 -- "DB Connection" --> CT106
    Seer -- "Requests" --> Sonarr
    Seer -- "Availability check" --> CT104
    Sonarr -- "Grab releases" --> CT105
```

---

## Node Details & Responsibilities

### 1. `pve01` (Proxmox VE Host) <img src="/assets/icons/server.svg" width="18" height="18" alt="Server" style="vertical-align: middle;" />
- **Role:** Bare-metal hypervisor host running Proxmox VE.
- **Network Interfaces:**
  - `vmbr0`: Bridged to physical LAN (`192.168.100.2/24`).
  - `vmbr1`: Isolated internal bridge serving the `10.10.0.0/24` homelab subnet (`10.10.0.1` gateway).
- **Storage Integration:** SMB mounts are managed directly at the host level.
- **Key Files:**
  - `/etc/fstab` — Handles mount points on boot, mounting `//rclone.lan/gdrive` at `/mnt/pve/smb-rclone.lan/Media`.

---

### 2. `adguard.lan` (CT 100) <img src="/assets/icons/shield.svg" width="18" height="18" alt="Shield" style="vertical-align: middle;" />
- **Role:** Primary local DNS server, DHCP daemon, and ad-blocking gateway.
- **IP:** `10.10.0.2` (Static)
- **Services & Ports:**
  - DNS Server: Port `53` (TCP/UDP)
  - Web UI: Port `3000` (HTTP)
  - DHCP Server for `10.10.0.0/24` subnet.

---

### 3. `cloudflared.lan` (CT 101) <img src="/assets/icons/cloud.svg" width="18" height="18" alt="Cloud" style="vertical-align: middle;" />
- **Role:** Cloudflare Zero-Trust Tunnel gateway providing secure external ingress to internal homelab services without opening inbound firewall ports on the ISP router.
- **IP:** `10.10.0.3` (Static)
- **Features:** Forwards DNS-over-HTTPS (DoH) and tunnel traffic to the `10.10.0.0/24` network.

---

### 4. `rclone.lan` (CT 103) <img src="/assets/icons/storage.svg" width="18" height="18" alt="Storage" style="vertical-align: middle;" />
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

### 5. `plex.lan` (CT 104) <img src="/assets/icons/play.svg" width="18" height="18" alt="Play" style="vertical-align: middle;" />
- **Role:** Media server running Plex Media Server.
- **Port:** `32400`
- **Storage Path:** `/mnt/media` (LXC bind mount from `pve01`'s `/mnt/pve/smb-rclone.lan/Media`).
- **Plex Section IDs:**
  - **Movies:** Section ID `2`
  - **TV Shows:** Section ID `3`

---

### 6. `sonarr.lan` (LXC Container) <img src="/assets/icons/tv.svg" width="18" height="18" alt="TV" style="vertical-align: middle;" />
- **Role:** Smart TV episode automation daemon. Tracks, grabs, and manages library importing for TV shows.
- **Port:** `8989`
- **Mounts / Paths:**
  - `/mnt/media/TV` — Directory for the final local TV library.
- **Integrations & Hooks:**
  - **Download Client:** Connects to `qbit.lan:8090` using a native Bearer Token API Key.
  - **Custom Post-Import Script:** Executes `/root/scripts/qbit-relocate.sh` on download/import events to rename/relocate files in qBittorrent, cleanup local source duplicates, and resume seeding.
- **Key Settings:**
  - `Create Empty Series Folders` enabled to generate root show directories immediately on add.

---

### 7. `seer.lan` (LXC Container) <img src="/assets/icons/search.svg" width="18" height="18" alt="Search" style="vertical-align: middle;" />
- **Role:** Media request and discovery platform (Jellyseerr / Overseerr).
- **Port:** `5055`
- **Integrations:**
  - **Sonarr Connection:** Connects directly to `sonarr.lan` to push requested television shows into Sonarr's monitoring queue.
  - **Plex Connection:** Scrapes `plex.lan` to check file availability before approving user requests.

---

### 8. `qbit.lan` (CT 105) <img src="/assets/icons/download.svg" width="18" height="18" alt="Download" style="vertical-align: middle;" />
- **Documentation:** [`containers/ct105-qbit.md`](containers/ct105-qbit.md)
- **Role:** Torrent downloader handling television and movie file transfers.
- **Port:** `8090`
- **Storage:**
  - Bind mount: `/mnt/media`
  - Save path: `/downloads/tv-sonarr` — Designated target path for television files.
- **Key Configurations:**
  - **WebAPI v2.14+ API Key Auth:** Generates bearer tokens for passwordless external scripts.
  - **Path Mapping:** Remote path mappings translate `/downloads/tv-sonarr` to Sonarr's internal access path.
  - **Torrent Completion Hook:** Executes `/root/.config/qBittorrent/discord_qbit_notification.sh` to trigger direct Plex library scans (Movies ID 2, TV ID 3) and send rich Discord notifications for non-Arr downloads.

---

### 9. `docker.lan` (VM 102) <img src="/assets/icons/docker.svg" width="18" height="18" alt="Docker" style="vertical-align: middle;" />
- **Role:** Dedicated Docker VM with 16GB RAM hosting multiple application stacks.
- **Hosted Stacks:**
  - **OpenKOS Suite:** (Uses CT 106 PostgreSQL)
    - `openkos-web-1` (`:8181` -> `:8080`)
    - `openkos-queue-1` & `openkos-scheduler-1`
    - `openkos-redis-1` (`:6379`)
    - `openkos-mailpit-1` (`:8025` / `:1025`)
  - **Firefly III Suite:** (Uses CT 106 PostgreSQL)
    - `firefly_iii_core` (`:800` -> `:8080`)
    - `firefly_iii_importer` (`:810` -> `:8080`)
    - `firefly_iii_cron`
  - **Privacy Tools:**
    - `podpdf` (`:2873` -> `:8080`)
  - **Administration & Gaming:**
    - `steam-ish` (`:3112` -> `:3000`)
    - `portainer` (`:9443` HTTPS / `:8000` HTTP)

---

### 10. `postgresql.lan` (CT 106) <img src="/assets/icons/database.svg" width="18" height="18" alt="Database" style="vertical-align: middle;" />
- **Role:** Dedicated shared database server running PostgreSQL and Adminer.
- **Default Port:** `5432`
- **Adminer Port:** `80` (access at `http://postgresql.lan/adminer`)
- **Hosted Databases:**
  - `openkos` — Primary database for the OpenKOS platform.
  - `firefly` — Primary database for the Firefly III Budgeting App.
- **Standard Administration Commands:**
  - Create new user:
    ```bash
    sudo -u postgres createuser --interactive --pwprompt
    ```
  - Connect to postgres instance:
    ```bash
    psql -h postgresql.lan -U postgres
    ```
  - Assign database ownership:
    ```sql
    ALTER DATABASE db OWNER TO new_user;
    ```
