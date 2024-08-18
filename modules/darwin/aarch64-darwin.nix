{inputs, ...}: {
  nixpkgs.hostPlatform = "aarch64-darwin";

  nix.nixPath = [
    "nixpkgs=${inputs.nixpkgs-darwin}"
  ];

  nix.registry = {
    # Makes `nix run nixpkgs#…` run using the nixpkgs from this flake
    nixpkgs.flake = inputs.nixpkgs-darwin;
  };
}
