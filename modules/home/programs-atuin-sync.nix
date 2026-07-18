{ self, inputs, ... }:
{
  flake.homeModules.programs-atuin-sync =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [ inputs.nix-config-secrets.homeModules.services-atuin ];

      programs.atuin = {
        settings = {
          auto_sync = true;
          key_path = config.age.secrets."services/atuin.key".path;
          sync_frequency = "5m";
          sync_address = "https://${self.lib.facts.services.atuin.domain}";
        };
      };

      systemd.user.services.atuin-session =
        let
          seed = pkgs.writeShellApplication {
            name = "atuin-seed-session";
            runtimeInputs = [ pkgs.sqlite ];
            text = ''
              umask 077

              # Contains a literal ''${XDG_RUNTIME_DIR}; expanded by bash at runtime.
              token="$(tr -d '[:space:]' < "${config.age.secrets."services/atuin.session".path}")"
              if [ -z "$token" ]; then
                echo "atuin session secret is empty" >&2
                exit 1
              fi

              db="''${XDG_DATA_HOME:-$HOME/.local/share}/atuin/meta.db"
              mkdir -p "$(dirname "$db")"

              # Schema copied verbatim from atuin's meta-migrations/20260203030924_create_meta.sql
              # ("create table if not exists"), so seeding before atuin's first run is safe and
              # atuin's own sqlx migration remains a no-op afterwards.
              sqlite3 "$db" <<SQL
              create table if not exists meta (
                  key text not null primary key,
                  value text not null,
                  updated_at integer not null default (strftime('%s', 'now'))
              );
              insert into meta (key, value, updated_at)
                values ('session', '$token', strftime('%s', 'now'))
                on conflict(key) do update set
                  value = excluded.value, updated_at = excluded.updated_at;
              SQL
            '';
          };
        in
        {
          Unit = {
            # atuin >= 18.15 reads the sync session token from meta.db only
            # (upstream PR #3317); session_path was removed. Seed the token from
            # the agenix secret so login stays declarative.
            Description = "Seed atuin sync session token from agenix secret";
            After = [ "agenix.service" ];
          };
          Service = {
            Type = "oneshot";
            ExecStart = lib.getExe seed;
          };
          Install.WantedBy = [ "default.target" ];
        };
    };
}
