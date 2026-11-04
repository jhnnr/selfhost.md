# Homelab Storage Architecture & Pipelines <img src="/assets/icons/storage.svg" width="20" height="20" alt="Storage" style="vertical-align: middle;" />

This document details the multi-layered storage architecture connecting Cloud storage, Telegram as Storage (TAS), local Proxmox VE host mounts, and LXC containers.

---

## Storage Pipeline Overview

```text
[ Cloud Providers ]
  |-- Google Drive (Remote: plex)
  +-- Telegram Bot API (TAS)
         |
         |  (rclone FUSE & TAS FUSE mounts)
         v
[ CT 103: rclone.lan ]
  |-- /mnt/gdrive/plex   (Mounted via rclone-gdrive.service)
  |-- /mnt/tas           (Mounted via tas-mount.service & tas-sync.service)
  +-- Samba Server       (Exports //rclone.lan/gdrive)
         |
         |  (Network SMB Share)
         v
[ Proxmox Host: pve01 ]
  +-- /mnt/pve/smb-rclone.lan/Media (Mounted via /etc/fstab)
         |
         |  (LXC Bind Mounts via mp0)
         +----------------------------------------+
         |                                        |
         v                                        v
[ CT 104: plex.lan ]                    [ CT 105: qbit.lan ]
  +-- /mnt/media                          +-- /mnt/media
        |-- Movies (Section ID 2)               +-- /downloads/tv-sonarr
        +-- TV (Section ID 3)
```

---

## 1. Storage Services on `rclone.lan` (CT 103)

### Systemd Units

#### `rclone-gdrive.service`
Mounts the Google Drive remote to the local filesystem using Rclone FUSE with optimized caching flags:
- Mount target: `/mnt/gdrive/plex`
- Unit location: `/etc/systemd/system/rclone-gdrive.service`

#### `tas-mount.service` & `tas-sync.service`
- **Mount Service:** Mounts Telegram as Storage (TAS) to `/mnt/tas`.
- **Sync Service:** Periodically runs synchronization jobs to push/pull data chunks across Telegram channels.
- Unit locations:
  - `/etc/systemd/system/tas-mount.service`
  - `/etc/systemd/system/tas-sync.service`

#### `plex-watcher.service`
- Monitors local filesystem events on `/mnt/gdrive/plex` and sends HTTP notification webhooks to Plex Media Server on `plex.lan` to initiate surgical section scans when new media arrives.
- Unit location: `/etc/systemd/system/plex-watcher.service`

---

## 2. Host Storage Configuration on `pve01`

Proxmox VE connects directly to the Samba share exposed by `rclone.lan` to make the filesystem available for container bind mounts.

### `/etc/fstab` Mount Entry
```text
//rclone.lan/gdrive /mnt/pve/smb-rclone.lan/Media cifs _netdev,credentials=/etc/pve/priv/smb-rclone.cred,uid=1000,gid=1000,iocharset=utf8 0 0
```

---

## 3. Container Bind Mounts

In Proxmox LXC configuration files (`/etc/pve/lxc/<CTID>.conf`), the host path is passed directly into containers:

### CT 104 (`plex.lan`)
```ini
mp0: /mnt/pve/smb-rclone.lan/Media,mp=/mnt/media
```

### CT 105 (`qbit.lan`)
```ini
mp0: /mnt/pve/smb-rclone.lan/Media,mp=/mnt/media
```

---

## 4. Media Ingestion & Relocation Flow

1. **Discovery & Request:** User requests media on `seer.lan` (Jellyseerr).
2. **TV Automation:** `seer.lan` passes request to `sonarr.lan`.
3. **Grab & Download:** `sonarr.lan` instructs `qbit.lan:8090` (using Bearer Token) to grab release, saving to `/downloads/tv-sonarr`.
4. **Torrent Completion Hook (`discord_qbit_notification.sh`):**
   - On completion, qBittorrent executes `/root/.config/qBittorrent/discord_qbit_notification.sh`.
   - Directly triggers Plex refresh for Movies (Section 2) or TV (Section 3).
   - Dispatches Discord embed notifications for non-Arr categories (skips `tv-sonarr`, `radarr` to prevent duplicate alerts).
5. **Post-Import Relocation Hook (`qbit-relocate.sh`):**
   - When download completes, `sonarr.lan` invokes `/root/scripts/qbit-relocate.sh`.
   - The script renames/relocates the media to the final `/mnt/media/TV` directory, cleans up temporary local files, and triggers qBittorrent to update its seeding target without duplicate storage consumption.
6. **Plex Library Update:** `plex-watcher.service` on `rclone.lan` or Sonarr's notification triggers Plex (`plex.lan`) to refresh TV Shows (Section `3`).
