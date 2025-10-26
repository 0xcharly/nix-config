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
          install -v -d --mode 750 --owner delay --group delay    /tank/backups/homelab

          install -v -d --mode 750 --owner ayako --group users    /tank/ayako
          install -v -d --mode 750 --owner ayako --group ayako    /tank/ayako/files
          install -v -d --mode 750 --owner ayako --group users    /tank/ayako/media

          install -v -d --mode 750 --owner delay --group users    /tank/delay
          install -v -d --mode 770 --owner delay --group immich   /tank/delay/album
          install -v -d --mode 750 --owner delay --group delay    /tank/delay/beans
          install -v -d --mode 750 --owner delay --group delay    /tank/delay/files
          install -v -d --mode 750 --owner delay --group jellyfin /tank/delay/media
          install -v -d --mode 750 --owner delay --group delay    /tank/delay/notes
          install -v -d --mode 750 --owner delay --group delay    /tank/delay/vault

          install -v -d --mode 750 --owner delay --group forgejo  /tank/delay/forge
          install -v -d --mode 770 --owner delay --group forgejo  /tank/delay/forge/data
          install -v -d --mode 770 --owner delay --group forgejo  /tank/delay/forge/repo
        '';
      };
    };
  };

  # NOTE: services-related group currently need to exist to set the proper
  # permissions on the secondaries. Would it be better to simply keep files
  # separate from backups? (i.e. /tank/delay and /tank/ayako only exist on the
  # primary?) Or should we just systematically create all users on all machines?
  # Seems like this would unnecessarily increase the attack surface…
  # TODO: figure out a better way to do this.
  users.groups = {
    forgejo = {};
    immich = {};
    jellyfin = {};
  };
}
