# 📥 CT 105: `qbit.lan` (qBittorrent Downloader)

This document details the configuration, storage bindings, API integrations, and notification hooks for the dedicated qBittorrent download client.

---

## 1. Container Metadata

| Property | Value |
| :--- | :--- |
| **Container ID** | `CT 105` |
| **Hostname** | `qbit.lan` |
| **IPv4 Address** | Dynamic via DHCP (`10.10.0.x`) with AdGuard DNS rewrite |
| **Network Bridge** | `vmbr1` (Homelab Subnet: `10.10.0.0/24`) |
| **Web UI Port** | `8090` (HTTP) |
| **Authentication** | WebAPI v2.14+ Bearer Token API Key Auth |
| **Storage Bind Mount** | `/mnt/media` ◄── Proxmox host `/mnt/pve/smb-rclone.lan/Media` |
| **Default Download Root** | `/downloads/tv-sonarr` |

---

## 2. Storage & Directory Layout

- **Bind Mount (`mp0`):**
  Host path `/mnt/pve/smb-rclone.lan/Media` is mounted inside the container at `/mnt/media`.
- **Target Directories:**
  - `/downloads/tv-sonarr` — Designated landing directory for automated TV downloads managed by Sonarr.
  - `/mnt/media/TV` — Final library location (used when seeding from library).
  - `/mnt/media/Movies` — Movie library directory.

---

## 3. Post-Download Completion Script

qBittorrent is configured to execute a notification and library scanning script automatically whenever any torrent finishes downloading.

### Hook Location & Configuration
- **Script Path:** `/root/.config/qBittorrent/discord_qbit_notification.sh`
- **Repository Template:** [`scripts/discord_qbit_notification.sh`](../../scripts/discord_qbit_notification.sh)
- **qBittorrent GUI Setting:**
  *Options* ➔ *Downloads* ➔ Check **"Run external program on torrent completion"**:
  ```bash
  /root/.config/qBittorrent/discord_qbit_notification.sh "%N" "%Z" "%F" "%T" "%L" "%R"
  ```

### Script Arguments Passed
| Parameter | qBittorrent Token | Description |
| :--- | :--- | :--- |
| `$1` | `%N` | Torrent name |
| `$2` | `%Z` | Torrent total size (converted via `numfmt` to IEC) |
| `$3` | `%F` | Number of files in torrent |
| `$4` | `%T` | Tracker hostname / URL |
| `$5` | `%L` | Category tag (e.g. `tv-sonarr`, `movies`, `tv`, `readarr`) |
| `$6` | `%R` | Torrent root / save path |

### Script Responsibilities

1. **Direct Plex Library Scans:**
   - Triggers Plex Media Server on `plex.lan:32400` using the Plex API token:
     - Categories matching `tv`, `tv shows`, `tv-shows`, `television` ➔ Triggers **TV Shows** (Section ID `3`).
     - Categories matching `movies`, `movie`, `4k movies`, `radarr`, `movies-radarr` ➔ Triggers **Movies** (Section ID `2`).
2. **Discord Embed Notifications:**
   - Dispatches a formatted rich Discord embed webhook displaying torrent name, formatted size, tracker, file count, and destination directory.
3. **Arr Deduplication (Smart Skip):**
   - Automatically **skips Discord notifications** for categories managed by *Arr* applications (such as `tv-sonarr`, `sonarr`, `radarr`, `movies-radarr`). This avoids sending double notifications, as Sonarr/Radarr handle post-import Discord notifications themselves.

---

## 4. Sonarr Integration & Post-Import Relocation

- **Download Client Setup:**
  - Sonarr connects to `qbit.lan:8090` via WebAPI v2.14+ using a bearer token.
  - Category is set to `tv-sonarr`.
- **Remote Path Mappings:**
  - Sonarr maps qBittorrent's `/downloads/tv-sonarr` to Sonarr's local import path.
- **Post-Import Hook (`qbit-relocate.sh`):**
  - Once Sonarr imports an episode, it executes `/root/scripts/qbit-relocate.sh` on Sonarr to update qBittorrent's seeding location to `/mnt/media/TV` and prune local duplicate downloads.
