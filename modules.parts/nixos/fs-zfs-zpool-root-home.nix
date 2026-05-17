{ self, ... }:
{
  flake.nixosModules.fs-zfs-zpool-root-home = {
    disko.devices.zpool.root = {
      datasets.home = self.lib.zfs.mkLegacyDataset "/home" { };
    };
  };
}
