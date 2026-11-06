# CT 110: `prowlarr.lan` (Prowlarr Indexer Proxy) <img src="../assets/icons/search.svg" width="20" height="20" alt="Search" style="vertical-align: middle;" />

This document details the configuration and service sync mappings for the centralized Prowlarr indexer proxy.

---

## 1. Container Metadata

| Property | Value |
| :--- | :--- |
| **Container ID** | `CT 110` |
| **Hostname** | `prowlarr.lan` |
| **IPv4 Address** | Dynamic via DHCP (`10.10.0.x`) with AdGuard DNS rewrite |
| **Network Bridge** | `vmbr1` (Homelab Subnet: `10.10.0.0/24`) |
| **Web UI Port** | `9696` (HTTP) |
| **Purpose** | Centralized Usenet & Torrent Indexer Management |

---

## 2. Connected Applications

Prowlarr manages API keys and search limits for trackers, automatically syncing indexer configurations to downstream Arr apps:

- **Sonarr (`sonarr.lan:8989`):** Synchronizes television trackers and release search endpoints.
- **Radarr (`radarr.lan:7878` / CT 109):** Synchronizes movie trackers and custom release profiles.
