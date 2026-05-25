# # [Framework Laptop 13](https://frame.work/)
#
# ## Updating Firmware
#
# Everything is updateable through fwupd.
#
# To get the latest firmware, run:
#
# ```sh
# $ fwupdmgr refresh
# $ fwupdmgr update
# ```
#
# Latest Update: https://fwupd.org/lvfs/devices/work.frame.Laptop.RyzenAI300.BIOS.firmware
{ inputs, ... }:
{
  flake.nixosModules.hardware-framework-13 =
    { pkgs', ... }:
    {
      imports = [ inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series ];
      # TODO(26.05): use stable version
      environment.defaultPackages = [ pkgs'.framework-tool-tui ];
    };
}
