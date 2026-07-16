{
  flake.nixosModules.services-qbittorrent =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.node.services.qbittorrent;
    in
    {
      options.node.services.qbittorrent = with lib; {
        enable = mkEnableOption "Spin up a qBittorrent instance";
      };

      config = lib.mkIf cfg.enable {
        services.qbittorrent = {
          enable = true;
          webuiPort = 8080;
          # torrentingPort stays null: no inbound behind a Mullvad exit node.
          serverConfig = {
            LegalNotice.Accepted = true;
            BitTorrent.Session = {
              # Bind torrent traffic to the tunnel: with tailscaled down there is no
              # interface to send on — fail-closed even before the killswitch fires.
              Interface = config.services.tailscale.interfaceName;
              InterfaceName = config.services.tailscale.interfaceName;
              DefaultSavePath = "/srv/torrents";
            };
            # No WebUI Address restriction: default binding (all interfaces) so the
            # Gatus poll from gate-jp can reach it; tailnet clients only see the
            # login wall. Localhost bypass is what qui and the arrs use.
            Preferences.WebUI.LocalHostAuth = false;
          };
        };

        # Killswitch layer 1: qbittorrent cannot outlive tailscaled.
        systemd.services.qbittorrent = {
          bindsTo = [ "tailscaled.service" ];
          after = [ "tailscaled.service" ];
        };

        users.users.qbittorrent.extraGroups = [ "media" ];
        users.groups.media = { };
        systemd.tmpfiles.rules = [ "d /srv/torrents 2775 qbittorrent media -" ];
      };
    };
}
