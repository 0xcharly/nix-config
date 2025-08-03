{config, ...}: {
  services.taskchampion-sync-server.enable = config.modules.system.services.serve.taskchampion-sync-server;
}
