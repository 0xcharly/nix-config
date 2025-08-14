{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib.attrsets) genAttrs;
  inherit (lib.lists) optionals;
  inherit (lib.modules) mkMerge;
  inherit (lib.options) mkOption;
  inherit (lib.types) attrsOf bool enum nullOr str submodule;
  inherit (pkgs.stdenv) isDarwin;

  cfg = config.modules.system;
in {
  options.modules.system = {
    mainUser = mkOption {
      type = enum (builtins.attrNames cfg.users);
      default = "delay";
      description = ''
        The username of the main user for your system.

        In case of a multiple systems, this will be the user with priority in ordered lists and enabled options.
      '';
    };

    users = let
      userModule = submodule {
        options = {
          name = mkOption {
            type = str;
            default = "nobody";
            description = "The name of the user.";
          };
          home = mkOption {
            type = str;
            default = "/home/nobody";
            description = "The home directory of the user.";
          };
        };
      };
    in
      mkOption {
        type = nullOr (attrsOf userModule);
        default = let
          mkUser = username: {
            name = username;
            home =
              if isDarwin
              then "/Users/${username}"
              else "/home/${username}";
          };
        in
          genAttrs ["delay"] mkUser;
        description = "A list of home-manager users on the system.";
      };

    security = {
      accessTier = mkOption {
        type = enum ["untrusted" "basic" "trusted" "highly-privileged"];
        default = "untrusted";
        description = "The machine's access tier.";
      };

      isBasicAccessTier = mkOption {
        type = bool;
        readOnly = true;
        default = cfg.security.accessTier == "basic" || cfg.security.isTrustedAccessTier;
        description = "True for basic access tier machines.";
      };
      isTrustedAccessTier = mkOption {
        type = bool;
        readOnly = true;
        default = cfg.security.accessTier == "trusted" || cfg.security.isHighlyPrivilegedAccessTier;
        description = "True for trusted access tier machines.";
      };
      isHighlyPrivilegedAccessTier = mkOption {
        type = bool;
        readOnly = true;
        default = cfg.security.accessTier == "highly-privileged";
        description = "True for highly privileged access tier machines.";
      };
    };

    services = {
      serve = {
        reverseProxy = mkOption {
          type = bool;
          default = false;
          description = ''
            If true, host serves services from across the internal network
            behind a reverse proxy.
          '';
        };

        taskchampion-sync-server = mkOption {
          type = bool;
          default = false;
          description = ''
            Whether this machine exposes a TaskWarrior sync service.
          '';
        };

        vaultwarden = mkOption {
          type = bool;
          default = false;
          description = ''
            If true, host spins up a vaultwarden server.

            https://www.vaultwarden.net
          '';
        };
      };
    };

    networking = {
      tailscaleNode = mkOption {
        type = bool;
        default = cfg.networking.tailscalePublicNode;
        description = "True for machines that should be part of the Tailscale network.";
      };

      tailscalePublicNode = mkOption {
        type = bool;
        default = false;
        description = "True for machines part of the Tailscale network and publicly accessible.";
      };

      tailscaleSSH = mkOption {
        type = bool;
        default = false; # cfg.networking.tailscaleNode;
        description = ''
          If true, the machine will be configured to use Tailscale SSH.
          Forbidden on macOS hosts.
        '';
      };
    };

    beans = {
      user = mkOption {
        type = str;
        default = "delay";
        readOnly = true;
        description = ''
          The local user that owns the beans.
        '';
      };

      dataDir = mkOption {
        type = str;
        default = "beans";
        readOnly = true;
        description = ''
          The path relative to the user's home directory in which the beans are
          stored.

          Do NOT add a trailing slash.
        '';
      };

      sourceOfTruthHostName = mkOption {
        type = nullOr str;
        default = "heimdall";
        readOnly = true;
        description = ''
          The hostname of the source of truth for the beans files.
        '';
      };

      sourceOfTruth = mkOption {
        type = bool;
        default = config.networking.hostName == cfg.beans.sourceOfTruthHostName;
        readOnly = true;
        description = ''
          True for the machine that is the source of truth for bean files
          (i.e. on which beans are edited).
        '';
      };
    };

    roles = {
      nixos = {
        amdCpu = mkOption {
          type = bool;
          default = false;
          description = "True for machines with an AMD CPU.";
        };

        amdGpu = mkOption {
          type = bool;
          default = false;
          description = "True for machines with an AMD GPU.";
        };

        intelCpu = mkOption {
          type = bool;
          default = cfg.roles.nixos.intelThunderbolt;
          description = "True for machines with an Intel CPU.";
        };

        intelGpu = mkOption {
          type = bool;
          default = false;
          description = "True for machines with an Intel GPU.";
        };

        intelThunderbolt = mkOption {
          type = bool;
          default = false;
          description = "True for machines with an Intel Thunderbolt interface.";
        };

        netboot = mkOption {
          type = bool;
          default = false;
          description = "Whether the system is a netboot server.";
        };

        noRgb = mkOption {
          type = bool;
          default = false;
          description = "Disables RGB lighting on the system.";
        };

        protonvpn = mkOption {
          type = bool;
          default = false;
          description = "True for machines that should have a ProtonVPN interface.";
        };

        workstation = mkOption {
          type = bool;
          default = false;
          description = "True for local workstations.";
        };
      };

      nas = {
        enable = mkOption {
          type = bool;
          default = false;
          description = "Whether this machine is a NAS.";
        };
        primary = mkOption {
          type = nullOr bool;
          default = null;
          description = ''
            Whether this NAS is the source of truth for data a.k.a. "primary"
            (true) or used for replication a.k.a. "replica" (false).
          '';
        };
        replica = mkOption {
          type = nullOr bool;
          readOnly = true;
          default =
            if cfg.roles.nas.primary == null
            then null
            else !cfg.roles.nas.primary;
          description = ''
            Whether this NAS is used for replication of data a.k.a. "replica"
            (true) or the source of truth a.k.a. "primary" (false).
          '';
        };
        hostId = mkOption {
          type = nullOr str;
          default = null;
          description = ''
            The host ID of the NAS machine.

            This is used to ensure that ZFS pools are not imported on the wrong machine.
            The host ID is a 4-byte hexadecimal string, e.g. `12345678`.
            You can generate a random host ID using the following command:

              head -c4 /dev/urandom | od -A none -t x4
          '';
        };
        drives = let
          mkDriveOption = description:
            mkOption {
              type = nullOr str;
              default = null;
              inherit description;
            };
        in {
          nvme0 = mkDriveOption "The ID of the NVMe drive in slot 0 used for system partition RAID0.";
          nvme1 = mkDriveOption "The ID of the NVMe drive in slot 1 used for system partition RAID0.";
          sata0 = mkDriveOption "The ID of the SATA drive in slot 0 used for ZFS pool RAIDZ1.";
          sata1 = mkDriveOption "The ID of the SATA drive in slot 1 used for ZFS pool RAIDZ1.";
          sata2 = mkDriveOption "The ID of the SATA drive in slot 2 used for ZFS pool RAIDZ1.";
          sata3 = mkDriveOption "The ID of the SATA drive in slot 3 used for ZFS pool RAIDZ1.";
        };
      };
    };
  };

  config.warnings = mkMerge [
    (optionals (config.modules.system.users == []) [
      ''
        You have not added any users to be supported by your system.
        You may end up with an unbootable system!

        Consider setting {option}`config.modules.system.users` in your configuration
      ''
    ])
  ];

  config.assertions = let
    inherit (config) isNixOS;
  in
    (
      builtins.map (role: {
        assertion = cfg.roles.nixos.${role} -> isNixOS;
        message = "`system.roles.nixos.${role}` role is only supported on NixOS.";
      }) (builtins.attrNames config.modules.system.roles.nixos)
    )
    # Security config validation.
    ++ [
      {
        assertion = cfg.security.accessTier == "basic" -> isNixOS;
        message = "Non-NixOS machines are do not meet the mimimum requirements for Basic Access";
      }
      {
        assertion = cfg.security.accessTier == "trusted" -> isNixOS;
        message = "Non-NixOS machines are do not meet the mimimum requirements for Trusted Access";
      }
      {
        assertion = cfg.security.accessTier == "highly-privileged" -> isNixOS;
        message = "Non-NixOS machines are do not meet the mimimum requirements for Highly Privileged Access";
      }
    ]
    # Networking config validation.
    ++ [
      {
        assertion = cfg.networking.tailscalePublicNode -> cfg.networking.tailscaleNode;
        message = "`system.networking.tailscalePublicNode` requires `system.networking.tailscaleNode`";
      }
      {
        assertion = cfg.networking.tailscaleSSH -> isNixOS;
        message = "Tailscale SSH is only supported on NixOS.";
      }
    ]
    # NAS config validation.
    ++ [
      {
        assertion = cfg.roles.nas.enable -> isNixOS;
        message = "`system.roles.nas.enable` role is only supported on NixOS.";
      }
      {
        assertion = cfg.roles.nas.enable -> cfg.roles.nas.hostId != null;
        message = "`system.roles.nas.hostId` must be set for NAS machines.";
      }
      {
        assertion = cfg.roles.nas.enable -> cfg.roles.nas.primary != null;
        message = "`system.roles.nas.primary` must be set for NAS machines.";
      }
    ]
    ++ (
      builtins.map (drive: {
        assertion = cfg.roles.nas.enable -> cfg.roles.nas.drives.${drive} != null;
        message = "`system.roles.nas.drives.${drive}` must be set for NAS machines.";
      }) (builtins.attrNames config.modules.system.roles.nas.drives)
    )
    ++ (
      builtins.map (drive: {
        assertion = (!cfg.roles.nas.enable) -> cfg.roles.nas.drives.${drive} == null;
        message = "`system.roles.nas.enable` is true but `system.roles.nas.drives.${drive}` is not null.";
      }) (builtins.attrNames config.modules.system.roles.nas.drives)
    );
}
