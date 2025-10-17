{flake, ...}: {
  config,
  lib,
  pkgs,
  ...
}: let
  domainName = "pieceofenglish.fr";
in {
  options.node.services.dns.${domainName} = with lib; {
    enable = mkEnableOption "Spin up a DNS server for the ${domainName} domain";
    openFirewall = mkEnableOption "Open firewall ports for Piece of English service";

    bindInterface = mkOption {
      type = types.str;
      example = "eth0";
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
        zoneFile = pkgs.writeText domainName ''
          $ORIGIN ${domainName}.
          $TTL    3600

          @         IN SOA   ns.${domainName}. hostmaster.${domainName}. 2025070100 86400 10800 3600000 3600
          @   300   IN NS    ns1.${domainName}.
          @   300   IN NS    ns2.${domainName}.
          ns1 300   IN A     ${records.ns1.ipv4}
          ns1 300   IN AAAA  ${records.ns1.ipv6}
          ns2 300   IN A     ${records.ns2.ipv4}
          ns2 300   IN AAAA  ${records.ns2.ipv6}

          ; Protonmail domain configuration.
          @                       10800 IN TXT   "protonmail-verification=002e45ea53d2d587fdbd680b84930481eb8ecf9a"
          @                       10800 IN TXT   "v=spf1 include:_spf.protonmail.ch ~all"
          _dmarc                  10800 IN TXT   "v=DMARC1; p=quarantine"
          @                       10800 IN MX    10 mail.protonmail.ch.
          @                       10800 IN MX    20 mailsec.protonmail.ch.
          protonmail._domainkey   10800 IN CNAME protonmail.domainkey.d3oesgdehuo3lyylmnywtohdojzlokhdt3hyq5wreaxvd6vmz3a5q.domains.proton.ch.
          protonmail2._domainkey  10800 IN CNAME protonmail2.domainkey.d3oesgdehuo3lyylmnywtohdojzlokhdt3hyq5wreaxvd6vmz3a5q.domains.proton.ch.
          protonmail3._domainkey  10800 IN CNAME protonmail3.domainkey.d3oesgdehuo3lyylmnywtohdojzlokhdt3hyq5wreaxvd6vmz3a5q.domains.proton.ch.

          @         IN A     ${records."@".ipv4}
          @         IN AAAA  ${records."@".ipv6}
          www       IN CNAME @
        '';
      in ''
        ${domainName}:53 {
          errors
          log stdout
          bind ${cfg.bindInterface}
          file ${zoneFile}
        }
        .:53 {
          errors
          log stdout
          bind ${cfg.bindInterface}
          forward . 1.1.1.1:53
        }
      '';
    };

    networking.firewall = lib.mkIf (cfg.openFirewall) {
      interfaces.${cfg.bindInterface} = {
        allowedTCPPorts = [53];
        allowedUDPPorts = [53];
      };
    };

    systemd.services.coredns = {
      after = ["network-online.target"];
      wants = ["network-online.target"];
    };
  };
}
