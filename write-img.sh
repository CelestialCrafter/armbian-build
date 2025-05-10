#!/usr/bin/env bash
set -e

if [ -z "$IMG" ] || [ -z "$DEVICE" ]; then
    echo "IMG or DEVICE missing" >&2
    exit 1
fi

function cleanup {
	echo cleanup
	sync
	losetup -D
	umount /mnt || true
}

trap cleanup EXIT

echo fetching sectors
LOOP=$(losetup --find --partscan --show "$IMG")

get_sectors() {
    parted -s -j "$1" unit s print \
      | jq -r --argjson n "$2" '.disk.partitions[] | select(.number == $n) | "\(.start) \(.end)"' \
      | sed 's/[[:alpha:]]//g'
}

read BOOT_START BOOT_END < <(get_sectors "$LOOP" 1)
read ROOT_START ROOT_END < <(get_sectors "$LOOP" 2)
read HOME_START HOME_END < <(get_sectors "$DEVICE" 3)

# adjust root partition end to just before home
ROOT_END=$((HOME_START - 1))

echo re-creating partitions
parted -s "$DEVICE" rm 1 || true
parted -s "$DEVICE" rm 2 || true
# partition 3 left intact

parted -s "$DEVICE" mkpart boot ext4 "${BOOT_START}s" "${BOOT_END}s"
parted -s "$DEVICE" mkpart rootfs btrfs "${ROOT_START}s" "${ROOT_END}s"

echo writing data
dd if="${LOOP}p1" of="${DEVICE}p1" bs=1M status=progress conv=fsync
dd if="${LOOP}p2" of="${DEVICE}p2" bs=1M status=progress conv=fsync

echo expanding rootfs
mount "${DEVICE}p2" /mnt
btrfs filesystem resize max /mnt
