# CalDAV task manager (TUI & CLI): https://codeberg.org/trougnouf/cfait
#
# cfait owns ~/.config/cfait/config.toml at runtime (it persists UI state and
# settings there), so the file is seeded once rather than symlinked from the
# store. The CalDAV password is vaulted in the OS keyring (gnome-keyring via
# the Secret Service DBus API); cfait looks it up with attributes
# {service=cfait, user=<username>}, which is exactly what `secret-tool store`
# writes below. The entry is NOT shared with Errands (different secret schema).
{
  moduleWithSystem,
  inputs,
  self,
  ...
}:
{
  flake.homeModules.programs-cfait = moduleWithSystem (
    perSystem@{ config, ... }:
    homeManager@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.nix-config-secrets.homeModules.services-cfait ];

      home.packages = [ perSystem.config.packages.cfait ];

      systemd.user.services.cfait-credentials =
        let
          username = homeManager.config.home.username;
          seed = pkgs.writeShellApplication {
            name = "cfait-seed-credentials";
            runtimeInputs = [ pkgs.libsecret ];
            text = ''
              umask 077

              # Contains a literal ''${XDG_CONFIG_HOME}; expanded by bash at runtime.
              config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/cfait"
              config="$config_dir/config.toml"
              if [ ! -e "$config" ]; then
                mkdir -p "$config_dir"
                printf 'url = "%s"\nusername = "%s"\n' \
                  "https://${self.lib.facts.services.radicale.domain}" \
                  "${username}" >"$config"
              fi

              passwd="$(cat "${homeManager.config.age.secrets."services/cfait.passwd".path}")"
              if [ -z "$passwd" ]; then
                echo "cfait password secret is empty" >&2
                exit 1
              fi
              printf '%s' "$passwd" | secret-tool store \
                --label="cfait (${username})" \
                service cfait user "${username}"
            '';
          };
        in
        {
          Unit = {
            Description = "Seed cfait CalDAV credentials from agenix secret";
            After = [ "agenix.service" ];
          };
          Service = {
            Type = "oneshot";
            ExecStart = lib.getExe seed;
          };
          Install.WantedBy = [ "default.target" ];
        };
    }
  );

  perSystem =
    { pkgs, ... }:
    {
      packages.cfait = pkgs.callPackage ./cfait { };
    };
}
