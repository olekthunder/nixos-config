# Setup

```bash
# Change this
DISK=/dev/nvme0n1

# mount key
mkdir /key && mount `findfs LABEL=key` /key

# Create partitions
yes | parted $DISK -- mklabel gpt
yes | parted $DISK -- mkpart ESP fat32 1MiB 512MiB
yes | parted $DISK -- mkpart primary 512MiB 100%
yes | parted $DISK -- set 1 esp on

# Change this
ROOT=/dev/nvme0n1p2
BOOT=/dev/nvme0n1p1
KEY=/key/key

# Setup encryption with keyfile
yes YES | cryptsetup luksFormat $ROOT $KEY
cryptsetup luksOpen $ROOT cryptroot --key-file $KEY
mkfs.ext4 -L nixos /dev/mapper/cryptroot
mount /dev/disk/by-label/nixos /mnt
mkdir /mnt/boot
mount $BOOT /mnt/boot

# Generate config
curl https://raw.githubusercontent.com/olekthunder/nixos-config/master/configuration.nix -o /mnt/etc/nixos/configuration.nix 
nixos-generate-config --root /mnt

# install
nixos-install
```
