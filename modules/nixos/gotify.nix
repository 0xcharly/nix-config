{
  config,
  lib,
  ...
}: let
  cfg = config.node.services.gotify;
in {
  options.node.services.gotify.enable = lib.mkEnableOption "Whether to spin up a Gotify server.";

  config.services = {
    gotify = {
      inherit (cfg) enable;
      environment.GOTIFY_SERVER_PORT = 6060;
      environmentFiles = [config.age.secrets."services/gotify.env".path];
    };

    caddy.virtualHosts = lib.mkIf config.node.services.reverseProxy.enable {
      "push.qyrnl.com".extraConfig = ''
        import ts_host
        reverse_proxy linode-jp.qyrnl.com:${toString config.services.gotify.environment.GOTIFY_SERVER_PORT}
      '';
    };

    gatus.settings.endpoints = [
      (lib.fn.mkHttpServiceEndpoint "gotify" "push.qyrnl.com")
    ];
  };
}
