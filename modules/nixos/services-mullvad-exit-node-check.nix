{ self, ... }:
{
  flake.nixosModules.services-mullvad-exit-node-check =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.node.services.mullvad-exit-node-check;
      inherit (self.lib) facts gatus;

      mkPushRequest =
        success:
        gatus.mkPushBasedExternalPostRequest {
          inherit pkgs success;
          domain = facts.services.gatus.domain;
          tokenFile = config.age.secrets."services/gatus-external-endpoints.token".path;
          group = "cron";
          endpoint = cfg.endpoint;
        };
    in
    {
      options.node.services.mullvad-exit-node-check = with lib; {
        enable = mkEnableOption "Whether to schedule a periodic Mullvad exit node check";
        onCalendar = mkOption {
          type = types.str;
          default = "minutely";
          description = ''
            When to run the check, as a systemd.time(7) calendar expression.
            Defaults to every minute.
          '';
        };
        endpoint = mkOption {
          type = types.str;
          default = "${config.networking.hostName} exit node";
          description = ''
            Name of the Gatus external endpoint to push the check result to.
          '';
        };
        killswitch = {
          units = mkOption {
            type = types.listOf types.str;
            default = [ ];
            example = [ "qbittorrent.service" ];
            description = "systemd units to stop when the VPN check fails.";
          };
          mode = mkOption {
            type = types.enum [
              "latch"
              "gate"
            ];
            default = "latch";
            description = ''
              latch: stopped units stay stopped until started manually.
              gate: units are started again on the next passing check (note: this
              also undoes a manual `systemctl stop` within a minute).
            '';
          };
        };
      };

      config = lib.mkIf cfg.enable {
        systemd.services.mullvad-exit-node-check = {
          description = "Check that this host egresses via a Mullvad exit node";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];

          script = self.lib.builders.mkShellApplication pkgs {
            name = "mullvad-exit-node-check";
            runtimeInputs = with pkgs; [
              curl
              jq
              systemd
            ];
            text = ''
              ok=true

              # IPv4 egress must be a Mullvad exit.
              if ! curl -4 -sS --max-time 20 https://am.i.mullvad.net/json | jq --exit-status '.mullvad_exit_ip == true'; then
                ok=false
              fi

              # IPv6 egress: only a reachable non-Mullvad path is a leak; no IPv6
              # connectivity means no IPv6 leak.
              if response=$(curl -6 -sS --max-time 20 https://ipv6.am.i.mullvad.net/json); then
                if ! jq --exit-status '.mullvad_exit_ip == true' <<<"$response"; then
                  ok=false
                fi
              fi

              # DNS leak: resolve a unique name under Mullvad's leak-check domain, then ask
              # the API which resolvers hit their authoritative servers. Any non-Mullvad
              # resolver, an empty result, or inability to verify is a failure.
              if leak_domain=$(curl -sS --max-time 20 https://am.i.mullvad.net/config | jq --exit-status --raw-output '.dns_leak_domain'); then
                id=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')
                curl -sS --max-time 10 "https://$id.$leak_domain/" >/dev/null || true
                result='[]'
                for _ in 1 2 3; do
                  sleep 2
                  result=$(curl -sS --max-time 20 "https://am.i.mullvad.net/dnsleak/$id") || result='[]'
                  if [ "$(jq 'length' <<<"$result")" -gt 0 ]; then
                    break
                  fi
                done
                if ! jq --exit-status 'length > 0 and all(.[]; .mullvad_dns == true)' <<<"$result"; then
                  ok=false
                fi
              else
                ok=false
              fi

              if "$ok"; then
                ${lib.optionalString (cfg.killswitch.mode == "gate" && cfg.killswitch.units != [ ]) ''
                  systemctl start -- ${lib.escapeShellArgs cfg.killswitch.units}
                ''}
                ${lib.getExe (mkPushRequest true)}
              else
                ${lib.optionalString (cfg.killswitch.units != [ ]) ''
                  systemctl stop -- ${lib.escapeShellArgs cfg.killswitch.units}
                ''}
                ${lib.getExe (mkPushRequest false)}
              fi
            '';
          };

          serviceConfig.Type = "oneshot";
          startAt = cfg.onCalendar;
        };
      };
    };
}
