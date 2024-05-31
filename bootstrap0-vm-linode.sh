#! /usr/bin/env bash

# Create filesystem.
parted -s /dev/sda -- mklabel gpt
parted -s /dev/sda -- mkpart primary 512MB -8GB
parted -s /dev/sda -- mkpart primary linux-swap -8GB 100\%
parted -s /dev/sda -- mkpart ESP fat32 1MB 512MB
parted -s /dev/sda -- set 3 esp on

mkfs.ext4 -L nixos /dev/sda1
mkswap -L swap /dev/disk/sda2
mkfs.fat -F 32 -n boot /dev/sda3

# Mount future system, activate swap device.
mount /dev/sda1 /mnt
mkdir -p /mnt/boot
mount /dev/sda3 /mnt/boot
swapon /dev/sda2

# Generate initial config.
nixos-generate-config --root /mnt

# Update generated config.
sed --in-place -f - /mnt/etc/nixos/hardware-configuration.nix <<- 'EOF'
		s|swapDevices = \[ \]|swapDevices = [ { device = "/dev/disk/by-label/swap"; } ]|
		s|"/dev/disk/by-uuid/.*"|"/dev/disk/by-label/nixos"|
		s|"/dev/sdc"|"/dev/disk/by-label/boot"|
EOF

ex -s /mnt/etc/nixos/configuration.nix <<- 'EOF'
$?}
i
  nix.package = pkgs.nixUnstable;
  nix.extraOptions = "experimental-features = nix-command flakes";
  nix.settings.substituters = [ "https://0xcharly-nixos-config.cachix.org" ];
  nix.settings.trusted-public-keys = [ "0xcharly-nixos-config.cachix.org-1:qnguqEXJ4bEmJ8ceXbgB2R0rQbFqfWgxI+F7j4Bi6oU=" ];
  boot.kernelParams = [ "console=ttyS0,19200n8" ];
  boot.loader.grub.extraConfig = ''
    serial --speed=19200 --unit=0 --word=8 --parity=no --stop=1;
    terminal_input serial;
    terminal_output serial
  '';
  boot.loader.grub.forceInstall = true;
  boot.loader.grub.device = "nodev";
  boot.loader.timeout = 10;
  environment.systemPackages = with pkgs; [ inetutils mtr sysstat ];
  networking.useDHCP = false;
  networking.usePredictableInterfaceNames = false;
  networking.interfaces.eth0.useDHCP = true;
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;
  services.openssh.settings.PermitRootLogin = "yes";
  users.users.root.initialHashedPassword = "$y$j9T$4khyPQBDfNOm5ZM0tlorW1$n3jptX37mtDoPL7lLkgY2HFnGoOQ7Sq9DFRRoYh/3cC";
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB/bLz52u0dTFYTfJelVbXbU+VK7H4OXgre/8Mgx1+cq"
  ];
.
w
EOF

# Install NixOS.
nixos-install --no-root-passwd && reboot
