{
  config,
  lib,
  ...
}:
lib.mkIf config.modules.system.services.serve.gotify {
  services.gotify = {
    enable = true;
    environment.GOTIFY_SERVER_PORT = 6060;
    environmentFiles = [config.age.secrets."services/gotify.env".path];
  };
}
