# This function creates a Home Manager configuration.
{
  overlays,
  nixpkgs,
  inputs,
}: {
  userModule ? ../users/delay/home-manager.nix,
  system ? "x86_64-linux",
  isCorpManaged ? false,
  isHeadless ? false,
  username ? "delay",
}: let
  supportedSystems = [
    "aarch64-linux"
    "x86_64-linux"
  ];
  throwForUnsupportedSystems = expr:
    nixpkgs.lib.throwIfNot (builtins.elem system supportedSystems) ("Unsupported system '" + system + "'") expr;
in
  throwForUnsupportedSystems (inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import nixpkgs {inherit system;};
    extraSpecialArgs = {inherit inputs isCorpManaged isHeadless;};
    modules = [
      {
        nixpkgs.overlays = overlays;
        home = {
          inherit username;
          homeDirectory = "/home/${username}";
        };
      }
      userModule
    ];
  })
