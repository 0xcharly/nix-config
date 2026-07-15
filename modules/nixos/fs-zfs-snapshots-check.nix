{ self, ... }:
{
  flake.nixosModules.fs-zfs-snapshots-check =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (self.lib) facts gatus;

      mkPushRequest =
        success:
        gatus.mkPushBasedExternalPostRequest {
          inherit pkgs success;
          domain = facts.services.gatus.domain;
          tokenFile = config.age.secrets."services/gatus-external-endpoints.token".path;
          group = "cron";
          endpoint = "ZFS snapshots ${config.networking.hostName}";
        };

      # The sanoid module renders its config into a store path passed via
      # `--configdir` and does not expose it as an option; recover it from
      # the unit's ExecStart (escapeShellArgs quotes tokens only when
      # needed, so accept both forms). Fails evaluation loudly if the
      # module ever changes shape.
      configdir =
        let
          matches = builtins.match ".*--configdir '?([^ ']+)'?.*" config.systemd.services.sanoid.serviceConfig.ExecStart;
        in
        if matches == null then
          throw "fs-zfs-snapshots-check: cannot extract --configdir from the sanoid unit's ExecStart"
        else
          builtins.head matches;
    in
    {
      systemd.services.zfs-snapshots-check = {
        description = "Check snapshot freshness on `tank` against the sanoid policy";
        after = [ "zfs-mount-tank.service" ];
        wants = [ "zfs-mount-tank.service" ];

        script = self.lib.builders.mkShellApplication pkgs {
          name = "zfs-snapshots-check";
          runtimeInputs = [ config.services.sanoid.package ];
          text = ''
            # Nagios-style: exit 0 OK, 1 WARN, >=2 CRIT. WARN is logged but
            # still reports healthy — warn thresholds trip transiently (e.g.
            # replica staleness during a long transfer); the crit thresholds
            # are the alerting contract. --force-update: monitor-only runs
            # otherwise accept a snapshot cache up to 5h stale, defeating
            # hourly freshness checks. Private cache/run dirs: the sanoid
            # unit's cache belongs to its DynamicUser and must not be
            # touched by root.
            status=0
            sanoid --monitor-snapshots \
              --force-update \
              --configdir ${configdir} \
              --cache-dir "$CACHE_DIRECTORY" \
              --run-dir "$RUNTIME_DIRECTORY" || status=$?

            if [ "$status" -lt 2 ]; then
              exec ${lib.getExe (mkPushRequest true)}
            else
              exec ${lib.getExe (mkPushRequest false)}
            fi
          '';
        };

        serviceConfig = {
          Type = "oneshot";
          CacheDirectory = "zfs-snapshots-check";
          RuntimeDirectory = "zfs-snapshots-check";
        };
        # Hourly at :30: clear of sanoid's :00 runs on the primary and of the
        # daily replication window (22:15 UTC) on the replica.
        startAt = "*:30:00";
      };
    };
}
