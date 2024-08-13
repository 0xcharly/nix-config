{config-manager, ...}: {
  imports = with config-manager; [
    global.nix-client-config
    global.nix-path
    system.nix-index
  ];
}
