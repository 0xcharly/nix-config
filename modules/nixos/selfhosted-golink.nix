{
  flake,
  inputs,
  ...
}: {
  config,
  lib,
  ...
}: {
  imports = [inputs.golink.nixosModules.default];

  options.node.services.golink = with lib; {
    enable = mkEnableOption "Spin up a go/link service";
  };

  config = let
    cfg = config.node.services.golink;
  in {
    node.fs.zfs.zpool.root.datadirs = lib.mkIf cfg.enable {
      golink = {
        owner = "golink";
        group = "golink";
        mode = "0700";
      };
    };

    services = {
      golink = {
        inherit (cfg) enable;
        tailscaleAuthKeyFile = config.age.secrets."services/tailscale-preauth.key".path;
      };
    };

    # Grant access to preauth key.
    users.users.golink.extraGroups = ["tailscale"];
  };
}
