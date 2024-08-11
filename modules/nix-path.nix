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
  ];
}
