{ self, ... }:
{
  flake.nixosModules.profile-fs-btrfs-workstation-baremetal =
    { lib, pkgs, ... }:
    {
      imports = with self.nixosModules; [
        fs-btrfs-root-preamble
        fs-btrfs-root-baremetal
        fs-btrfs-root-subvol-home
        fs-btrfs-impermanence
        prometheus-exporters-btrfs
      ];

      # Workstations ride latest. mkDefault: a host can pin down if a kernel
      # regression ever forces it.
      boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
    };
}
