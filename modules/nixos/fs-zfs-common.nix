{
  flake.nixosModules.fs-zfs-common =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      options.node.fs.zfs = with lib; {
        hostId = mkOption {
          type = types.nullOr types.str;
          example = "4e98920d";
          default = "";
          description = ''
            The 32-bit host ID of the machine, formatted as 8 hexadecimal characters.

            You should try to make this ID unique among your machines. You can
            generate a random 32-bit ID using the following commands:

            `head -c 8 /etc/machine-id`

            (this derives it from the machine-id that systemd generates) or

            `head -c4 /dev/urandom | od -A none -t x4`

            The primary use case is to ensure when using ZFS that a pool isn't imported
            accidentally on a wrong machine.

            https://search.nixos.org/options?channel=unstable&query=networking.hostId
          '';
        };
      };

      config =
        let
          cfg = config.node.fs.zfs;
        in
        {
          # The primary use case is to ensure when using ZFS that a pool isn’t imported
          # accidentally on a wrong machine.
          # https://search.nixos.org/options?channel=unstable&query=networking.hostId
          networking = { inherit (cfg) hostId; };

          boot = {
            swraid.mdadmConf = ''
              MAILADDR root
            '';

            kernelModules = [ "zfs" ];
            supportedFilesystems.zfs = true;

            # IMPORTANT NOTE: LTS Linux Kernel is the recommended setup for ZFS
            # (also NixOS default).
            # https://discourse.nixos.org/t/zfs-latestcompatiblelinuxpackages-is-deprecated/52540
            # https://github.com/openzfs/zfs/releases
            kernelPackages = pkgs.linuxPackages;
            zfs.package = pkgs.zfs_2_4;

            # When true, forcibly import the ZFS root pool(s) during early boot.
            # It is highly recommended to keep this option disabled as it
            # bypasses ZFS safeguard that protect your pools.
            # You should only need to do this after unclean shutdowns.
            # This is `false` for every hosts in this configuration. The
            # `lib.mkForce` verifies that.
            zfs.forceImportRoot = lib.mkForce false;
          };

          # Scrub all pools, monthly by default
          services.zfs.autoScrub.enable = true;

          environment.systemPackages = [
            pkgs.httm # Snapshot browsing
            config.boot.zfs.package
          ];
        };
    };
}
