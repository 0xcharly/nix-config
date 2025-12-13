{flake, ...}: {pkgs, ...}: {
  # Automatically mount the ZFS pool when agenix secrets are mounted.
  systemd.services.zfs-mount-tank = {
    description = "Mount ZFS pool `tank` and its datasets";

    # Wait for the agenix service to be running / complete before mounting the ZFS pool.
    after = ["run-agenix.d.mount" "zfs-import.target"];
    requires = ["run-agenix.d.mount" "zfs-import.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = flake.lib.builders.mkShellApplication pkgs {
        name = "mount-tank";
        runtimeInputs = with pkgs; [coreutils zfs];
        text = ''
          set -euo pipefail

          if ! zpool list tank >/dev/null 2>&1; then
            echo "Importing ZFS pool 'tank'…"
            zpool import tank
          else
            echo "ZFS pool 'tank' is already online."
          fi

          echo "Mounting ZFS datasets for /tank…"
          # NOTE: The following mounts all datasets in the pool, not only tank.
          # Reconsider this if we add more pools.
          zfs mount -a -l

          echo "Fixing permissions for /tank…"
          # Create the directories for the ZFS datasets, with the correct permissions.
          # TODO: Consider creating groups as well (eg. `backups`?).

          # Set tank root folder world-traversable.
          install -v -d --mode 751 --owner root  --group root     /tank

          # Set backup root folder world-traversable.
          install -v -d --mode 751 --owner delay --group users    /tank/backups
          install -v -d --mode 750 --owner ayako --group ayako    /tank/backups/ayako
          install -v -d --mode 750 --owner delay --group delay    /tank/backups/dad
          install -v -d --mode 750 --owner delay --group delay    /tank/backups/delay
          install -v -d --mode 750 --owner delay --group git      /tank/backups/github
          install -v -d --mode 750 --owner delay --group delay    /tank/backups/homelab

          install -v -d --mode 751 --owner ayako --group users    /tank/ayako
          install -v -d --mode 750 --owner ayako --group ayako    /tank/ayako/files
          install -v -d --mode 750 --owner ayako --group users    /tank/ayako/media

          install -v -d --mode 751 --owner delay --group users       /tank/delay
          install -v -d --mode 770 --owner delay --group immich      /tank/delay/album
          install -v -d --mode 750 --owner delay --group delay       /tank/delay/beans
          install -v -d --mode 770 --owner delay --group paperless   /tank/delay/files
          install -v -d --mode 751 --owner delay --group jellyfin    /tank/delay/media
          install -v -d --mode 750 --owner delay --group delay       /tank/delay/notes
          install -v -d --mode 770 --owner delay --group vaultwarden /tank/delay/vault

          install -v -d --mode 751 --owner delay --group forgejo  /tank/delay/forge
          install -v -d --mode 770 --owner delay --group forgejo  /tank/delay/forge/data
          install -v -d --mode 770 --owner delay --group forgejo  /tank/delay/forge/repo
        '';
      };
    };
  };
}
