{ self, ... }:
{
  flake.nixosModules.services-github-backup =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (self.lib) facts gatus;

      # PR josegonzalez/python-github-backup#521: GitHub deprecated
      # /users/{username}/subscriptions (2026-06-30 changelog) and the endpoint
      # now returns empty responses, breaking the watched-repos step of `--all`
      # backups. Watched repos for the authenticated user now come from
      # /user/subscriptions; other users warn and skip.
      # TODO(26.11): Drop this override once the PR lands in a nixpkgs release.
      github-backup = pkgs.github-backup.overrideAttrs (attrs: {
        patches = (attrs.patches or [ ]) ++ [
          ./github-backup/pr-521-watched-repositories-endpoint.patch
        ];
      });

      mkPushRequest =
        success:
        gatus.mkPushBasedExternalPostRequest {
          inherit pkgs success;
          domain = facts.services.gatus.domain;
          tokenFile = config.age.secrets."services/gatus-external-endpoints.token".path;
          group = "cron";
          endpoint = "GitHub backup";
        };

      reportResult = self.lib.builders.mkShellApplication pkgs {
        name = "github-backup-report-result";
        text = ''
          if [ "''${SERVICE_RESULT:-}" = "success" ]; then
            exec ${lib.getExe (mkPushRequest true)}
          else
            exec ${lib.getExe (mkPushRequest false)}
          fi
        '';
      };
    in
    {
      systemd.services.github-backup = {
        description = "Backup GitHub data";

        script = self.lib.builders.mkShellApplication pkgs {
          name = "github-backup";
          runtimeInputs = [ github-backup ];
          text = ''
            set -euo pipefail

            echo "Performing 0xcharly user backup…"
            github-backup \
              --token-fine file://${config.age.secrets."services/github-backup-usr-0xcharly.token".path} \
              --all \
              --private \
              --gists \
              --starred-gists \
              --bare \
              --output-directory /tank/backups/github/0xcharly \
              0xcharly

            echo "Performing soycount organization backup…"
            github-backup \
              --token-fine file://${config.age.secrets."services/github-backup-org-soycount.token".path} \
              --all \
              --private \
              --bare \
              --output-directory /tank/backups/github/soycount \
              --organization soycount

            echo "Fixing /tank/backups/github permissions…"
            chown -R git:git /tank/backups/github/0xcharly
            chown -R git:git /tank/backups/github/soycount
          '';
        };

        serviceConfig = {
          Type = "oneshot";
          User = "git";
          # "+" runs the hook as root: the Gatus token file is root-readable only,
          # and $SERVICE_RESULT covers every outcome (non-zero exit, timeout, kill).
          ExecStopPost = "+${reportResult}";
        };
        startAt = "02:00"; # Daily at 2am.
      };
    };
}
