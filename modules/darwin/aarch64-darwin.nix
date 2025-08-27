{inputs, ...}: {
  nixpkgs.hostPlatform = "aarch64-darwin";

  # nix.nixPath = [
  #   "nixpkgs=${inputs.nixpkgs-darwin}"
  # ];

  # Makes `nix run nixpkgs#…` run using the nixpkgs from this flake
  # nix.registry.nixpkgs.flake = inputs.nixpkgs-darwin;
}
