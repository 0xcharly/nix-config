{
  globalModules,
  sharedModules,
  ...
}: {
  imports = [
    globalModules.nix-client-config
    sharedModules.nix-index
    sharedModules.nixos
    sharedModules.user-delay
  ];
}
