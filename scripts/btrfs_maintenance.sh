#!/bin/bash
# Btrfs Maintenance Script for Fedora Root Filesystem
# This script performs scrub and balance checks automatically.

LOGFILE="/var/log/btrfs_maintenance.log"
DEVICE="/dev/nvme0n1p3"
MOUNTPOINT="/"

echo "==== Btrfs Maintenance Started at $(date) ====" >> "$LOGFILE"

# Scrub (check & repair data and metadata)
echo "Starting scrub..." >> "$LOGFILE"
btrfs scrub start -Bd "$MOUNTPOINT" >> "$LOGFILE" 2>&1

# Balance only if metadata/data usage exceeds thresholds (best practice)
METADATA_USAGE=$(btrfs filesystem df "$MOUNTPOINT" | grep Metadata | awk '{print $4}' | sed 's/%//')
DATA_USAGE=$(btrfs filesystem df "$MOUNTPOINT" | grep Data | awk '{print $4}' | sed 's/%//')

if [ "$METADATA_USAGE" -gt 75 ] || [ "$DATA_USAGE" -gt 85 ]; then
    echo "Starting balance due to high usage..." >> "$LOGFILE"
    btrfs balance start "$MOUNTPOINT" >> "$LOGFILE" 2>&1
else
    echo "Balance not needed (metadata: $METADATA_USAGE%, data: $DATA_USAGE%)" >> "$LOGFILE"
fi

echo "==== Btrfs Maintenance Completed at $(date) ====" >> "$LOGFILE"
echo "" >> "$LOGFILE"
