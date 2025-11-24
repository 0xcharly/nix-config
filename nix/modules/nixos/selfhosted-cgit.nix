{flake, ...}: {
  config,
  lib,
  ...
}: {
  options.node.services.cgit = with lib; {
    enable = mkEnableOption "Spin up a cgit service";
  };

  config = let
    cfg = config.node.services.cgit;
    inherit (flake.lib) caddy facts;
  in {
    services = {
      cgit.github = {
        inherit (cfg) enable;
        scanPath = "/tank/backups/github";
        nginx.virtualHost = facts.services.cgit.domain;
      };

      caddy.virtualHosts = caddy.mkReverseProxyConfig facts.services.cgit;
    };

    users.users.${config.services.cgit.github.user}.extraGroups = ["git"];
  };
}
