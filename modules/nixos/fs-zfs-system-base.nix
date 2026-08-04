{ inputs, ... }:
{
  flake.nixosModules.fs-zfs-system-base =
    { config, lib, ... }:
    {
      imports = [ inputs.disko.nixosModules.disko ];

      options.node.fs.zfs.system = with lib; {
        luksPasswordFile = mkOption {
          type = types.path;
          description = ''
            Path to the file containing the disk encryption passphrase.

            Only used at provisioning time to encrypt the disk.
          '';
        };
        disk = mkOption {
          type = types.str;
          example = "/dev/disk/by-id/ata-WDC_WDS400T1R0A-68A4W0_21083X800070";
          description = ''
            The path under /dev to the disk used for the system.
          '';
        };
      };

      config =
        let
          cfg = config.node.fs.zfs.system;
        in
        {
          boot.initrd = {
            kernelModules = [ "zfs" ];
            supportedFilesystems.zfs = true;
          };

          # The nixpkgs-generated zfs-import-root.service polls for the pool
          # for a hardcoded ~60s, racing the LUKS passphrase prompt: type
          # slower than that and the import fails, collapsing sysroot.mount
          # into emergency mode (observed on term-x1p, boot 9348afe0…,
          # 2026-08-03). Gate the import on cryptsetup.target so the poll only
          # starts once the mapping exists. The passphrase prompt itself has
          # no timeout (crypttab default), so boot waits indefinitely at the
          # prompt instead.
          # https://github.com/nix-community/disko/issues/1257
          boot.initrd.systemd.services.zfs-import-root = {
            after = [ "cryptsetup.target" ];
            requires = [ "cryptsetup.target" ];
          };

          disko.devices.disk.system = {
            type = "disk";
            device = cfg.disk;
            content = {
              type = "gpt";
              partitions.luks = {
                size = "100%";
                content = {
                  type = "luks";
                  name = "crypted";
                  settings.allowDiscards = true;
                  passwordFile = cfg.luksPasswordFile;
                  content = {
                    type = "zfs";
                    pool = "root";
                  };
                };
              };
            };
          };
        };
    };
}
