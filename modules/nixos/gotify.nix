{
  config,
  lib,
  ...
}: let
  cfg = config.node.services.gotify;
in {
  options.node.services.gotify.enable = lib.mkEnableOption "Whether to spin up a Gotify server.";

  config.services.gotify = {
    inherit (cfg) enable;
    environment.GOTIFY_SERVER_PORT = 6060;
    environmentFiles = [config.age.secrets."services/gotify.env".path];
  };
}
