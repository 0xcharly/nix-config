{ config, lib, ... }:
let
  cfg = config.node.networking.wakeOnLan;
in
{
  options.node.networking.wakeOnLan = with lib; {
    openFirewall = mkEnableOption "Open firewall ports for qyrnl.com's reverse proxy";
    interface = mkOption {
      type = types.str;
      example = "eth0";
      default = config.services.tailscale.interfaceName;
      description = "The network interface to bind to.";
    };
  };

  config.networking = {
    interfaces.${cfg.interface}.wakeOnLan.enable = true;
    firewall = lib.mkIf cfg.openFirewall {
      allowedUDPPorts = [ 9 ];
    };
  };
}
