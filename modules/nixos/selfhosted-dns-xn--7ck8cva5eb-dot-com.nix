{ flake, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  domainName = "xn--7ck8cva5eb.com"; # チャーリー.com
in
{
  options.node.services.dns.${domainName} = with lib; {
    enable = mkEnableOption "Spin up a DNS server for the ${domainName} domain";
    openFirewall = mkEnableOption "Open firewall ports for the specified interface";

    bindInterface = mkOption {
      type = types.str;
      example = "eth0";
      description = "The network interface to bind to.";
    };
  };

  config =
    let
      cfg = config.node.services.dns.${domainName};
      inherit (flake.lib) facts;
    in
    {
      services.coredns = {
        inherit (cfg) enable;

        config =
          let
            records = facts.dns.${domainName};
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
            '';
          in
          ''
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
          allowedTCPPorts = [ 53 ];
          allowedUDPPorts = [ 53 ];
        };
      };

      systemd.services.coredns = {
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
      };
    };
}
