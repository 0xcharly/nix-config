{lib, ...}: let
  inherit (lib.options) mkOption;
  inherit (lib.types) listOf str;
in {
  options.node.facts = {
    tailscale = {
      tailscaleIP = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "100.101.102.103";
        description = "Tailscale IP of the node";
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
        default = ["heimdall" "linode" "nyx" "helios" "selene"];
        readOnly = true;
        description = ''
          The list of all hosts part of the tailnet.
        '';
      };
    };
  };
}
