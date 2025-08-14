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
  options.node.services.dns.enable = lib.mkEnableOption "Spins up a DNS server.";

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
