#!/bin/bash
# Safe Btrfs Watchdog Script
# Performs: scrub, conditional balance, SMART check, logging
# Designed for Fedora root filesystem on NVMe, safe defaults

LOGFILE="/var/log/btrfs_watchdog.log"
DEVICE="/dev/nvme0n1"
MOUNTPOINT="/"

echo "==== Btrfs Watchdog Started at $(date) ====" >> "$LOGFILE"

# 1. Check disk SMART health
if command -v smartctl >/dev/null 2>&1; then
    echo "Running SMART check..." >> "$LOGFILE"
    SMART_STATUS=$(sudo smartctl -H "$DEVICE" | grep "SMART overall-health" | awk '{print $6}')
    if [ "$SMART_STATUS" != "PASSED" ]; then
        echo "WARNING: SMART reports potential disk issues!" >> "$LOGFILE"
    else
        echo "SMART check passed." >> "$LOGFILE"
    fi
else
    echo "smartctl not installed; skipping SMART check." >> "$LOGFILE"
fi

# 2. Run Btrfs scrub
echo "Starting Btrfs scrub on $MOUNTPOINT..." >> "$LOGFILE"
sudo btrfs scrub start -Bd "$MOUNTPOINT" >> "$LOGFILE" 2>&1

# 3. Check usage to decide if balance is needed
METADATA_USAGE=$(sudo btrfs filesystem df "$MOUNTPOINT" | grep Metadata | awk '{print $4}' | sed 's/%//')
DATA_USAGE=$(sudo btrfs filesystem df "$MOUNTPOINT" | grep Data | awk '{print $4}' | sed 's/%//')

if [ "$METADATA_USAGE" -gt 75 ] || [ "$DATA_USAGE" -gt 85 ]; then
    echo "High usage detected (metadata: $METADATA_USAGE%, data: $DATA_USAGE%) - starting safe balance..." >> "$LOGFILE"
    sudo btrfs balance start -dusage=75 -musage=75 "$MOUNTPOINT" >> "$LOGFILE" 2>&1
else
    echo "Balance not required (metadata: $METADATA_USAGE%, data: $DATA_USAGE%)" >> "$LOGFILE"
fi

# 4. Rotate logs if too big (>5MB)
if [ -f "$LOGFILE" ]; then
    LOGSIZE=$(stat -c%s "$LOGFILE")
    if [ "$LOGSIZE" -gt 5242880 ]; then
        mv "$LOGFILE" "$LOGFILE.old"
        touch "$LOGFILE"
        echo "Log rotated at $(date)" >> "$LOGFILE"
    fi
fi

echo "==== Btrfs Watchdog Completed at $(date) ====" >> "$LOGFILE"
echo "" >> "$LOGFILE"
