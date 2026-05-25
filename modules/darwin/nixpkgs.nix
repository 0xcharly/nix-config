{ inputs, ... }:
{
  flake.darwinModules.nixpkgs =
    { pkgs, ... }:
    {
      nixpkgs = {
        config.allowUnfree = true;

        # Keep this consistent instead of automagically swapping nixpkgs for
        # nixpkgs-darwin on nix-darwin.
        flake = {
          setFlakeRegistry = false;
          setNixPath = false;
        };
      };

      _module.args.pkgs' = import inputs.nixpkgs-unstable {
        inherit (pkgs.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };
    };
}
