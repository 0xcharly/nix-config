{inputs, ...}: {
  # nix-index-database configuration.
  imports = [inputs.nix-index-database.hmModules.nix-index];
  programs.nix-index-database.comma.enable = true;
}
