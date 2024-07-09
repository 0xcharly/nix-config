# This function creates a Home Manager configuration.
{
  overlays,
  nixpkgs,
  inputs,
}: {
  system ? "x86_64-linux",
  isCorpManaged ? false,
  isHeadless ? false,
  username ? "delay",
  userModule ? ../users/${username},
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
      # System options.
      {
        nixpkgs.overlays = overlays;
        home = {
          inherit username;
          homeDirectory = "/home/${username}";
        };
      }

      # User configuration.
      userModule

      # nix-index-database configuration.
      inputs.nix-index-database.hmModules.nix-index
      {programs.nix-index-database.comma.enable = true;}
    ];
  })
