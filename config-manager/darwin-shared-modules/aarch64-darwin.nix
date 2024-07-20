{inputs, ...}: {
  nixpkgs.hostPlatform = "aarch64-darwin";

  nix.nixPath = [
    "nixpkgs=${inputs.nixpkgs-darwin}"
  ];
}
