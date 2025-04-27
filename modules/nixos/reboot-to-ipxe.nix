{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.modules.system.roles.nixos.rebootToIpxe {
  environment.shellAliases.reboot2PXE = "${pkgs.grub2}/bin/grub-editenv /boot/grub/grubenv set entry=ipxe && reboot";
  boot.loader = {
    # Different systems may require a different one of the following two
    # options. The first instructs Grub to install itself in an EFI standard
    # location. And the second tells it to install somewhere custom, but
    # mutate the EFI NVRAM so EFI knows where to find it. The former
    # should work on any system. The latter allows you to share one ESP
    # among multiple OSes, but doesn't work on a few systems (namely
    # VirtualBox, which doesn't support persistent NVRAM).
    #
    # Just make sure to only have one of these enabled.
    grub.efiInstallAsRemovable = true;
    efi.canTouchEfiVariables = false;

    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      ipxe = {
        "netboot.xyz" = ''
          #!ipxe
          dhcp
          chain --autofree http://boot.netboot.xyz/ipxe/netboot.xyz.efi
        '';
        "ipxe-config" = ''
          #!ipxe
          dhcp
          config
        '';
      };
    };
  };
}
