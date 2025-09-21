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
{inputs, ...}: {
  imports = [
    inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
  ];
}
