# This file is normally automatically generated. Since we build a VM
# and have full control over that hardware I can hardcode this into my
# repository.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  boot.initrd.availableKernelModules = [
    "ata_piix" "mptspi" "uhci_hcd" "ehci_pci" "sd_mod" "sr_mod" "nvme" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # Enable LISH.
  # https://www.linode.com/docs/guides/install-nixos-on-linode/#enable-lish
  boot.kernelParams = [ "console=ttyS0,19200n8" ];
  boot.loader.grub.extraConfig = ''
    serial --speed=19200 --unit=0 --word=8 --parity=no --stop=1;
    terminal_input serial;
    terminal_output serial
  '';

  # Configure GRUB.
  # https://www.linode.com/docs/guides/install-nixos-on-linode/#configure-grub
  boot.loader.grub.forceInstall = true;
  boot.loader.grub.device = "nodev";
  boot.loader.timeout = 10;

  fileSystems."/" =
    { device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-label/swap"; }
    ];

}
