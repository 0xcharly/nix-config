{inputs, ...}: {
  nix.nixPath = [
    "nixpkgs-unstable=${inputs.nixpkgs-unstable}"
    "home-manager=${inputs.home-manager}"
  ];
}
