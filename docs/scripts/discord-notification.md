# qBittorrent Discord Notification & Plex Refresh Script <img src="../assets/icons/bell.svg" width="20" height="20" alt="Notification" style="vertical-align: middle;" />

This document provides the reference implementation and configuration guide for `/root/.config/qBittorrent/discord_qbit_notification.sh` running on **CT 105 (`qbit.lan`)**.

---

## Overview

The script triggers automatically upon torrent completion in qBittorrent:
1. **Refreshes Plex Libraries:**
   - TV Shows (Section `3`) for TV categories (`tv`, `tv shows`, `television`).
   - Movies (Section `2`) for movie categories (`movies`, `movie`, `4k movies`, `radarr`).
2. **Dispatches Rich Discord Webhook Embeds:**
   - Includes torrent name, human-readable size, file count, tracker, and save path.
3. **Smart Notification Deduplication:**
   - Skips Discord alerts for categories managed by *Arr* services (`tv-sonarr`, `sonarr`, `radarr`) to prevent duplicate notifications.

---

## qBittorrent Configuration

In qBittorrent WebUI:
1. Navigate to **Options** -> **Downloads**.
2. Scroll down to **"Run external program"**.
3. Enable **"Run on torrent finished"** and enter:
   ```bash
   /root/.config/qBittorrent/discord_qbit_notification.sh "%N" "%Z" "%F" "%T" "%L" "%R"
   ```

---

## Script Source Code

```bash
--8<-- "scripts/discord_qbit_notification.sh"
```
*(Source code embedded directly from [`scripts/discord_qbit_notification.sh`](https://github.com/jhnnr/selfhost.md/blob/main/scripts/discord_qbit_notification.sh))*
