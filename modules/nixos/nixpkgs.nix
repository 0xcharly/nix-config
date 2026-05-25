{ inputs, ... }:
{
  flake.nixosModules.nixpkgs =
    { pkgs, ... }:
    {
      nixpkgs.config.allowUnfree = true;

      _module.args.pkgs' = import inputs.nixpkgs-unstable {
        inherit (pkgs.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };
    };
}
