{
  config,
  pkgs,
  lib,
  ...
}: {
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

  config = let
    cfg = config.node.fs.zfs;
  in {
    # The primary use case is to ensure when using ZFS that a pool isn’t imported
    # accidentally on a wrong machine.
    # https://search.nixos.org/options?channel=unstable&query=networking.hostId
    networking = {inherit (cfg) hostId;};

    boot = {
      swraid.mdadmConf = ''
        MAILADDR root
      '';

      kernelModules = ["zfs"];
      supportedFilesystems.zfs = true;

      # IMPORTANT NOTE: Carefully check the latest kernel version that is compatible
      # with the ZFS version in use.
      # Compatible kernel versions are listed on the OpenZFS release page. Check
      # which ZFS version is in use for the current stable channel.
      # The current stable channel is 25.05, which uses ZFS 2.3.5, and is compatible
      # with 4.18 - 6.17 kernels.
      # https://discourse.nixos.org/t/zfs-latestcompatiblelinuxpackages-is-deprecated/52540
      # https://github.com/openzfs/zfs/releases
      kernelPackages = pkgs.linuxPackages_6_17;
    };

    environment.systemPackages = with pkgs; [
      httm # Snapshot browsing.
      zfs
    ];
  };
}
