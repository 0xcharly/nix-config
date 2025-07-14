{config, ...}: {
  services.atuin = {
    enable = config.modules.system.services.serve.atuin;
    # NOTE: temporary change that to add new users.
    openRegistration = false;
  };
}
