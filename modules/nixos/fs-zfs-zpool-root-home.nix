{ flake, ... }:
{
  disko.devices.zpool.root = {
    datasets.home = flake.lib.zfs.mkLegacyDataset "/home" { };
  };
}
