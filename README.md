# Setup

```bash
# Change this
DISK=/dev/nvme0n1

# Create partitions
parted $DISK -- mklabel gpt
parted $DISK -- mkpart ESP fat32 1MiB 512MiB
parted $DISK -- mkpart primary 512MiB 100%
parted $DISK -- set 1 esp on

# Change this
KEY=/path/to/keyfile
ROOT=/dev/nvme0n1p2
BOOT=/dev/nvme0n1p1

# Setup encryption with keyfile
cryptsetup luksFormat $ROOT $KEY
cryptsetup luksOpen $ROOT cryptroot --key-file $KEY
mkfs.ext4 -L nixos /dev/mapper/cryptroot
mount /dev/disk/by-label/nixos /mnt
mkdir /mnt/boot
mount $BOOT /mnt/boot

# Generate config
nixos-generate-config --root /mnt
```
