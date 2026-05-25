{
  flake.nixosModules.bootloader-grub = {
    boot.loader.grub = {
      enable = true;
      device = "nodev";
      forceInstall = true;
    };
  };
}
