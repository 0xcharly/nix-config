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
          default = "*:0/2";
          description = ''
            When to run the check, as a systemd.time(7) calendar expression.
            Defaults to every 2 minutes.
          '';
        };
        endpoint = mkOption {
          type = types.str;
          default = "${config.networking.hostName} exit node";
          description = ''
            Name of the Gatus external endpoint to push the check result to.
          '';
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
            ];
            text = ''
              if curl -sS --max-time 30 https://am.i.mullvad.net/json | jq --exit-status '.mullvad_exit_ip == true'; then
                ${lib.getExe (mkPushRequest true)}
              else
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
