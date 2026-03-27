# ZFS data disk setup on Arch

This machine uses two disks directly and creates a ZFS mirror for backup data.

Why ZFS:

- mirror: one disk may fail without losing data
- checksumming: detects corruption
- scrub: verifies and repairs data from the good mirror side
- snapshots: point-in-time rollback/recovery
- native encryption

Layout:

- pool: `tank`
- dataset: `tank/garage`
- mountpoint: `/mnt/tank`

## Notes

- These steps destroy all data on the target disks.
- Use `/dev/disk/by-id/...`, not `/dev/sdX`.
- For 2 disks, use a `mirror`.

## 1. Identify the disks

List stable disk IDs:

```bash
ls -l /dev/disk/by-id
```

Set the two target disks:

```bash
export DISK1=/dev/disk/by-id/wwn-...
export DISK2=/dev/disk/by-id/wwn-...
```

Verify them carefully:

```bash
readlink -f "$DISK1"
readlink -f "$DISK2"
```

## 2. Wipe old metadata

```bash
wipefs -a "$DISK1"
wipefs -a "$DISK2"
sgdisk --zap-all "$DISK1"
sgdisk --zap-all "$DISK2"
```

## 3. Create the pool

```bash
zpool create \
  -f \
  -o ashift=12 \
  -O compression=lz4 \
  -O atime=off \
  -O xattr=sa \
  -O acltype=posixacl \
  -O mountpoint=none \
  tank \
  mirror \
  "$DISK1" \
  "$DISK2"
```

Explanation:

- `ashift=12`: correct alignment for modern 4K-sector disks
- `compression=lz4`: lightweight compression
- `atime=off`: avoids unnecessary writes
- `mountpoint=none`: do not mount the pool root directly

## 4. Create the encrypted dataset

This expects a passphrase key file at `/run/agenix/garage-zfs-key`.

```bash
zfs create \
  -o encryption=aes-256-gcm \
  -o keyformat=passphrase \
  -o keylocation=file:///run/agenix/zfs-key \
  -o mountpoint=/mnt/tank \
  tank/garage
```

Check the result:

```bash
zpool status
zfs list
zfs get encryption,keyformat,keylocation,mountpoint tank/garage
```

## 5. Export before moving the disks

Before shutting down or moving the disks:

```bash
zpool export tank
```

## Useful commands

Check pool health:

```bash
zpool status -v
```

List datasets:

```bash
zfs list
```

Run a scrub:

```bash
zpool scrub tank
```

List snapshots:

```bash
zfs list -t snapshot
```

## Snapshots

Create a snapshot:

```bash
zfs snapshot tank/garage@before-upgrade
```

List snapshots:

```bash
zfs list -t snapshot
```

## Restore options

### Roll back the dataset

This restores the dataset to the snapshot state.

```bash
zfs rollback tank/garage@before-upgrade
```

Warning:

- this discards changes made after the snapshot

### Clone a snapshot for inspection

This is safer if you want to inspect old data first.

```bash
zfs clone tank/garage@before-upgrade tank/garage-restore
zfs set mountpoint=/mnt/tank-restore tank/garage-restore
zfs mount tank/garage-restore
```

This creates a separate dataset from the snapshot so you can browse or copy data.

## Summary

Create the pool and dataset on Arch with:

```bash
export DISK1=/dev/disk/by-id/wwn-...
export DISK2=/dev/disk/by-id/wwn-...

wipefs -a "$DISK1"
wipefs -a "$DISK2"
sgdisk --zap-all "$DISK1"
sgdisk --zap-all "$DISK2"

zpool create \
  -f \
  -o ashift=12 \
  -O compression=lz4 \
  -O atime=off \
  -O xattr=sa \
  -O acltype=posixacl \
  -O mountpoint=none \
  tank \
  mirror \
  "$DISK1" \
  "$DISK2"

zfs create \
  -o encryption=aes-256-gcm \
  -o keyformat=passphrase \
  -o keylocation=file:///run/agenix/garage-zfs-key \
  -o mountpoint=/mnt/tank \
  tank/garage

zpool export tank
```

Best practices:

- scrub regularly
- keep free space available
- do not enable dedup
- snapshots are not a second backup copy