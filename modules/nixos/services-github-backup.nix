{flake, ...}: {
  config,
  pkgs,
  ...
}: {
  systemd.services.github-backup = {
    description = "Backup GitHub data";

    script = flake.lib.builders.mkShellApplication pkgs {
      name = "mount-tank";
      runtimeInputs = with pkgs; [github-backup];
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
    };
    startAt = "02:00"; # Daily at 2am.
  };
}
