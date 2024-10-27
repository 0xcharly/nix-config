{inputs, ...}: {
  # SOPS doesn't support nix-darwin yet.
  imports = [ inputs.sops-nix.homeManagerModules.sops ];
}
