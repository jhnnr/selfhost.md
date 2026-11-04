# Sonarr Post-Import Relocation Hook <img src="/assets/icons/terminal.svg" width="20" height="20" alt="Script" style="vertical-align: middle;" />

This document details `/root/scripts/qbit-relocate.sh`, which is invoked on **Sonarr** after downloading and importing TV episodes.

---

## Overview

When Sonarr finishes importing an episode into the main library directory (`/mnt/media/TV`):
1. Executes `/root/scripts/qbit-relocate.sh`.
2. Connects to `qbit.lan:8090` via WebAPI v2.14+ using a bearer token.
3. Relocates the torrent save path to the final destination so seeding can continue from the permanent location.
4. Prunes temporary source duplicate files.

---

## Sonarr Setup

1. In Sonarr, navigate to **Settings** -> **Connect**.
2. Add a **Custom Script** connection.
3. Path: `/root/scripts/qbit-relocate.sh`.
4. Trigger on: **On Download**, **On Upgrade**, **On Rename**.

---

## Script Template

```bash
#!/usr/bin/env bash
# ==============================================================================
# Script: qbit-relocate.sh (Example Template)
# Role: Sonarr Custom Post-Import Script
# Path: /root/scripts/qbit-relocate.sh
# Purpose:
#   Invoked by Sonarr upon successful download and import.
#   - Communicates with qBittorrent WebAPI (v2.14+) using Bearer Token Auth
#   - Relocates/renames downloaded files in qBittorrent
#   - Cleans up local temporary download source duplicates
#   - Resumes or continues seeding from the final library location
# ==============================================================================

set -euo pipefail

# Configuration
QBIT_HOST="http://qbit.lan:8090"
QBIT_AUTH_TOKEN="<REDACTED_QBIT_BEARER_TOKEN>" # Configure in environment or secrets manager

# Sonarr Event Variables provided on execution:
#   sonarr_eventtype (e.g. Download, Upgrade, Rename)
#   sonarr_series_title
#   sonarr_episodefile_path
#   sonarr_download_id (Torrent Hash)
#   sonarr_download_client

EVENT_TYPE="${sonarr_eventtype:-}"
TORRENT_HASH="${sonarr_download_id:-}"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] Sonarr Post-Import Hook Triggered: Event=${EVENT_TYPE}"

if [[ "${EVENT_TYPE}" != "Download" && "${EVENT_TYPE}" != "Upgrade" ]]; then
    echo "Event type ${EVENT_TYPE} does not require relocation. Exiting."
    exit 0
fi

if [[ -z "${TORRENT_HASH}" ]]; then
    echo "Warning: No download ID (torrent hash) provided. Exiting."
    exit 0
fi

echo "Relocating and resuming torrent: ${TORRENT_HASH}"

# Example API call to qBittorrent WebAPI v2.14+ to set location or resume
# curl -s -X POST "${QBIT_HOST}/api/v2/torrents/setLocation" \
#     -H "Authorization: Bearer ${QBIT_AUTH_TOKEN}" \
#     --data-urlencode "hashes=${TORRENT_HASH}" \
#     --data-urlencode "location=/mnt/media/TV"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] Relocate hook finished successfully."
exit 0
```
*(Reference template stored in [`scripts/qbit-relocate.sh.example`](https://github.com/jhnnr/selfhost.md/blob/main/scripts/qbit-relocate.sh.example))*
