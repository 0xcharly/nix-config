{ self, inputs, ... }:
{
  flake.homeModules.atuin-sync =
    { config, ... }:
    {
      imports = [ inputs.nix-config-secrets.homeModules.services-atuin ];

      programs.atuin = {
        settings = {
          auto_sync = true;
          key_path = config.age.secrets."services/atuin.key".path;
          session_path = config.age.secrets."services/atuin.session".path;
          sync_frequency = "5m";
          sync_address = "https://${self.lib.facts.services.atuin.domain}";
        };
      };
    };
}
