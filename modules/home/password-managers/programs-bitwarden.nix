# TODO(26.11): bitwarden-desktop depends on EOL Electron 39
# https://github.com/nixos/nixpkgs/issues/526914
{
  flake.homeModules.programs-bitwarden =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.bitwarden-desktop ];
    };
}
