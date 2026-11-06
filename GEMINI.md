# GEMINI.md — Homelab Documentation Repository (`selfhost.md`)

Welcome to `selfhost.md`. This repository is the Single Source of Truth (SSoT) for documenting, architecting, and maintaining the user's homelab infrastructure.

---

## 1. Homelab Overview & Architecture

### Infrastructure Summary
- **Hypervisor:** Proxmox VE host (`pve01`) on `192.168.100.2` (via `vmbr0`) with an isolated homelab bridge `vmbr1` (`10.10.0.1/24`).
- **Core Network & Ingress:**
  - **Top Level:** Sole top node is `Public Internet`.
  - **Physical Ingress:** Home ISP Router (`192.168.100.1/24`) is the **only** link connected to Proxmox physical bridge `vmbr0` (`192.168.100.2`).
  - **Subnet:** `10.10.0.0/24` on internal bridge `vmbr1` (NAT Gateway: `10.10.0.1`).
  - **DNS & DHCP:** AdGuard Home (`10.10.0.2` / `adguard.lan` / CT 100).
  - **External Ingress:** Cloudflare Tunnel daemon (`10.10.0.3` / `cloudflared.lan` / CT 101) connected directly to Cloudflare Edge / Mesh (`100.96.0.0/12`), providing DoH and zero-trust portless ingress.
  - **Mesh / Remote Access:** Oracle Cloud VPS (`openvpn-oracle`) connected via Cloudflare Edge / Mesh (`100.96.0.0/12`).
- **Storage Infrastructure:**
  - **Cloud / Remote Storage:** `rclone.lan` (CT 103) running FUSE mounts for Google Drive (`/mnt/gdrive/plex`) and Telegram as Storage (`/mnt/tas` via `tas-mount.service` & `tas-sync.service`).
  - **Samba Server:** `//rclone.lan/gdrive` exported back to Proxmox VE host.
  - **Host Storage Mount:** SMB mount handled in `/etc/fstab` on `pve01` (`/mnt/pve/smb-rclone.lan/Media`).
  - **Container Bind Mounts:** Passed via Proxmox bind mount (`mp0`) to:
    - `plex.lan` (CT 104) at `/mnt/media`
    - `qbit.lan` (CT 105) at `/mnt/media`
    - `sonarr.lan` (CT 108) at `/mnt/media`
    - `radarr.lan` (CT 109) at `/mnt/media`
    - `bazarr.lan` (CT 111) at `/mnt/media`
- **Database Layer:**
  - Dedicated PostgreSQL server (`postgresql.lan` / CT 106) on port `5432` with Adminer (`:80/adminer`), hosting centralized databases (e.g., `openkos`, `firefly`).
- **Docker Host:**
  - Dedicated VM (`docker.lan` / VM 102) with 16GB RAM hosting projects:
    - **OpenKOS:** Web (`:8181`), Worker Queues, Scheduler, Redis (`:6379`), Mailpit (`:8025`).
    - **Firefly III:** Core (`:800`), Importer (`:810`), Cron.
    - **PodPDF:** Privacy-first PDF tooling (`:2873`).
    - **Steam-ish:** Gaming tool (`:3112`).
    - **Portainer:** Container management (`:9443` HTTPS / `:8000` HTTP).
- **Media Automation Pipeline:**
  - **Jellyseerr / Overseerr (`seer.lan` / CT 107):** Media requests and discovery on port `5055`.
  - **Sonarr (`sonarr.lan` / CT 108):** TV automation daemon on port `8989`.
  - **Radarr (`radarr.lan` / CT 109):** Movie automation daemon on port `7878`.
  - **Prowlarr (`prowlarr.lan` / CT 110):** Centralized indexer manager and proxy on port `9696`.
  - **Bazarr (`bazarr.lan` / CT 111):** Subtitle automation daemon on port `6767`.
  - **qBittorrent (`qbit.lan` / CT 105):** Torrent client with WebAPI v2.14+ API Key auth on `:8090`.
  - **Plex Media Server (`plex.lan` / CT 104):** Final media playback (Movies: Section 2, TV: Section 3).

---

## 2. Repository Structure

Maintain a clean, modular hierarchy for all documentation, configurations, scripts, and compose stacks:

```text
selfhost.md/
├── GEMINI.md                       # Project-specific guidelines & architecture for Gemini CLI
├── AGENTS.md                       # Universal AI agent instructions & SOPs
├── README.md                       # High-level entrypoint & homelab index
├── book.toml                       # mdBook configuration file
├── lightbox.js                     # Lightbox modal popup script for diagrams
├── lightbox.css                    # Lightbox modal styles
├── .gitignore                      # Strict ignores for secrets, dumps, and keys
├── docs/
│   ├── index.md                    # mdBook entrypoint & overview
│   ├── SUMMARY.md                  # mdBook navigation & sidebar tree
│   ├── infrastructure-map.md       # Visual architecture, node details & roles
│   ├── inventory.md                # Central IP, Port, Container ID & Resource Registry
│   ├── assets/
│   │   ├── network-topology.svg    # Compiled high-resolution Graphviz SVG
│   │   └── icons/                  # 16 clean vector SVG icons (strictly no emojis)
│   ├── network/
│   │   ├── network-topology.dot    # Graphviz DOT source (splines=ortho, 90-deg angles)
│   │   └── topology.md             # Subnets, routing, bridges, mesh VPN
│   ├── nodes/
│   │   └── pve01.md                # Proxmox VE host specs, fstab, network bridges
│   ├── containers/                 # LXC container documentation
│   │   ├── ct105-qbit.md
│   │   ├── ct109-radarr.md
│   │   ├── ct110-prowlarr.md
│   │   └── ct111-bazarr.md
│   ├── storage/
│   │   └── architecture.md         # Rclone FUSE, TAS, SMB, and Bind Mount pipelines
│   └── scripts/                    # Automation hook documentation
│       ├── discord-notification.md
│       └── qbit-relocate.md
├── .github/
│   └── workflows/
│       └── deploy.yml              # GitHub Actions deploy to GitHub Pages
└── scripts/                        # Sanitized automation & hook script templates
    ├── discord_qbit_notification.sh
    └── qbit-relocate.sh.example
```

---

## 3. Strict Documentation & Engineering Standards

### A. Zero Secrets Policy
- **NEVER commit sensitive credentials:** Passwords, API tokens, bearer keys, private encryption keys, WireGuard/OpenVPN configs, Cloudflare tunnel tokens, or Telegram bot tokens.
- **Sanitization Format:** Use standardized placeholders in all markdown and configuration files:
  - `<POSTGRES_PASSWORD>`
  - `<CLOUDFLARE_TUNNEL_TOKEN>`
  - `<QBIT_BEARER_TOKEN>`
  - `<PLEX_CLAIM_TOKEN>`
  - `${ENV_VAR_NAME}` for Compose templates

### B. Single Source of Truth for Ports & IPs
- Every addition, port modification, or new container assignment **MUST** be reflected in `docs/inventory.md`.
- Always verify against `docs/inventory.md` before documenting or suggesting a port assignment to prevent port collisions on `docker.lan` or IP collisions on the `10.10.0.0/24` subnet. Next available Container ID: `CT 112+`.

### C. Standard Document Template
When documenting a new LXC container, VM, or Docker Service, use the following standardized sections:
1. **Metadata Table:** (ID, Hostname, IPv4, Host/Hypervisor, Primary Ports, Status).
2. **Overview & Purpose:** (Brief description of the service role).
3. **Architecture & Dependencies:** (Database, upstream reverse proxy, storage dependencies).
4. **Configuration & Paths:** (Config files, mount paths, systemd units).
5. **Operational Commands:** (Start, restart, logs, console access).
6. **Backup & Recovery Strategy:** (Proxmox backup schedule, database dump commands).

### D. Diagrams & Network Schematics
- The primary network architecture diagram is authored in Graphviz DOT format at `docs/network/network-topology.dot` and compiled to `docs/assets/network-topology.svg` using `dot -Tsvg`.
- **90-Degree Orthogonal Lines:** Always enforce `splines = "ortho"` so lines make sharp right angles without curvature.
- **Interactive Lightbox:** Clicking the Network Diagram triggers a full-screen modal popup in front of the page powered by `lightbox.js` and `lightbox.css`.

### E. Strictly No Emojis (Use SVGs)
- Do NOT use emojis in documentation titles, headings, or content.
- Use clean typography or vector SVGs located in `docs/assets/icons/` when visual iconography is required.

### F. AI Guidelines Isolation
- `AGENTS.md` and `GEMINI.md` are strictly for AI agent instructions and repository governance.
- Never add `AGENTS.md` or `GEMINI.md` to `docs/` or expose them in the `docs/SUMMARY.md` navigation tree.

---

## 4. Common Maintenance Workflows

### Adding a New LXC Container
1. Allocate an unused Container ID (e.g., CT 112+) and document it in `docs/inventory.md`.
2. Assign static DHCP lease in AdGuard Home (`adguard.lan`) and create a DNS rewrite entry (`<service>.lan -> 10.10.0.X`).
3. Document any bind mounts from `pve01` in both `docs/nodes/pve01.md` and `docs/containers/<name>.md`.
4. If a database is required, document the database creation commands targeting `postgresql.lan`.

### Adding a New Docker Service on `docker.lan`
1. Check `docs/inventory.md` for host port availability on `docker.lan`.
2. Create documentation in `docs/services/<service>.md`.
3. Provide a sanitized `docker-compose.yml` and `.env.example` under `compose/<service>/`.
4. If exposed externally, document the Cloudflare Tunnel hostname routing in `docs/network/ingress-tunnel.md`.

---

## 5. Development, mdBook & Validation Commands

This repository uses **mdBook** with the `mdbook-mermaid` preprocessor to compile documentation into a fast, responsive static book automatically deployed to **GitHub Pages** via GitHub Actions.

### Local Development
```bash
# Start local live-reloading preview server (default: http://localhost:3000)
mdbook serve

# Validate full production build (outputs to book/)
mdbook build

# Recompile Graphviz network topology diagram
dot -Tsvg docs/network/network-topology.dot -o docs/assets/network-topology.svg
```

### GitHub Pages Setup
- The repository uses `.github/workflows/deploy.yml` with native GitHub Pages deployment.
- In repository **Settings** -> **Pages**:
  - **Source:** Select **GitHub Actions**.
  - Pushes to `main` will automatically build and publish the site.
