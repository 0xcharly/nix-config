{config, lib, ...}: lib.mkIf config.modules.system.services.serve.jellyfin {
  services.jellyfin.enable = true;
}
