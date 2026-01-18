{ flake, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.node.services.cgit = with lib; {
    enable = mkEnableOption "Spin up a cgit service";
  };

  config =
    let
      cfg = config.node.services.cgit;
      inherit (flake.lib) facts;
    in
    {
      services = {
        cgit.github = {
          inherit (cfg) enable;
          package = pkgs.cgit-pink;
          scanPath = "/tank/backups/github";
          nginx.virtualHost = facts.services.cgit.domain;

          # cgit-pink options.
          extraConfig = ''
            css=/custom.css
            side-by-side-diffs=true
          '';
        };
        nginx.virtualHosts.${facts.services.cgit.domain}.locations."= /custom.css".extraConfig = ''
          alias ${./selfhosted-cgit.css};
        '';
      };
    };
}
