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

        intelGpu = mkOption {
          type = bool;
          default = false;
          description = "True for machines with an Intel GPU.";
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

        tailscaleNode = mkOption {
          type = bool;
          default = false;
          description = "True for machines that should be part of the Tailscale network.";
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
            if cfg.nas.primary == null
            then null
            else !cfg.nas.primary;
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
    inherit (config.modules.stdenv) isNixOS;
  in
    (
      builtins.map (role: {
        assertion = cfg.roles.nixos.${role} -> isNixOS;
        message = "`system.roles.nixos.${role}` role is only supported on NixOS.";
      }) (builtins.attrNames config.modules.system.roles.nixos)
    )
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
