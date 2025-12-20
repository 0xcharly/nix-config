{flake, ...}: {
  config,
  lib,
  ...
}: {
  options.node.services.linkwarden = with lib; {
    enable = mkEnableOption "Spin up a Linkwarden service";
  };

  config = let
    cfg = config.node.services.linkwarden;
    inherit (flake.lib) facts;
  in {
    node.fs.zfs.zpool.root.datadirs = lib.mkIf cfg.enable {
      linkwarden = {
        owner = config.services.linkwarden.user;
        group = config.services.linkwarden.group;
        mode = "0700";
      };
    };

    services = {
      linkwarden = {
        inherit (cfg) enable;
        inherit (facts.services.linkwarden) port;
        host = "0.0.0.0";
        storageLocation = config.node.fs.zfs.zpool.root.datadirs.linkwarden.absolutePath;
        environmentFile = config.age.secrets."services/linkwarden.env".path;

        environment = {
          NEXTAUTH_URL = "https://${facts.services.linkwarden.domain}/api/v1/auth";
          DISABLE_NEW_SSO_USERS = "true";
        };
        enableRegistration = false;
      };
    };
  };
}
