{flake, ...}: {
  config,
  lib,
  pkgs,
  ...
}: let
  domainName = "qyrnl.com";
  tailnetDomainName = "neko-danio.ts.net";
in {
  options.node.services.dns.${domainName} = with lib; {
    enable = mkEnableOption "Spin up a DNS server for the ${domainName} domain";

    bindInterface = mkOption {
      type = types.str;
      example = "eth0";
      default = config.services.tailscale.interfaceName;
      description = "The network interface to bind to.";
    };
  };

  config = let
    cfg = config.node.services.dns.${domainName};
    inherit (flake.lib) facts;
  in {
    services.coredns = {
      inherit (cfg) enable;

      config = let
        records = facts.dns.${domainName};
        reverseProxyHostName = facts.reverse-proxy.${domainName}.host;
        zoneFile = pkgs.writeText domainName ''
          $ORIGIN ${domainName}.
          $TTL    3600

          @             IN SOA   ns.${domainName}. hostmaster.${domainName}. 2025070100 86400 10800 3600000 3600
          @       300   IN NS    ns1.${domainName}.
          @       300   IN NS    ns2.${domainName}.
          ns1     300   IN A     ${records.ns1.ipv4}
          ns1     300   IN AAAA  ${records.ns1.ipv6}
          ns2     300   IN A     ${records.ns2.ipv4}
          ns2     300   IN AAAA  ${records.ns2.ipv6}

          ; Hosts declaration.
          bowmore       IN CNAME bowmore.${tailnetDomainName}.
          dalmore       IN CNAME dalmore.${tailnetDomainName}.
          fwk           IN CNAME fwk.${tailnetDomainName}.
          heimdall      IN CNAME heimdall.${tailnetDomainName}.
          linode-fr     IN CNAME linode-fr.${tailnetDomainName}.
          linode-jp     IN CNAME linode-jp.${tailnetDomainName}.
          nyx           IN CNAME nyx.${tailnetDomainName}.
          rip           IN CNAME rip.${tailnetDomainName}.
          skl           IN CNAME skl.${tailnetDomainName}.

          ; Services declaration.
          album         IN CNAME ${reverseProxyHostName}
          atuin         IN CNAME ${reverseProxyHostName}
          files         IN CNAME ${reverseProxyHostName}
          git           IN CNAME ${reverseProxyHostName}
          github        IN CNAME ${reverseProxyHostName}
          graphs        IN CNAME ${reverseProxyHostName}
          jellyfin      IN CNAME ${reverseProxyHostName}
          music         IN CNAME ${reverseProxyHostName}
          news          IN CNAME ${reverseProxyHostName}
          prometheus    IN CNAME ${reverseProxyHostName}
          push          IN CNAME ${reverseProxyHostName}
          reads         IN CNAME ${reverseProxyHostName}
          search        IN CNAME ${reverseProxyHostName}
          shared.album  IN CNAME ${reverseProxyHostName}
          status        IN CNAME ${reverseProxyHostName}
          vault         IN CNAME ${reverseProxyHostName}
        '';
      in ''
        ${domainName}:53 {
          errors
          log stdout
          bind ${cfg.bindInterface}
          file ${zoneFile}
        }
        ${tailnetDomainName}:53 {
          errors
          log stdout
          bind ${cfg.bindInterface}
          forward . 100.100.100.100:53
        }
        .:53 {
          errors
          log stdout
          bind ${cfg.bindInterface}
          forward . 1.1.1.1:53
        }
      '';
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
