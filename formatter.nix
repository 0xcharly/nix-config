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
  settings.formatter.prettier.excludes = [
    "modules/home/wayland-waybar-style.css"
  ];
}
