# GEMINI.md — Homelab Documentation Repository (`selfhost.md`)

Welcome to `selfhost.md`. This repository is the Single Source of Truth (SSoT) for documenting, architecting, and maintaining the user's homelab infrastructure.

---

## 1. Homelab Overview & Architecture

### Infrastructure Summary
- **Hypervisor:** Proxmox VE host (`pve01`) on `192.168.100.2` (via `vmbr0`) with an isolated homelab bridge `vmbr1` (`10.10.0.1/24`).
- **Core Network:**
  - Subnet: `10.10.0.0/24` (Gateway: `10.10.0.1`).
  - DNS & DHCP: AdGuard Home (`10.10.0.2` / `adguard.lan` / CT 100).
  - External Ingress: Cloudflare Tunnel daemon (`10.10.0.3` / `cloudflared.lan` / CT 101) providing DoH and zero-trust portless ingress.
  - Mesh / Remote Access: Cloudflare Edge / Mesh (`100.96.0.0/12`) + Oracle Cloud VPS (`openvpn-oracle`).
- **Storage Infrastructure:**
  - Cloud / Remote Storage: `rclone.lan` (CT 103) running FUSE mounts for Google Drive (`/mnt/gdrive/plex`) and Telegram as Storage (`/mnt/tas` via `tas-mount.service` & `tas-sync.service`).
  - Samba Server: `//rclone.lan/gdrive` shared back to Proxmox VE.
  - Host Storage Mount: SMB mounts handled in `/etc/fstab` on `pve01` (`/mnt/pve/smb-rclone.lan/Media`).
  - Container Bind Mounts: Passed into `plex.lan` (CT 104) and `qbit.lan` (CT 105) at `/mnt/media`.
- **Database Layer:**
  - Dedicated PostgreSQL server (`postgresql.lan` / CT 106) on port `5432` with Adminer (`:80/adminer`), hosting centralized databases (e.g., `openkos`, `firefly`).
- **Docker Host:**
  - Dedicated VM (`docker.lan` / VM 102) with 16GB RAM hosting containerized suites:
    - **OpenKOS Suite:** Web (`:8181`), Worker Queues, Scheduler, Redis (`:6379`), Mailpit (`:8025`).
    - **Firefly III Suite:** Core (`:800`), Importer (`:810`), Cron.
    - **Privacy Tools:** PodPDF (`:2873`).
    - **Management & Gaming:** Portainer (`:9443`), Steam-ish (`:3112`).
- **Media Automation Pipeline:**
  - **Jellyseerr / Overseerr (`seer.lan`):** Media requests and discovery.
  - **Sonarr (`sonarr.lan`):** TV automation daemon grabbing releases and triggering post-import relocate scripts.
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
├── .gitignore                      # Strict ignores for secrets, dumps, and keys
├── docs/
│   ├── infrastructure-map.md       # Visual & ASCII topology, full node hierarchy
│   ├── inventory.md                # Central IP, Port, Container ID & Resource Registry
│   ├── network/
│   │   ├── topology.md             # Subnets, routing, bridges, mesh VPN
│   │   ├── dns-dhcp.md             # AdGuard Home config, local DNS rewrites
│   │   └── ingress-tunnel.md       # Cloudflare Tunnel mappings & ingress rules
│   ├── nodes/
│   │   └── pve01.md                # Proxmox VE host specs, fstab, network bridges
│   ├── containers/                 # LXC container documentation
│   │   ├── ct100-adguard.md
│   │   ├── ct101-cloudflared.md
│   │   ├── ct103-rclone.md
│   │   ├── ct104-plex.md
│   │   ├── ct105-qbit.md
│   │   ├── ct106-postgresql.md
│   │   ├── sonarr.md
│   │   └── seer.md
│   ├── virtual-machines/           # VM documentation
│   │   └── vm102-docker.md
│   ├── services/                   # Application stacks running on Docker or bare metal
│   │   ├── openkos.md
│   │   ├── firefly-iii.md
│   │   ├── podpdf.md
│   │   ├── portainer.md
│   │   └── steam-ish.md
│   ├── storage/
│   │   ├── architecture.md         # Rclone FUSE, TAS, SMB, and Bind Mount pipelines
│   │   └── media-pipeline.md       # Sonarr -> qBittorrent -> Relocate -> Plex flow
│   └── runbooks/                   # Operational guides & recovery procedures
│       ├── new-service-checklist.md
│       ├── postgres-db-provisioning.md
│       └── backup-and-disaster-recovery.md
├── compose/                        # Sanitized Docker Compose templates
│   ├── openkos/
│   │   ├── docker-compose.yml
│   │   └── .env.example
│   ├── firefly/
│   │   ├── docker-compose.yml
│   │   └── .env.example
│   └── podpdf/
│       └── docker-compose.yml
└── scripts/                        # Sanitized automation & hook scripts
    ├── qbit-relocate.sh            # Sonarr post-import script
    └── rclone/
        ├── plex-watcher.sh
        └── tas-sync.sh
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
- Always verify against `docs/inventory.md` before documenting or suggesting a port assignment to prevent port collisions on `docker.lan` or IP collisions on the `10.10.0.0/24` subnet.

### C. Standard Document Template
When documenting a new LXC container, VM, or Docker Service, use the following standardized sections:
1. **Metadata Table:** (ID, Hostname, IPv4, Host/Hypervisor, Primary Ports, Status).
2. **Overview & Purpose:** (Brief description of the service role).
3. **Architecture & Dependencies:** (Database, upstream reverse proxy, storage dependencies).
4. **Configuration & Paths:** (Config files, mount paths, systemd units).
5. **Operational Commands:** (Start, restart, logs, console access).
6. **Backup & Recovery Strategy:** (Proxmox backup schedule, database dump commands).

### D. Diagrams
- Maintain both ASCII diagrams (for quick terminal/CLI reading) and Mermaid diagrams (for visual rendering in GitHub and markdown viewers) when modifying network routing or data flow.

### E. Strictly No Emojis (Use SVGs)
- Do NOT use emojis in documentation titles, headings, or content.
- Use clean typography or vector SVGs located in `docs/assets/icons/` when visual iconography is required.

### F. AI Guidelines Isolation
- `AGENTS.md` and `GEMINI.md` are strictly for AI agent instructions and repository governance.
- Never add `AGENTS.md` or `GEMINI.md` to `docs/` or expose them in the `mkdocs.yml` navigation tree.

---

## 4. Common Maintenance Workflows

### Adding a New LXC Container
1. Allocate an unused Container ID (e.g., CT 107+) and document it in `docs/inventory.md`.
2. Assign static DHCP lease in AdGuard Home (`adguard.lan`) and create a DNS rewrite entry (`<service>.lan -> 10.10.0.X`).
3. Document any bind mounts from `pve01` in both `docs/nodes/pve01.md` and `docs/containers/<name>.md`.
4. If a database is required, document the database creation commands targeting `postgresql.lan`.

### Adding a New Docker Service on `docker.lan`
1. Check `docs/inventory.md` for host port availability on `docker.lan`.
2. Create documentation in `docs/services/<service>.md`.
3. Provide a sanitized `docker-compose.yml` and `.env.example` under `compose/<service>/`.
4. If exposed externally, document the Cloudflare Tunnel hostname routing in `docs/network/ingress-tunnel.md`.

---

## 5. Development, MkDocs & Validation Commands

This repository uses standard **MkDocs** (`theme: name: mkdocs`) to compile documentation into a searchable, responsive static site automatically deployed to **GitHub Pages** via GitHub Actions.

### Local Development
```bash
# Install dependencies
python -m pip install -r requirements.txt

# Start local hot-reloading preview server (default: http://127.0.0.1:8000)
python -m mkdocs serve

# Validate full build and verify all internal links in strict mode
python -m mkdocs build --strict
```

### GitHub Pages Setup
- The repository uses `.github/workflows/deploy.yml` with native GitHub Pages deployment.
- In repository **Settings** -> **Pages**:
  - **Source:** Select **GitHub Actions**.
  - Pushes to `main` will automatically build and publish the site.
