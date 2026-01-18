{ inputs, ... }:
{ pkgs, ... }:
{
  _module.args.pkgs' = import inputs.nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
}
