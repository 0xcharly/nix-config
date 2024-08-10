{config-manager, ...}: {
  imports = with config-manager; [
    global.nix-client-config
    system.nix-index
    system.nixos
    system.user-delay
  ];
}
