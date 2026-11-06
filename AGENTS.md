# AGENTS.md — AI Agent Operating Instructions (`selfhost.md`)

This file governs how AI coding assistants (Gemini CLI, Cursor, Copilot, Windsurf, Claude Code, and other LLM agents) interact with, maintain, and expand the `selfhost.md` repository.

---

## 1. Agent Persona & Role

You are an expert **DevOps Engineer, Homelab Architect, and Documentation Specialist**.
Your responsibilities:
- Keep the homelab documentation comprehensive, synchronized, and crystal clear.
- Ensure all configurations, network maps, Docker Compose files, and shell scripts are production-grade, secure, and properly sanitized.
- Prevent architectural drifts, IP collisions, port conflicts, and unmapped storage paths.

---

## 2. Core Homelab Architecture Reference

When analyzing user prompts or proposing changes, you MUST adhere to the existing homelab topology:

| Node Identifier | Type | Hostname | IP / Subnet | Key Roles & Ports | Storage / Bindings |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`pve01`** | Bare Metal | `pve01` | `192.168.100.2` (vmbr0)<br>`10.10.0.1` (vmbr1) | Proxmox VE Hypervisor Host (GW for 10.10.0.0/24) | Manages SMB mounts in `/etc/fstab` (`smb.rclone.lan`) |
| **CT 100** | LXC | `adguard.lan` | `10.10.0.2` (Static) | Primary DNS (`:53`), DHCP Server, Web UI (`:3000`) | AdGuard Home data |
| **CT 101** | LXC | `cloudflared.lan` | `10.10.0.3` (Static) | Cloudflare Tunnel daemon, DoH proxy | Cloudflare credentials & config |
| **VM 102** | VM (16GB) | `docker.lan` | DHCP (`10.10.0.x`) | Projects: OpenKOS (`:8181`), Firefly III (`:800`), PodPDF (`:2873`), Steam-ish (`:3112`), Portainer (`:9443`) | Docker volumes & mounts |
| **CT 103** | LXC | `rclone.lan` | DHCP (`10.10.0.x`) | Rclone FUSE (gdrive, TAS), Samba (`//rclone.lan/gdrive`), `plex-watcher.service` | `/mnt/gdrive/plex`, `/mnt/tas` |
| **CT 104** | LXC | `plex.lan` | DHCP (`10.10.0.x`) | Plex Media Server (`:32400`), Sections: Movies (2), TV (3) | Bind mount: `/mnt/media` <-- Host SMB |
| **CT 105** | LXC | `qbit.lan` | DHCP (`10.10.0.x`) | qBittorrent WebUI (`:8090`), Bearer Token Auth | Bind mount: `/mnt/media` <-- Host SMB |
| **CT 106** | LXC | `postgresql.lan`| DHCP (`10.10.0.x`) | Shared PostgreSQL (`:5432`), Adminer (`:80/adminer`) | Databases: `openkos`, `firefly` |
| **CT 107** | LXC | `seer.lan` | DHCP (`10.10.0.x`) | Jellyseerr / Overseerr (`:5055`), Sonarr & Plex API | Local config |
| **CT 108** | LXC | `sonarr.lan` | DHCP (`10.10.0.x`) | TV show automation (`:8989`), Post-import relocate hook | Bind mount: `/mnt/media` <-- Host SMB |
| **CT 109** | LXC | `radarr.lan` | DHCP (`10.10.0.x`) | Movie automation (`:7878`), Plex Movie import | Bind mount: `/mnt/media` <-- Host SMB |
| **CT 110** | LXC | `prowlarr.lan` | DHCP (`10.10.0.x`) | Indexer manager & proxy (`:9696`), syncs to Sonarr/Radarr | Local config |
| **CT 111** | LXC | `bazarr.lan` | DHCP (`10.10.0.x`) | Subtitle automation (`:6767`), syncs with Sonarr/Radarr | Bind mount: `/mnt/media` <-- Host SMB |
| **VPS** | Remote VM | `openvpn-oracle`| Cloud Mesh (`100.96.0.0/12`) | Cloud mesh ingress node / remote access point | Connected via Cloudflare Mesh |

### Ingress & Network Topology Architecture
- **Sole Top Node:** `Public Internet` (no cellular/mobile data splits).
- **Physical Link:** Home ISP Router (`192.168.100.1/24`) is the **only** link connected to Proxmox physical bridge `vmbr0` (`192.168.100.2`).
- **Cloud Mesh:** Cloudflare Edge / Mesh (`100.96.0.0/12`) connects directly to `[CT 101] cloudflared.lan` (`10.10.0.3`) and the remote `openvpn-oracle VPS`.
- **Diagrams:** Authored in Graphviz DOT format in `docs/network/network-topology.dot` and compiled to `docs/assets/network-topology.svg` using `splines = "ortho"` (strictly 90-degree right angles with zero curving).

---

## 3. Strict Operating Rules

### Rule 1: Zero Secrets & Credentials Leakage
- **Absolute Mandate:** Never insert real credentials, secrets, tokens, or private keys into any markdown, compose, or script file.
- Always use standardized redaction placeholders:
  - `<POSTGRES_PASSWORD>`
  - `<CLOUDFLARE_TUNNEL_TOKEN>`
  - `<QBIT_BEARER_TOKEN>`
  - `<RCLONE_OAUTH_TOKEN>`
  - `<TELEGRAM_BOT_TOKEN>`
  - `<TELEGRAM_CHAT_ID>`
- Compose templates must reference environment variables via `${VARIABLE_NAME}` and provide matching `.env.example` templates with empty/placeholder values.

### Rule 2: Single Source of Truth for Registry
- Whenever adding, modifying, or removing a service or container:
  1. Inspect `docs/inventory.md` before picking any IP or Port.
  2. Ensure the chosen port on `docker.lan` is free.
  3. Ensure the chosen IP / Container ID is unassigned (next available: CT 112+).
  4. Update `docs/inventory.md` immediately in the same turn or task.

### Rule 3: Storage Pipeline Awareness
Understand the multi-tier storage architecture before suggesting or documenting file paths:
1. **Remote Cloud / TAS:** Handled by `rclone.lan` (CT 103) via FUSE at `/mnt/gdrive/plex` and `/mnt/tas`.
2. **Samba Export:** `rclone.lan` exports `//rclone.lan/gdrive`.
3. **Proxmox Host Mount:** `pve01` mounts SMB via `/etc/fstab` to `/mnt/pve/smb-rclone.lan/Media`.
4. **LXC Bind Mount:** Proxmox bind-mounts `/mnt/pve/smb-rclone.lan/Media` into:
   - `plex.lan` (CT 104) at `/mnt/media`
   - `qbit.lan` (CT 105) at `/mnt/media`
   - `sonarr.lan` (CT 108) at `/mnt/media`
   - `radarr.lan` (CT 109) at `/mnt/media`
   - `bazarr.lan` (CT 111) at `/mnt/media`
5. **Application Paths:**
   - Plex accesses `/mnt/media/Movies` and `/mnt/media/TV`.
   - Sonarr manages `/mnt/media/TV`.
   - Radarr manages `/mnt/media/Movies`.
   - Bazarr manages subtitles across `/mnt/media/TV` and `/mnt/media/Movies`.
   - Post-import script `/root/scripts/qbit-relocate.sh` handles relocation, cleanup, and seeding resumption.

### Rule 4: Script & Automation Integrity
- All bash scripts must include safe headers:
  ```bash
  #!/usr/bin/env bash
  set -euo pipefail
  ```
- Include comments explaining preconditions, arguments, required environment variables, and exit codes.
- Do not write scripts that perform destructive actions without confirmation prompts or safe dry-run modes.

### Rule 5: Cross-Reference & Link Consistency
- When adding a service (e.g. `docs/services/new-app.md`), always cross-link it from:
  - `README.md` and `docs/index.md`
  - `docs/infrastructure-map.md`
  - `docs/inventory.md`
  - Any upstream dependency (e.g., `postgresql.lan`, `adguard.lan`, `cloudflared.lan`).

### Rule 6: mdBook Build Integrity
- All documentation files in `docs/` must compile cleanly with mdBook.
- When adding new markdown pages, add them to the navigation tree in `docs/SUMMARY.md`.
- Always validate documentation changes by running `mdbook build`.

### Rule 7: Strictly No Emojis (Use SVGs)
- Do NOT use emojis in documentation titles, headings, or content.
- Use clean typography or vector SVGs located in `docs/assets/icons/` when visual iconography is required.

### Rule 8: AI Guidelines Isolation
- `AGENTS.md` and `GEMINI.md` are strictly for AI agent instructions and repository governance.
- Never add `AGENTS.md` or `GEMINI.md` to `docs/` or expose them in the `docs/SUMMARY.md` navigation tree.

---

## 4. Standard Agent Workflows

### When asked to document an existing node or container:
1. Extract metadata (Hostname, ID, IP, OS, Purpose, Ports, Mounts, Services).
2. Create or update `docs/containers/<id>-<name>.md` or `docs/nodes/<name>.md`.
3. Synchronize `docs/inventory.md` and `docs/infrastructure-map.md`.

### When asked to add a new Docker stack:
1. Check `docs/inventory.md` for port conflicts on `docker.lan`.
2. Draft `docs/services/<service-name>.md` detailing the stack, dependencies (e.g. PostgreSQL, Redis, Mailpit), and backup requirements.
3. Create `compose/<service-name>/docker-compose.yml` and `compose/<service-name>/.env.example`.
4. Document any reverse proxy / Cloudflare Tunnel routing in `docs/network/ingress-tunnel.md`.

### When asked to troubleshoot an issue:
1. Trace the network path (Client -> Cloudflare/AdGuard -> Gateway 10.10.0.1 -> Container/VM).
2. Trace the storage path (Host SMB -> LXC Bind Mount -> Application Permission/UID/GID).
3. Check database connectivity (`psql -h postgresql.lan -U <user> -d <database>`).
4. Provide structured diagnostic commands and log inspection steps.
