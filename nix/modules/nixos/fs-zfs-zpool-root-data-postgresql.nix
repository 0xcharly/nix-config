{
  config,
  lib,
  ...
}: {
  options.node.services.postgresql = with lib; {
    enable = mkEnableOption "Sets up ZFS datasets and postgresql options" // {
      default = config.services.postgresql.enable;
    };
  };

  config = let
    cfg = config.node.services.postgresql;
  in {
    node.fs.zfs.zpool.root.datadirs = lib.mkIf cfg.enable {
      postgresql = {
        owner = "postgres";
        group = "postgres";
        mode = "0750";
        extraOptions = {
          atime = "off"; # Disables updating access times.
          compression = "lz4"; # Fast and space-efficient.
          dedup = "off"; # PostgreSQL data patterns don’t benefit from dedup.
          logbias = "throughput"; # PostgreSQL already manages sync writes via WAL (Write Ahead Log).
          recordsize = "8k"; # PostgreSQL uses 8 KiB pages internally.
        };
      };
      "postgresql/${config.services.postgresql.package.psqlSchema}/pg_wal" = {
        owner = "postgres";
        group = "postgres";
        mode = "0700";
        # Other options are inherited from the parent dataset.
        extraOptions.recordsize = "128K"; # Larger blocks improve performance for large sequential files.
      };
    };

    assertions = [
      {
        assertion = config.services.postgresql.enable -> cfg.enable;
        message = "Enable custom postgresql module to finetune filesystem and options";
      }
    ];
  };
}
