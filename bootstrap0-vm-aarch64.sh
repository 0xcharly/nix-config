#! /usr/bin/env bash

# Create filesystem.
parted -s /dev/sda -- mklabel gpt
parted -s /dev/sda -- mkpart primary 512MB -8GB
parted -s /dev/sda -- mkpart primary linux-swap -8GB 100\%
parted -s /dev/sda -- mkpart ESP fat32 1MB 512MB
parted -s /dev/sda -- set 3 esp on

mkfs.ext4 -L nixos /dev/sda1
mkswap -L swap /dev/sda2
mkfs.fat -F 32 -n boot /dev/sda3

# Mount future system.
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot

# Generate initial config.
nixos-generate-config --root /mnt

# Update generated config.
ex -s /mnt/etc/nixos/configuration.nix <<- 'EOF'
$?}
i
  nix.package = pkgs.nixUnstable;
  nix.extraOptions = "experimental-features = nix-command flakes";
  nix.settings.substituters = ["https://0xcharly-nixos-config.cachix.org"];
  nix.settings.trusted-public-keys = ["0xcharly-nixos-config.cachix.org-1:qnguqEXJ4bEmJ8ceXbgB2R0rQbFqfWgxI+F7j4Bi6oU="];
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;
  services.openssh.settings.PermitRootLogin = "yes";
  users.users.root.initialHashedPassword = "$y$j9T$4khyPQBDfNOm5ZM0tlorW1$n3jptX37mtDoPL7lLkgY2HFnGoOQ7Sq9DFRRoYh/3cC";
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP4Jr8wJUXhECjbSXlGPpLFAN0Zq+eY6n4w+0ezoMxFK delay"
  ];
.
w
EOF

# Install NixOS.
nixos-install --no-root-passwd && reboot
