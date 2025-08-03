{
  config,
  lib,
  ...
}:
lib.mkIf config.modules.system.services.serve.gotify {
  services.taskchampion-sync-server.enable = true;
}
