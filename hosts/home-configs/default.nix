{config-manager, ...}: {
  imports = with config-manager; [system.nix-index];
}
