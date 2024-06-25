#! /usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Ensure that the script is passed a single argument.
if test $# -ne 1; then
  >&2 echo "Illegal number of parameters: expected 1, got $#"
  >&2 echo "Usage: $0 <nix-name>"
  exit 1
fi

# Create filesystem.
parted -s /dev/sda -- mklabel gpt
parted -s /dev/sda -- mkpart primary 512MB -8GB
parted -s /dev/sda -- mkpart primary linux-swap -8GB 100\%
parted -s /dev/sda -- mkpart ESP fat32 1MB 512MB
parted -s /dev/sda -- set 3 esp on

mkfs.ext4 -L nixos /dev/sda1
mkswap -L swap /dev/sda2
mkfs.fat -F 32 -n boot /dev/sda3

# Mount future system, activate swap device.
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
swapon /dev/disk/by-label/swap

# Install system.
nixos-install \
  --option extra-experimental-features flakes \
  --option accept-flake-config true \
  --show-trace \
  --no-root-passwd \
  --flake /nix-config#$1

# Reboot into new system.
reboot
