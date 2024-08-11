{config-manager, ...}: {
  imports = with config-manager; [
    global.nix-path
    system.nix-index
  ];
}
