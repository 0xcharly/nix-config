# Config derived from:
#   - https://willnorris.com/2023/tailscale-custom-domain/
#   - https://garrido.io/notes/tailscale-nextdns-custom-domains/
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.node.services.dns;
in {
  options.node.services.dns.enable = lib.mkEnableOption "Whether to spin up a DNS server.";

  imports = [
    {
      # NOTE: this currently only check that the IPv6 address (the AAAA record)
      # can be resolved, not that the domain can be resolved _over_ IPv6.
      # TODO: also check resolver over IPv6?
      config.services.gatus.settings.endpoints = let
        # TODO: factorize these definitions with the one in facts (when declared).
        publicIPv4 = "100.85.79.53";
        domainNames = [
          "ns1.qyrnl.com"
          "ns2.qyrnl.com"
        ];
      in
        builtins.concatMap (fun:
          builtins.concatMap (domainName: [
            (fun domainName publicIPv4 {name = "${domainName} 🎯";})
            (fun domainName "8.8.8.8" {
              name = "${domainName} 🌐";
              rcode = "NXDOMAIN"; # Should _not_ resolve publicly.
            })
          ])
          domainNames) [lib.fn.mkDnsIPv4Endpoint lib.fn.mkDnsIPv6Endpoint];
    }
  ];

  config = lib.mkIf cfg.enable {
    services = {
      coredns = {
        enable = true;

        config = let
          inherit (config.node.facts.tailscale) tailnetName;
          zoneFile = pkgs.replaceVars ./dns/qyrnl.com {
            inherit tailnetName;
            inherit (config.node.facts.tailscale) tailscaleIPv4 tailscaleIPv6;
          };
          tailscaleInterface = config.services.tailscale.interfaceName;
        in ''
          qyrnl.com:53 {
            errors
            log stdout
            bind ${tailscaleInterface}
            file ${zoneFile}
          }
          ${tailnetName}:53 {
            errors
            log stdout
            bind ${tailscaleInterface}
            forward . 100.100.100.100:53
          }
          .:53 {
            errors
            log stdout
            bind ${tailscaleInterface}
            forward . 1.1.1.1:53
          }
        '';
      };

      tailscale.extraSetFlags = let
        isTailscaleNode = lib.fn.isTrue config.modules.system.networking.tailscaleNode;
      in
        lib.mkIf isTailscaleNode ["--accept-dns=true"];
    };

    systemd.services.coredns = {
      after = [
        "tailscaled.service"
        "tailscaled-autoconnect.service"
      ];
      unitConfig.Requires = ["tailscaled.service"];
      serviceConfig.RestartSec = "5s";
    };
  };
}
