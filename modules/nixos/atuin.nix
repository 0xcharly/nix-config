{config, ...}: {
  services.atuin.enable = config.modules.system.services.serve.atuin;
}

