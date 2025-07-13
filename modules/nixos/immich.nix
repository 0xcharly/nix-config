{config, ...}: {
  services.immich = {
    enable = config.modules.system.services.serve.immich;
    host = "0.0.0.0";
    mediaLocation = "/tank/delay/album";
    settings.server.externalDomain = "https://album.qyrnl.com";
  };

  services.immich-public-proxy = {
    enable = config.modules.system.services.serve.immich;
    immichUrl = "https://album.qyrnl.com";
  };
}
