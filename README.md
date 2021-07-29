# Create keyfile

assuming usb stick is mounted at /dev/sdb

```
yes | parted /dev/sdb -- mklabel gpt
yes | parted /dev/sdb -- mkpart primary 0% 100%
mkfs.fat -F 32 -n key /dev/sdb1
mount /dev/sdb1 /mnt
bs=512 count=8 if=/dev/random of=/mnt/key iflag=fullblock
```

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
yes YES | cryptsetup luksFormat $ROOT $KEY --label cryptroot
cryptsetup luksOpen $ROOT cryptroot --key-file $KEY
mkfs.ext4 -L nixos /dev/mapper/cryptroot
sleep 1  # in case this code is just copied - we must wait for label to be created
mount /dev/disk/by-label/nixos /mnt
mkdir /mnt/boot
mount $BOOT /mnt/boot

# Clone config
git clone https://github.com/olekthunder/nixos-config.git /mnt/etc/nixos
# Generate hadware config 
nixos-generate-config --root /mnt
# Install it
nix-shell -p git -p nixFlakes --run "nixos-install --root /mnt/ --impure --flake /mnt/etc/nixos#gimli"

reboot

# Then set user password
passwd olekthunder
```
