{ ... }:
{
  flake.nixosModules.selfhosted-dns-catchall =
    { config, lib, ... }:
    {
      options.node.services.dns.catchall = with lib; {
        enable = mkEnableOption "Forward otherwise-unmatched DNS queries to an upstream resolver";
        openFirewall = mkEnableOption "Open firewall ports for the specified interface";

        bindInterface = mkOption {
          type = types.str;
          example = "eth0";
          description = "The network interface to bind to.";
        };
      };

      config =
        let
          cfg = config.node.services.dns.catchall;
        in
        {
          services.coredns = {
            inherit (cfg) enable;

            config = ''
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
    };
}
