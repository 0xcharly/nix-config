{flake, ...}: {
  config,
  lib,
  pkgs,
  ...
}: {
  options.node.fs.zfs.zpool.root = with lib; {
    datadirs = let
      datasetOpts = {
        name,
        config,
        ...
      }: {
        options = {
          mountpoint = mkOption {
            type = types.str;
            default = name;
            description = ''
              Relative path under /var/lib.
            '';
          };
          absolutePath = mkOption {
            type = types.path;
            default = /var/lib + "/${config.node.fs.zfs.zpool.root.datadirs.${name}.mountpoint}";
            readOnly = true;
            description = ''
              The absolute mountpoint path.
            '';
          };
          extraOptions = mkOption {
            type = types.attrsOf types.str;
            default = {};
            description = ''
              Additional ZFS options to set on the dataset.
            '';
          };
          owner = mkOption {
            type = types.str;
            default = "root";
            description = ''
              The owning user of this directory.
            '';
          };
          group = mkOption {
            type = types.str;
            default = "users";
            description = ''
              The owning group of this directory.
            '';
          };
          mode = mkOption {
            type = types.str;
            default = "0755";
            description = ''
              The permissions to set on this directory.
            '';
          };
        };
      };
    in
      mkOption {
        type = types.attrsOf (types.submodule datasetOpts);
        default = {};
        description = ''
          List of additional datasets to create under /var/lib.
        '';
      };
  };

  config = let
    cfg = config.node.fs.zfs.zpool.root;
  in
    lib.mkIf (cfg.datadirs != {}) {
      disko.devices.zpool.root.datasets = let
        mkDataDirAttrs = lib.mapAttrs' (
          name: options:
            lib.nameValuePair "var/lib/${name}" (
              flake.lib.zfs.mkLegacyDataset "/var/lib/${options.mountpoint}" options.extraOptions
            )
        );
      in
        mkDataDirAttrs cfg.datadirs;

      # Automatically adjust datadirs' permissions, if any.
      systemd.services = {
        set-datadir-perms = {
          description = "Adjust datadirs' perms";

          # Wait for the agenix service to be running / complete before mounting the ZFS pool.
          after = ["zfs-import.target"];
          requires = ["zfs-import.target"];
          wantedBy = ["multi-user.target"];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = let
              datadirs = builtins.attrValues cfg.datadirs;
              install-datadir = datadir: ''
                install -d --mode ${datadir.mode} --owner ${datadir.owner} --group ${datadir.group} /var/lib/${datadir.mountpoint}
              '';
              set-datadir-perms = pkgs.writeShellApplication {
                name = "set-datadir-perms";
                runtimeInputs = with pkgs; [coreutils zfs];
                text = lib.concatStringsSep "\n" (builtins.map install-datadir datadirs);
              };
            in
              lib.getExe set-datadir-perms;
          };
        };
      };
    };
}
