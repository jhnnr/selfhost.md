# Sonarr Post-Import Relocation Hook <img src="../assets/icons/terminal.svg" width="20" height="20" alt="Script" style="vertical-align: middle;" />

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
--8<-- "scripts/qbit-relocate.sh.example"
```
*(Reference template stored in [`scripts/qbit-relocate.sh.example`](https://github.com/jhnnr/selfhost.md/blob/main/scripts/qbit-relocate.sh.example))*
