{
  config,
  lib,
  ...
}: let
  cfg = config.node.services.immich-public-proxy;
in {
  options.node.services.immich-public-proxy.enable = lib.mkEnableOption "Whether to spin up an Immich Public Proxy (IPP) server.";

  config.services.immich-public-proxy = {
    inherit (cfg) enable;
    immichUrl = "https://album.qyrnl.com";
  };
}
