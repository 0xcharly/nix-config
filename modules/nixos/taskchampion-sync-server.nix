{
  config,
  lib,
  ...
}: let
  cfg = config.node.services.taskchampion-sync-server;
in {
  options.node.services.taskchampion-sync-server.enable = lib.mkEnableOption "Whether to spin up a Taskchampion Sync server.";

  config.services = {
    taskchampion-sync-server = {
      inherit (cfg) enable;
    };

    caddy.virtualHosts."tasks.qyrnl.com" = {
      extraConfig = ''
        import ts_host
        reverse_proxy localhost:${toString config.services.taskchampion-sync-server.port}
      '';
    };
  };
}
