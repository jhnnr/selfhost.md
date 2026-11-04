# Node Specification: `pve01` (Proxmox VE Host) <img src="../assets/icons/server.svg" width="20" height="20" alt="Server" style="vertical-align: middle;" />

This document covers the core hypervisor host `pve01` running Proxmox VE.

---

## 1. Node Overview

- **Hostname:** `pve01`
- **Role:** Bare Metal Hypervisor Host, Gateway for `10.10.0.0/24`, Central Storage Mounting
- **Physical IP:** `192.168.100.2` (via `vmbr0`)
- **Internal Gateway IP:** `10.10.0.1` (via `vmbr1`)
- **Web Interface:** `https://192.168.100.2:8006` or `https://10.10.0.1:8006`

---

## 2. Network Interface Configuration (`/etc/network/interfaces`)

```text
auto lo
iface lo inet loopback

iface eno1 inet manual

# Physical bridge to home ISP router
auto vmbr0
iface vmbr0 inet static
    address 192.168.100.2/24
    gateway 192.168.100.1
    bridge-ports eno1
    bridge-stp off
    bridge-fd 0

# Internal isolated bridge for Homelab Subnet (10.10.0.0/24)
auto vmbr1
iface vmbr1 inet static
    address 10.10.0.1/24
    bridge-ports none
    bridge-stp off
    bridge-fd 0
    # Enable IP forwarding and NAT for homelab containers
    post-up   iptables -t nat -A POSTROUTING -s '10.10.0.0/24' -o vmbr0 -j MASQUERADE
    post-down iptables -t nat -D POSTROUTING -s '10.10.0.0/24' -o vmbr0 -j MASQUERADE
```

---

## 3. Storage Mounts & `/etc/fstab`

`pve01` mounts the Samba share exposed by `rclone.lan` (CT 103) locally so that it can be passed into containers via unprivileged/privileged bind mounts.

### Mount Configuration
- **Remote Share:** `//rclone.lan/gdrive`
- **Host Mount Point:** `/mnt/pve/smb-rclone.lan/Media`
- **Credentials:** `/etc/pve/priv/smb-rclone.cred`

### Entry in `/etc/fstab`:
```text
//rclone.lan/gdrive /mnt/pve/smb-rclone.lan/Media cifs _netdev,credentials=/etc/pve/priv/smb-rclone.cred,uid=1000,gid=1000,iocharset=utf8 0 0
```

---

## 4. Container Bind Mounts from Host

The host storage mount is passed into media LXC containers via their respective `/etc/pve/lxc/<CTID>.conf` configuration files:

- **Plex Media Server (`CT 104`):**
  ```ini
  mp0: /mnt/pve/smb-rclone.lan/Media,mp=/mnt/media
  ```
- **qBittorrent Downloader (`CT 105`):**
  ```ini
  mp0: /mnt/pve/smb-rclone.lan/Media,mp=/mnt/media
  ```

---

## 5. Maintenance Commands

- **Check Network Bridges:**
  ```bash
  ip route show
  brctl show
  ```
- **Verify SMB Mount Status:**
  ```bash
  df -h /mnt/pve/smb-rclone.lan/Media
  mount | grep smb-rclone
  ```
- **Reload Mounts:**
  ```bash
  mount -a
  ```
