{
  inputs,
  pkgs,
  ...
}: let
  nixpkgs =
    if pkgs.stdenv.isDarwin
    then inputs.nixpkgs-darwin
    else inputs.nixpkgs;
in {
  nix.nixPath = [
    "nixpkgs=${nixpkgs}"
    "nixpkgs-unstable=${inputs.nixpkgs-unstable}"
    "home-manager=${inputs.home-manager}"
  ];

  nix.registry = {
    # Makes `nix run nixpkgs#…` run using the nixpkgs from this flake
    nixpkgs.flake = nixpkgs;
  };
}
