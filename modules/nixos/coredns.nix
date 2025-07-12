{
  config,
  lib,
  pkgs,
  usrlib,
  ...
}: let
  tailscaleInterface = config.services.tailscale.interfaceName;
  inherit (config.node.facts.tailscale) tailscaleIP tailnetName;
  zoneFile = pkgs.replaceVars ./dns/qyrnl.com {inherit tailnetName tailscaleIP;};
in
  lib.mkIf config.modules.system.services.serve.dns {
    services.coredns = {
      enable = true;
      config = ''
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
    systemd.services.coredns = {
      after = [
        "tailscaled.service"
        "tailscaled-autoconnect.service"
      ];
      unitConfig.Requires = ["tailscaled.service"];
      serviceConfig.RestartSec = "5s";
    };

    services.tailscale.extraSetFlags = let
      isTailscaleNode = usrlib.bool.isTrue config.modules.system.networking.tailscaleNode;
    in
      lib.mkIf isTailscaleNode ["--accept-dns=true"];
  }
