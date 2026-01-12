# Fedora KDE – Steam Storage Migration & Disk Health Guide

## Purpose

This document serves as a **reference guide** for safely reclaiming disk space on Fedora KDE (Btrfs root) by migrating Steam game data and shader caches to secondary storage. It follows Fedora best practices and avoids system-breaking tweaks.

---

## System Context (Example)

* **OS**: Fedora KDE Plasma
* **Root FS**: Btrfs
* **Primary Disk**: NVMe (root `/`)
* **Secondary Disk**: HDD mounted at `/mnt/data`
* **GPU**: NVIDIA (MX series or similar)
* **Steam**: Native Linux client

---

## Problem Statement

Btrfs root filesystem nearing full capacity (>90%) can cause:

* Update failures
* Metadata exhaustion
* System stutters
* Application instability

Steam games, Proton data, and shader caches are common causes of silent disk growth.

---

## Step 1 – Verify Disk Pressure

```bash
df -h /
sudo btrfs filesystem usage /
```

**Action threshold**:

* Root usage > 85% → cleanup required
* Metadata usage > 80% → cleanup recommended

---

## Step 2 – Move Steam Games to Secondary Storage (Recommended)

### 2.1 Create Steam Library Directory

```bash
mkdir -p /mnt/data/SteamLibrary
sudo chown -R $USER:$USER /mnt/data/SteamLibrary
```

### 2.2 Add Library in Steam (GUI)

* Steam → Settings → Storage
* Add Library: `/mnt/data/SteamLibrary`
* (Optional) Set as default library

### 2.3 Move Installed Games

* Steam → Settings → Storage
* Select game → Move → `/mnt/data/SteamLibrary`

Steam handles integrity, symlinks, and Proton paths automatically.

---

## Step 3 – Move Steam Shader Cache & Proton Data (Optional but Recommended)

### What Is Being Moved

* Shader cache
* Proton compatibility data

Locations:

```
~/.steam/steam/steamapps/shadercache
~/.steam/steam/steamapps/compatdata
```

These can grow **10–30 GB** over time.

---

## Step 4 – Bind Mount Method (Preferred)

Bind mounts are safer than symlinks and fully transparent to Steam.

### 4.1 Close Steam

```bash
pkill steam
```

### 4.2 Create Target Directories

```bash
mkdir -p /mnt/data/steam-cache/shadercache
mkdir -p /mnt/data/steam-cache/compatdata
sudo chown -R $USER:$USER /mnt/data/steam-cache
```

### 4.3 Move Existing Data

```bash
mv ~/.steam/steam/steamapps/shadercache /mnt/data/steam-cache/
mv ~/.steam/steam/steamapps/compatdata /mnt/data/steam-cache/
```

### 4.4 Recreate Empty Mount Points

```bash
mkdir ~/.steam/steam/steamapps/shadercache
mkdir ~/.steam/steam/steamapps/compatdata
```

---

## Step 5 – Persist Bind Mounts

Edit `/etc/fstab`:

```bash
sudo nano /etc/fstab
```

Add:

```
/mnt/data/steam-cache/shadercache  /home/<user>/.steam/steam/steamapps/shadercache  none  bind  0  0
/mnt/data/steam-cache/compatdata  /home/<user>/.steam/steam/steamapps/compatdata  none  bind  0  0
```

Replace `<user>` with your username.

### Apply & Verify

```bash
sudo mount -a
mount | grep steam-cache
```

No output errors = success.

---

## Step 6 – Validation

```bash
df -h /
sudo btrfs filesystem usage /
```

**Expected result**:

* Root usage < 80%
* Metadata usage < 75%
* Long-term disk stability

---

## Performance Notes

* Slightly slower *initial* shader compilation (HDD)
* No impact on in-game FPS
* Prevents long-term stutter and cache bloat

Recommended strategy:

* Competitive games → SSD
* Single-player / large games → HDD

---

## Rollback Procedure (If Needed)

```bash
sudo sed -i '/steam-cache/d' /etc/fstab
sudo umount ~/.steam/steam/steamapps/shadercache
sudo umount ~/.steam/steam/steamapps/compatdata
```

Steam will recreate directories automatically.

---

## Do NOT Do

* Do not manually copy `steamapps` outside Steam
* Do not disable Btrfs features
* Do not symlink system directories
* Do not rebalance Btrfs unnecessarily

---

## Status After Completion

* ✔ Fedora system stable
* ✔ Btrfs metadata healthy
* ✔ Steam storage optimized
* ✔ Future disk pressure prevented

---

## Revision Notes

* Designed for Fedora KDE Plasma
* Safe for NVIDIA + Proton
* No cron jobs, scripts, or unsupported tweaks
