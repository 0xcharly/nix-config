{ self, ... }:
{
  flake.nixosModules.profile-fs-btrfs-server-linode =
    { pkgs, ... }:
    {
      imports = with self.nixosModules; [
        fs-btrfs-root-preamble
        fs-btrfs-root-linode
        fs-btrfs-impermanence
        prometheus-exporters-btrfs
      ];

      # Servers ride LTS — an explicit policy, not a reliance on the NixOS
      # default (releases have shipped non-LTS defaults before, and nothing
      # would fail when it recurs).
      boot.kernelPackages = pkgs.linuxPackages;
    };
}
