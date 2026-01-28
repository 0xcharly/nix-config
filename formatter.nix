{
  pkgs,
  inputs,
  ...
}:
inputs.treefmt-nix.lib.mkWrapper pkgs {
  projectRootFile = "flake.lock";
  programs = {
    nixfmt.enable = true;
    prettier.enable = true;
    shfmt.enable = false;
  };
}
