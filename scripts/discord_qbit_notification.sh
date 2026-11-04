#!/usr/bin/env bash
# ==============================================================================
# Script: discord_qbit_notification.sh
# Path on CT 105: /root/.config/qBittorrent/discord_qbit_notification.sh
#
# Purpose:
#   Post-Download Notification & Plex Library Refresh Script for qBittorrent.
#   - Refreshes corresponding Plex libraries (Movies: Section 2, TV: Section 3).
#   - Sends rich Discord webhook embeds for non-Arr downloads.
#   - Skips notifications for Arr-managed categories (tv-sonarr, radarr) to
#     prevent duplicate alerts.
#
# qBittorrent Setup:
#   Options -> Downloads -> "Run external program on torrent completion":
#   /root/.config/qBittorrent/discord_qbit_notification.sh "%N" "%Z" "%F" "%T" "%L" "%R"
# ==============================================================================

# --- CONFIGURATION (Sanitized) ---
discord_webhook_url="<DISCORD_WEBHOOK_URL>"

# Plex Server Configuration
PLEX_URL="http://plex.lan:32400"
PLEX_TOKEN="<PLEX_TOKEN>"
PLEX_MOVIES_SECTION="2"            # Section ID for Movies
PLEX_TV_SECTION="3"                # Section ID for TV Shows

# --- INPUT ARGUMENTS FROM QBITTORRENT ---
torrent_name="$1"
size="$2"
files="$3"
tracker="$4"
category="$5"
path="$6"

# Helper function to convert bytes into human-readable format
calculate_size() {
    if command -v numfmt >/dev/null 2>&1; then
        echo "$size" | numfmt --to=iec
    else
        echo "$size"
    fi
}

size_message=$(calculate_size)

# Case-insensitive category check
cat_lower=$(echo "$category" | tr '[:upper:]' '[:lower:]')

# ==============================================================================
# 1. TRIGGER PLEX LIBRARY REFRESH
# ==============================================================================
trigger_plex_refresh() {
    local section_id="$1"
    local section_name="$2"

    if [ -n "$PLEX_TOKEN" ] && [ "$PLEX_TOKEN" != "<PLEX_TOKEN>" ] && [ "$PLEX_TOKEN" != "YOUR_PLEX_TOKEN_HERE" ]; then
        echo "[Plex] Triggering scan for $section_name (Section ID: $section_id)..."
        curl -s -G "$PLEX_URL/library/sections/$section_id/refresh" \
            --data-urlencode "X-Plex-Token=$PLEX_TOKEN" >/dev/null 2>&1
    else
        echo "[Plex] Skipped: PLEX_TOKEN is not configured."
    fi
}

case "$cat_lower" in
    "tv"|"tv shows"|"tv-shows"|"television")
        trigger_plex_refresh "$PLEX_TV_SECTION" "TV Shows"
        ;;
    "movies"|"movie"|"4k movies"|"radarr"|"movies-radarr")
        trigger_plex_refresh "$PLEX_MOVIES_SECTION" "Movies"
        ;;
esac

# ==============================================================================
# 2. DISCORD NOTIFICATION (EXCLUDE Arr Categories: tv-sonarr & radarr)
# ==============================================================================
# Skip Discord notification for categories handled by Sonarr or Radarr
# (Prevents duplicate notifications since the Arrs manage post-import notifications)
if [ "$cat_lower" == "tv-sonarr" ] || [ "$cat_lower" == "sonarr" ] || \
   [ "$cat_lower" == "radarr" ] || [ "$cat_lower" == "movies-radarr" ]; then
    echo "[$torrent_name] Category '$category' is managed by Sonarr/Radarr. Discord notification skipped."
    exit 0
fi

# Determine download label for embed
case "$cat_lower" in
    "readarr")
        download_type="Readarr"
        ;;
    "4k movies")
        download_type="4K Movie"
        ;;
    "movies")
        download_type="Watch Movie"
        ;;
    "tv"|"tv shows")
        download_type="Watch TV Show"
        ;;
    "alternative")
        download_type="Alt"
        ;;
    "books")
        download_type="Book"
        ;;
    *)
        download_type="Uncategorised"
        ;;
esac

# Construct JSON payload securely using python3 (avoids breakages from quotes or brackets in torrent names)
if command -v python3 >/dev/null 2>&1; then
    payload=$(python3 -c '
import json, sys
t_name, sz, fls, trk, pth = sys.argv[1:6]
data = {
    "embeds": [{
        "author": {"name": "qBittorrent", "icon_url": "https://i.imgur.com/6LTKLgZ.jpg"},
        "title": f"{t_name} download completed",
        "color": 7506394,
        "fields": [
            {"name": "Torrent", "value": t_name},
            {"name": "Size", "value": sz, "inline": True},
            {"name": "Files", "value": fls, "inline": True},
            {"name": "Tracker", "value": trk},
            {"name": "Save Path", "value": pth}
        ]
    }]
}
print(json.dumps(data))
' "$torrent_name" "$size_message" "$files" "$tracker" "$path")
else
    # Fallback raw payload if python3 is not available
    escaped_name=$(echo "$torrent_name" | sed 's/"/\\"/g')
    escaped_path=$(echo "$path" | sed 's/"/\\"/g')
    payload='{
        "embeds": [
            {
                "author": {"name": "qBittorrent", "icon_url": "https://i.imgur.com/6LTKLgZ.jpg"},
                "title": "'"$escaped_name"' download completed",
                "color": 7506394,
                "fields": [
                    {"name": "Torrent", "value": "'"$escaped_name"'"},
                    {"name": "Size", "value": "'"$size_message"'", "inline": true},
                    {"name": "Files", "value": "'"$files"'", "inline": true},
                    {"name": "Tracker", "value": "'"$tracker"'"},
                    {"name": "Save Path", "value": "'"$escaped_path"'"}
                ]
            }
        ]
    }'
fi

# Send payload to Discord
if [ -n "$discord_webhook_url" ] && [ "$discord_webhook_url" != "<DISCORD_WEBHOOK_URL>" ]; then
    curl -s -H "Content-Type: application/json" -X POST -d "$payload" "$discord_webhook_url" >/dev/null 2>&1
    echo "[$torrent_name] ${download_type} completed. Discord notification sent."
else
    echo "[$torrent_name] Skipped: discord_webhook_url is not configured."
fi

exit 0
