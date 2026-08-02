{ self, ... }:
{
  flake.nixosModules.fs-zfs-encryption-check =
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
          endpoint = "ZFS encryption ${config.networking.hostName}";
        };
    in
    {
      systemd.services.zfs-encryption-check = {
        description = "Check that every leaf dataset in `tank` is encrypted";
        after = [ "zfs-mount-tank.service" ];
        wants = [ "zfs-mount-tank.service" ];

        script = self.lib.builders.mkShellApplication pkgs {
          name = "zfs-encryption-check";
          runtimeInputs = [ config.boot.zfs.package ];
          text = ''
            # Every leaf dataset (no children) must be encrypted; the
            # container datasets are unencrypted by design. A plain-send
            # `zfs receive` that recreates a dataset would inherit its
            # container's encryption=off — this catches it within a day.
            check_leaves_encrypted() {
              local datasets ds encryption ok=0
              mapfile -t datasets < <(zfs list -H -o name -r -t filesystem tank) || return 1
              [ "''${#datasets[@]}" -gt 0 ] || return 1
              for ds in "''${datasets[@]}"; do
                case "$ds" in
                # Deliberately unencrypted, non-replicated migration insurance
                # (received via plain send, so encryption=off is expected —
                # the exact signature this check exists to catch elsewhere).
                # The bare name matters too: with no children it would count
                # as a leaf. TODO: delete when migration is complete.
                tank/migration-backups | tank/migration-backups/*) continue ;;
                esac
                if printf '%s\n' "''${datasets[@]}" | grep -q "^$ds/"; then
                  continue # container dataset; its children are checked individually
                fi
                encryption=$(zfs get -H -o value encryption "$ds") || return 1
                if [ "$encryption" != "aes-256-gcm" ]; then
                  echo "Unencrypted leaf dataset: $ds (encryption=$encryption)"
                  ok=1
                fi
              done
              return "$ok"
            }

            if check_leaves_encrypted; then
              exec ${lib.getExe (mkPushRequest true)}
            else
              exec ${lib.getExe (mkPushRequest false)}
            fi
          '';
        };

        serviceConfig.Type = "oneshot";
        # Daily, after the nightly replication window (00:15–~06:00 Paris).
        startAt = "*-*-* 08:00:00 Europe/Paris";
      };
    };
}
