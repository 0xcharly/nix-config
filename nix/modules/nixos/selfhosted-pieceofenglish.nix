{
  flake,
  inputs,
  ...
}: {
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    inputs.nix-config-secrets.modules.nixos.services-pieceofenglish
    inputs.pieceofenglish.nixosModules.default
  ];

  options.node.services.pieceofenglish = with lib; {
    enable = mkEnableOption "Spin up a Pieceofenglish service";
    reverse-proxy = {
      enable = mkEnableOption "Set up reverse proxy service for pieceofenglish.fr";
      openFirewall = mkEnableOption "Open firewall ports for Piece of English service";
      bindInterface = lib.mkOption {
        type = lib.types.str;
        example = "eth0";
        description = "The network interface to bind to.";
      };
    };
  };

  config = let
    cfg = config.node.services.pieceofenglish;
    inherit (flake.lib) caddy facts gatus;
  in {
    node.fs.zfs.zpool.root.datadirs = lib.mkIf cfg.enable {
      pieceofenglish = {
        owner = config.services.pieceofenglish.user;
        group = config.services.pieceofenglish.group;
        mode = "0700";
      };
    };

    services = {
      pieceofenglish = {
        inherit (cfg) enable;
        inherit (facts.services.pieceofenglish) port;

        baseUrl = facts.services.pieceofenglish.domain;
        dataDir = config.node.fs.zfs.zpool.root.datadirs.pieceofenglish.absolutePath;
        environmentFile = config.age.secrets."services/pieceofenglish.env".path;
      };

      # NOTE: DNS-01 validation via Gandi requires the DNS zone to be hosted on
      # Gandi’s nameservers. Since this domain is managed by our own
      # authoritative DNS server, the Gandi DNS plugin cannot create the
      # _acme-challenge TXT record automatically.
      #
      # Therefore, ACME/Let's Encrypt certificates must be obtained using the
      # HTTP-01 challenge instead. DO NOT configure:
      #
      #     dns gandi {env.GANDIV5_PERSONAL_ACCESS_TOKEN}
      #
      # or Caddy will repeatedly fail with:
      #     "timed out waiting for record to fully propagate"
      #
      # To re-enable DNS-01 in the future, migrate the DNS zone back to Gandi or
      # implement a custom DNS provider plugin.
      caddy = lib.mkIf cfg.reverse-proxy.enable {
        inherit (cfg.reverse-proxy) enable;
        virtualHosts = lib.mergeAttrsList [
          (caddy.mkReverseProxyConfig (facts.services.pieceofenglish
            // {
              host = config.services.pieceofenglish.listenAddress;
              import = "";
            }))
          (caddy.mkWwwRedirectConfig facts.services.pieceofenglish)
        ];
      };

      gatus.settings.endpoints = [
        (gatus.mkHttpServiceCheck "pieceofenglish" facts.services.pieceofenglish)
      ];
    };

    systemd.services.caddy.serviceConfig = lib.mkIf cfg.reverse-proxy.enable {
      AmbientCapabilities = ["CAP_NET_BIND_SERVICE"]; # Allow Caddy to bind to 443.
    };

    networking.firewall = lib.mkIf (cfg.reverse-proxy.enable && cfg.reverse-proxy.openFirewall) {
      interfaces.${cfg.reverse-proxy.bindInterface}.allowedTCPPorts = [80 443];
    };
  };
}
