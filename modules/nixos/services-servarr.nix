{ self, ... }:
{
  flake.nixosModules.services-servarr =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.node.services.servarr;
      inherit (self.lib) facts;
    in
    {
      options.node.services.servarr = with lib; {
        enable = mkEnableOption "Spin up radarr, sonarr, lidarr, and prowlarr";
      };

      config = lib.mkIf cfg.enable {
        services.radarr = {
          enable = true;
          settings.server.port = facts.services.radarr.port;
        };
        services.sonarr = {
          enable = true;
          settings.server.port = facts.services.sonarr.port;
        };
        services.lidarr = {
          enable = true;
          settings.server.port = facts.services.lidarr.port;
        };
        services.prowlarr = {
          enable = true;
          settings.server.port = facts.services.prowlarr.port;
        };

        users.users.radarr.extraGroups = [ "media" ];
        users.users.sonarr.extraGroups = [ "media" ];
        users.users.lidarr.extraGroups = [ "media" ];
        users.groups.media = { };

        # Library layout mirrors site-jp's tank/delay/media (movies/shows/animes) so
        # a future NFS-from-NAS migration is a root-folder path swap, not a rename.
        systemd.tmpfiles.rules = [
          "d /srv/media 2775 root media -"
          "d /srv/media/movies 2775 radarr media -"
          "d /srv/media/shows 2775 sonarr media -"
          "d /srv/media/animes 2775 sonarr media -"
          "d /srv/media/music 2775 lidarr media -"
        ];

        # No firewall openings: tailscaled's ts-input chain accepts tailnet traffic
        # (same convention as every other tailnet-facing service in this repo).
      };
    };
}
