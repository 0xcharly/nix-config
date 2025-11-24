{flake, ...}: {
  config,
  lib,
  ...
}: {
  options.node.services.navidrome = with lib; {
    enable = mkEnableOption "Spin up a Navidrome service";
  };

  config = let
    cfg = config.node.services.navidrome;
    inherit (flake.lib) facts;
  in {
    services = {
      navidrome = {
        inherit (cfg) enable;
        settings = {
          Address = "0.0.0.0";
          BaseUrl = "https://${facts.services.navidrome.domain}";
          Port = facts.services.navidrome.port;
          MusicFolder = "/tank/delay/media/music";
          EnableInsightsCollector = false;
        };
      };
    };
  };
}
