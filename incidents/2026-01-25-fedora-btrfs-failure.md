# Title: Sudden Shutdown Causing Btrfs Metadata Inconsistency and Boot Failure on Fedora

## Date/Time: 2026-01-25 (date of incident)

## System Affected:
- Fedora Workstation
- Root filesystem: Btrfs
- Kernel: 6.x (Fedora default)
- Disk: NVMe SSD

## Incident Description:
The system was running normally when a sudden shutdown/power loss occurred. Upon reboot, the system failed to boot correctly. Errors observed included:
- systemd-random-seed.service failed
- audit.service failed
- Btrfs balance failed on root filesystem

## Cause:
- Btrfs uses a copy-on-write filesystem and maintains multiple copies of metadata blocks.
- A sudden shutdown caused partial writes to metadata blocks.
- The system detected metadata inconsistency during boot, preventing certain services from starting.

## Impact:
- System failed to boot normally, requiring emergency mode intervention.
- Services depending on root filesystem integrity failed to start.

## Resolution Steps:
1- Booted from a live environment (Fedora Live USB).
2- Mounted root Btrfs filesystem:
```
sudo mount -o subvol=@ /dev/nvme0n1p3 /mnt/sysroot

```
3- Checked filesystem status:
```
sudo btrfs filesystem df /mnt/sysroot
sudo btrfs scrub start -Bd /mnt/sysroot
sudo btrfs balance start -dusage=75 /mnt/sysroot
```
4- Rebooted system; verified normal boot and service status.

## Preventive Measures:
- Ensure stable power (UPS for desktops, healthy battery for laptops).
- Maintain Btrfs health via regular scrubs and balances.
- Keep ~10–15% free space to avoid metadata overflows.
- Set up automatic snapshot backups of root and important directories.
- Monitor disk health using SMART (`smartctl`).

## Lessons Learned:
- Btrfs is resilient but sensitive to abrupt shutdowns.
- Regular maintenance (`scrub`, `balance`, snapshots) significantly reduces the risk of data corruption.
- Automating maintenance tasks is recommended for production/stable workstation use.
