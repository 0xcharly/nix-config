{config-manager, ...}: {
  imports = with config-manager; [
    global.nix-client-config
    global.settings
    global.unfree
  ];
}
