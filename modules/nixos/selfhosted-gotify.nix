{ flake, ... }:
{
  config,
  lib,
  ...
}:
{
  options.node.services.gotify = with lib; {
    enable = mkEnableOption "Spin up a Gotify service";
  };

  config =
    let
      cfg = config.node.services.gotify;
      inherit (flake.lib) facts;
    in
    {
      services = {
        gotify = {
          inherit (cfg) enable;
          environment.GOTIFY_SERVER_PORT = facts.services.gotify.port;
          environmentFiles = [ config.age.secrets."services/gotify.env".path ];
        };
      };
    };
}
