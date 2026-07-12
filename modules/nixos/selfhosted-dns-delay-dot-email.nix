{ self, ... }:
{
  flake.nixosModules.selfhosted-dns-delay-dot-email =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      domainName = "delay.email";
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
          inherit (self.lib) facts;
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

                  @             IN SOA   ns.${domainName}. hostmaster.${domainName}. 2026071200 86400 10800 3600000 3600
                  @       300   IN NS    ns1.${domainName}.
                  @       300   IN NS    ns2.${domainName}.
                  ns1     300   IN A     ${records.ns1.ipv4}
                  ns1     300   IN AAAA  ${records.ns1.ipv6}
                  ns2     300   IN A     ${records.ns2.ipv4}
                  ns2     300   IN AAAA  ${records.ns2.ipv6}

                  ; Mailserver configuration.
                  mx      300   IN A     ${records.mx.ipv4}
                  mx      300   IN AAAA  ${records.mx.ipv6}
                  @       10800 IN MX    10 mx.delay.email.
                  @       10800 IN TXT   "v=spf1 mx ~all"
                  _dmarc  10800 IN TXT   "v=DMARC1; p=quarantine"
                  ; TODO(post-deploy): paste from jump-jp:/var/mail/dkim/delay.email.mail.txt
                  ; mail._domainkey  10800 IN TXT   "v=DKIM1; k=rsa; p=<pubkey>"
                '';
              in
              ''
                ${domainName}:53 {
                  errors
                  log stdout
                  bind ${cfg.bindInterface}
                  file ${zoneFile}
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
    };
}
