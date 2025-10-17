{lib, ...}: let
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) listOf nullOr str;
in {
  options.node.facts = {
    tailscale = {
      tailscaleIPv4 = lib.mkOption {
        type = nullOr lib.types.str;
        default = null;
        example = "100.101.102.103";
        description = "Tailscale IPv4 of the node";
      };

      tailscaleIPv6 = lib.mkOption {
        type = nullOr lib.types.str;
        default = null;
        example = "2001:db8::1";
        description = "Tailscale IPv6 of the node";
      };

      tailnetName = mkOption {
        type = str;
        default = "neko-danio.ts.net";
        readOnly = true;
        description = ''
          Unique name is used when registering DNS entries, sharing your device
          to other tailnets, and issuing TLS certificates.
        '';
      };

      allNodes = mkOption {
        type = listOf str;
        default = ["heimdall" "linode" "nyx" "helios" "skullkid"];
        readOnly = true;
        description = ''
          The list of all hosts part of the tailnet.
        '';
      };
    };
  };
}
