{
  inputs,
  pkgs,
  ...
}: {
  nix.nixPath = let
    nixpkgs =
      if pkgs.stdenv.isDarwin
      then inputs.nixpkgs-darwin
      else inputs.nixpkgs;
  in [
    "nixpkgs=${nixpkgs}"
    "nixpkgs-unstable=${inputs.nixpkgs-unstable}"
    "home-manager=${inputs.home-manager}"
  ];
}
