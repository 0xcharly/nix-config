{ flake, ... }:
{ lib, ... }:
let
  inherit (flake.lib) facts gatus inventory;

  # NOTE: these checks only verify that the IPv6 address (the AAAA record) can
  # be resolved, not that the domain can be resolved _over_ IPv6.
  # TODO: also check resolver over IPv6?

  # NOTE: these checks only verify that @.pieceofenglish.fr and ns1.qyrnl.com
  # resolve against their respective nameservers.
  pieceofenglish-checks =
    let
      inherit (facts.dns."pieceofenglish.fr") nameservers;
      inherit (facts.dns."pieceofenglish.fr"."@") ipv4 ipv6;

      # Domain to check.
      domain = "pieceofenglish.fr";
    in
    lib.concatLists (
      lib.mapAttrsToList
        (ip: fun: [
          (fun domain "ns1.pieceofenglish.fr" {
            name = "pieceofenglish.fr 🎯 (via ns1)";
            conditions = [ "[BODY] == ${ip}" ];
          })
          (fun domain "ns2.pieceofenglish.fr" {
            name = "pieceofenglish.fr 🎯 (via ns2)";
            conditions = [ "[BODY] == ${ip}" ];
          })
          (fun domain "8.8.8.8" {
            name = "pieceofenglish.fr 🌐 (via Google)";
            conditions = [ "[BODY] == ${ip}" ];
          })
        ])
        {
          ${ipv4} = gatus.mkDnsIPv4Endpoint;
          ${ipv6} = gatus.mkDnsIPv6Endpoint;
        }
    );

  # NOTE: this currently only check that the IPv6 address (the AAAA record)
  # can be resolved, not that the domain can be resolved _over_ IPv6.
  qyrnl-checks =
    let
      inherit (facts.dns."qyrnl.com") nameservers;
      inherit (facts.dns."qyrnl.com".ns1) ipv4 ipv6;

      # Domain to check.
      domain = "ns1.qyrnl.com";
    in
    lib.concatLists (
      lib.mapAttrsToList
        (ip: fun: [
          (fun domain "ns1.qyrnl.com" {
            name = "ns1.qyrnl.com 🎯 (via ns1)";
            conditions = [ "[BODY] == ${ip}" ];
          })
          (fun domain "ns2.qyrnl.com" {
            name = "ns1.qyrnl.com 🎯 (via ns2)";
            conditions = [ "[BODY] == ${ip}" ];
          })
          (fun domain "8.8.8.8" {
            name = "ns1.qyrnl.com 🌐 (via Google)";
            rcode = "NXDOMAIN"; # Should _not_ resolve publicly.
          })
        ])
        {
          ${ipv4} = gatus.mkDnsIPv4Endpoint;
          ${ipv6} = gatus.mkDnsIPv6Endpoint;
        }
    );
in
{
  services.gatus.settings = {
    endpoints =
      qyrnl-checks
      ++ pieceofenglish-checks
      ++ (map gatus.mkPingHostCheck inventory.servers)
      ++ [
        (gatus.mkHttpServiceCheck "atuin" facts.services.atuin)
        (gatus.mkHttpServiceCheck "CalDAV" facts.services.radicale)
        (gatus.mkHttpServiceCheck "cgit" facts.services.cgit)
        # (gatus.mkHttpServiceCheck "calibre-web" facts.services.calibre-web)
        (gatus.mkHttpServiceCheck "forgejo" facts.services.forgejo)
        (gatus.mkHttpServiceCheck "go/link" facts.services.go)
        (gatus.mkHttpServiceCheck "gotify" facts.services.gotify)
        (gatus.mkApiCheck "grafana" {
          url = "${facts.services.grafana.domain}/api/health";
          conditions = [ "[BODY].database == ok" ];
        })
        (gatus.mkHttpServiceCheck "immich-public-proxy" facts.services.immich-public-proxy)
        (gatus.mkHttpServiceCheck "immich" facts.services.immich)
        (gatus.mkHttpServiceCheck "jellyfin" facts.services.jellyfin)
        (gatus.mkHttpServiceCheck "linkwarden" facts.services.linkwarden)
        (gatus.mkHttpServiceCheck "miniflux" facts.services.miniflux)
        (gatus.mkHttpServiceCheck "navidrome" facts.services.navidrome)
        (gatus.mkHttpServiceCheck "paperless" facts.services.paperless)
        (gatus.mkHttpServiceCheck "Piece of English" facts.services.pieceofenglish)
        (gatus.mkHttpServiceCheck "prometheus" {
          domain = "${facts.services.prometheus.domain}/-/healthy";
        })
        (gatus.mkHttpServiceCheck "search" facts.services.search)
        (gatus.mkHttpServiceCheck "vaultwarden" facts.services.vaultwarden)
      ];

    external-endpoints = [
      (gatus.mkPushBasedExternalEndpoint "GitHub backup" { heartbeat = "48h"; })
    ];
  };
}
