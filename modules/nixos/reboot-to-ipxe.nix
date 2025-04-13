{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf (config.modules.system.roles.nixos.rebootToIpxe) {
  environment.shellAliases.reboot2PXE = "${pkgs.grub2}/bin/grub-editenv /boot/grub/grubenv set entry=ipxe && reboot";
  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";

      extraFiles = {"ipxe.efi" = "${pkgs.ipxe}/ipxe.efi";};
      extraEntries = ''
        menuentry "Reinstall via iPXE" {
          chainloader /ipxe.efi
        }
      '';
    };
  };
}
