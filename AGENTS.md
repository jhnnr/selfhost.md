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
| **VM 102** | VM (16GB) | `docker.lan` | DHCP (`10.10.0.x`) | Docker stacks: OpenKOS, Firefly III, PodPDF, Steam-ish, Portainer | Docker volumes & mounts |
| **CT 103** | LXC | `rclone.lan` | DHCP (`10.10.0.x`) | Rclone FUSE (gdrive, TAS), Samba (`//rclone.lan/gdrive`), `plex-watcher.service` | `/mnt/gdrive/plex`, `/mnt/tas` |
| **CT 104** | LXC | `plex.lan` | DHCP (`10.10.0.x`) | Plex Media Server (`:32400`), Sections: Movies (2), TV (3) | Bind mount: `/mnt/media` <-- Host SMB |
| **CT 105** | LXC | `qbit.lan` | DHCP (`10.10.0.x`) | qBittorrent WebUI (`:8090`), Bearer Token Auth | Bind mount: `/mnt/media`, `/downloads/tv-sonarr` |
| **CT 106** | LXC | `postgresql.lan`| DHCP (`10.10.0.x`) | Shared PostgreSQL (`:5432`), Adminer (`:80/adminer`) | Databases: `openkos`, `firefly` |
| **LXC** | LXC | `sonarr.lan` | DHCP (`10.10.0.x`) | TV show automation (`:8989`), Post-import relocate hook | `/mnt/media/TV` |
| **LXC** | LXC | `seer.lan` | DHCP (`10.10.0.x`) | Jellyseerr / Overseerr (`:5055`), Sonarr & Plex API | Local config |
| **VPS** | Remote VM | `openvpn-oracle`| Cloud Mesh (`100.96.0.0/12`) | Cloud mesh ingress node / remote access point | OpenVPN / WireGuard mesh |

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
  3. Ensure the chosen IP / Container ID is unassigned.
  4. Update `docs/inventory.md` immediately in the same turn or task.

### Rule 3: Storage Pipeline Awareness
Understand the multi-tier storage architecture before suggesting or documenting file paths:
1. **Remote Cloud / TAS:** Handled by `rclone.lan` (CT 103) via FUSE at `/mnt/gdrive/plex` and `/mnt/tas`.
2. **Samba Export:** `rclone.lan` exports `//rclone.lan/gdrive`.
3. **Proxmox Host Mount:** `pve01` mounts SMB via `/etc/fstab` to `/mnt/pve/smb-rclone.lan/Media`.
4. **LXC Bind Mount:** Proxmox bind-mounts `/mnt/pve/smb-rclone.lan/Media` into `plex.lan` (CT 104) and `qbit.lan` (CT 105) at `/mnt/media`.
5. **Application Paths:**
   - Plex accesses `/mnt/media/Movies` and `/mnt/media/TV`.
   - Sonarr tracks `/mnt/media/TV`.
   - qBittorrent downloads to `/downloads/tv-sonarr` and uses Sonarr remote path mappings.
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

### Rule 6: MkDocs Build Integrity
- All documentation files in `docs/` must compile cleanly with standard MkDocs (`theme: name: mkdocs`).
- When adding new markdown pages, add them to the navigation tree in `mkdocs.yml`.
- Always validate documentation changes by running `python -m mkdocs build --strict`.

### Rule 7: Strictly No Emojis (Use SVGs)
- Do NOT use emojis in documentation titles, headings, or content.
- Use clean typography or vector SVGs located in `docs/assets/icons/` when visual iconography is required.

### Rule 8: AI Guidelines Isolation
- `AGENTS.md` and `GEMINI.md` are strictly for AI agent instructions and repository governance.
- Never add `AGENTS.md` or `GEMINI.md` to `docs/` or expose them in the `mkdocs.yml` navigation tree.

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
