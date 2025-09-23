{
  pkgs,
  inputs,
  ...
}:
inputs.treefmt-nix.lib.mkWrapper pkgs {
  projectRootFile = "flake.lock";
  programs = {
    alejandra.enable = true;
    prettier.enable = true;
    shfmt.enable = false;
  };
  settings.formatter.prettier.excludes = [
    "nix/modules/home/walker-style.css"
    "nix/modules/home/waybar-style.css"
    "users/delay/walker/style.css"
    "users/delay/waybar/style.css"
  ];
}
