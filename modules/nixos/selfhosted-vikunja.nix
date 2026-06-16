{ self, ... }:
{
  flake.nixosModules.selfhosted-vikunja =
    { config, lib, ... }:
    {
      options.node.services.vikunja = with lib; {
        enable = mkEnableOption "Spin up a Vikunja service";
      };

      config =
        let
          cfg = config.node.services.vikunja;
          inherit (self.lib) facts;
        in
        {
          services.vikunja = {
            inherit (cfg) enable;
            inherit (facts.services.vikunja) port;
            address = "0.0.0.0";
            database.type = "sqlite";
            frontendScheme = "https";
            frontendHostname = facts.services.vikunja.domain;
            environmentFiles = [ config.age.secrets."services/vikunja.env".path ];
            settings.service.enableregistration = false;
          };
        };
    };
}
