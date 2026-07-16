{ self, ... }:
{
  flake.nixosModules.selfhosted-gatus-endpoints =
    { lib, ... }:
    let
      inherit (self.lib) facts gatus inventory;

      # NOTE: these checks only verify that the IPv6 address (the AAAA record) can
      # be resolved, not that the domain can be resolved _over_ IPv6.
      # TODO: also check resolver over IPv6?

      # NOTE: these checks only verify that ns1.pieceofenglish.fr and ns1.qyrnl.com
      # resolve against their respective nameservers.

      pieceofenglish-checks =
        domain:
        { ipv4, ipv6, ... }:
        lib.concatLists (
          lib.mapAttrsToList
            (ip: fun: [
              (fun domain "ns1.pieceofenglish.fr" {
                name = "${domain} 🎯 (via ns1)";
                conditions = [ "[BODY] == ${ip}" ];
              })
              (fun domain "ns2.pieceofenglish.fr" {
                name = "${domain} 🎯 (via ns2)";
                conditions = [ "[BODY] == ${ip}" ];
              })
              (fun domain "8.8.8.8" {
                name = "${domain} 🌐 (via Google)";
                conditions = [ "[BODY] == ${ip}" ];
              })
            ])
            {
              ${ipv4} = gatus.mkDnsIPv4Endpoint;
              ${ipv6} = gatus.mkDnsIPv6Endpoint;
            }
        );

      qyrnl-checks =
        domain:
        { ipv4, ipv6, ... }:
        let
          inherit (facts.dns."qyrnl.com") nameservers;
        in
        lib.concatLists (
          lib.mapAttrsToList
            (ip: fun: [
              (fun domain "ns1.qyrnl.com" {
                name = "${domain} 🎯 (via ns1)";
                conditions = [ "[BODY] == ${ip}" ];
              })
              (fun domain "ns2.qyrnl.com" {
                name = "${domain} 🎯 (via ns2)";
                conditions = [ "[BODY] == ${ip}" ];
              })
              (fun domain "8.8.8.8" {
                name = "${domain} 🌐 (via Google)";
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
          (qyrnl-checks "ns1.qyrnl.com" facts.dns."qyrnl.com".ns1)
          ++ (qyrnl-checks "ns2.qyrnl.com" facts.dns."qyrnl.com".ns2)
          ++ (pieceofenglish-checks "ns1.pieceofenglish.fr" facts.dns."pieceofenglish.fr".ns1)
          ++ (pieceofenglish-checks "ns2.pieceofenglish.fr" facts.dns."pieceofenglish.fr".ns2)
          ++ (map gatus.mkPingHostCheck inventory.gatus)
          ++ [
            (gatus.mkHttpServiceCheck "atuin" facts.services.atuin)
            (gatus.mkHttpServiceCheck "CalDAV" facts.services.radicale)
            (gatus.mkHttpServiceCheck "forgejo" facts.services.forgejo)
            (gatus.mkHttpServiceCheck "ggit" facts.services.ggit)
            (gatus.mkHttpServiceCheck "go/link" facts.services.go)
            (gatus.mkHttpServiceCheck "gotify" facts.services.gotify)
            (gatus.mkApiCheck "grafana" {
              url = "${facts.services.grafana.domain}/api/health";
              conditions = [ "[BODY].database == ok" ];
            })
            (gatus.mkHttpServiceCheck "immich-public-proxy" facts.services.immich-public-proxy)
            (gatus.mkHttpServiceCheck "immich" facts.services.immich)
            (gatus.mkHttpServiceCheck "jellyfin" facts.services.jellyfin)
            (gatus.mkHttpServiceCheck "lidarr" (facts.services.lidarr // { group = "servarr"; }))
            (gatus.mkHttpServiceCheck "linkwarden" facts.services.linkwarden)
            (gatus.mkHttpServiceCheck "miniflux" facts.services.miniflux)
            (gatus.mkHttpServiceCheck "navidrome" facts.services.navidrome)
            (gatus.mkHttpServiceCheck "paperless" facts.services.paperless)
            (gatus.mkHttpServiceCheck "prometheus" {
              domain = "${facts.services.prometheus.domain}/-/healthy";
            })
            (gatus.mkHttpCheck "qbittorrent" "http://node-skl.qyrnl.com:8080" { group = "servarr"; })
            (gatus.mkHttpServiceCheck "qui" (facts.services.qui // { group = "servarr"; }))
            (gatus.mkHttpServiceCheck "radarr" (facts.services.radarr // { group = "servarr"; }))
            (gatus.mkHttpServiceCheck "sonarr" (facts.services.sonarr // { group = "servarr"; }))
            (gatus.mkHttpServiceCheck "vaultwarden" facts.services.vaultwarden)
            # NOTE: the smtp/submissions checks originate from gate-jp, a
            # Linode, so they stay red (and alert) until Linode lifts the
            # account's outbound 25/465/587 restriction — expected during the
            # bring-up window.
            (gatus.mkTcpCheck "imaps" "${facts.mail.fqdn}:993")
            (gatus.mkTcpCheck "smtp" "${facts.mail.fqdn}:25")
            (gatus.mkTcpCheck "submissions" "${facts.mail.fqdn}:465")
            (gatus.mkRdnsCheck "rdns IPv4" facts.dns."delay.email".mx.ipv4 facts.mail.fqdn)
            (gatus.mkRdnsCheck "rdns IPv6" facts.dns."delay.email".mx.ipv6 facts.mail.fqdn)
          ];

        external-endpoints = [
          (gatus.mkPushBasedExternalEndpoint "GitHub backup" { heartbeat = "48h"; })
          (gatus.mkPushBasedExternalEndpoint "node-skl exit node" { heartbeat = "5m"; })
          (gatus.mkPushBasedExternalEndpoint "Mail archive" { heartbeat = "2h"; })
          (gatus.mkPushBasedExternalEndpoint "Mail egress" {
            group = "mail";
            heartbeat = "2h";
          })
          (gatus.mkPushBasedExternalEndpoint "Mail retention purge" { heartbeat = "48h"; })
        ]
        # 48h ≈ two missed daily runs, matching the "GitHub backup" convention.
        ++ lib.mapAttrsToList (
          _: replica:
          gatus.mkPushBasedExternalEndpoint "ZFS replication ${replica.label}" { heartbeat = "48h"; }
        ) facts.nas.replicas
        ++ map (
          host: gatus.mkPushBasedExternalEndpoint "ZFS encryption ${host}" { heartbeat = "48h"; }
        ) inventory.nas
        # Hourly check (fs-zfs-snapshots-check): 3h ≈ two missed runs.
        ++ map (
          host: gatus.mkPushBasedExternalEndpoint "ZFS snapshots ${host}" { heartbeat = "3h"; }
        ) inventory.nas;
      };
    };
}
