{
  inputs,
  lib,
  ...
}: {
  imports = [inputs.catppuccin.homeModules.catppuccin];

  # Configure catppuccin theme applied throughout the configuration.
  catppuccin = {
    flavor = "mocha";
    accent = "blue";

    atuin.enable = true;
    bat.enable = true;
    bottom.enable = true;
    fish.enable = true;
    # TODO: figure out a better way to integrate with the github:catppuccin/nix config.
    # fzf.enable = true;
    hyprland.enable = true;
    nushell.enable = true;
  };

  programs.fzf.colors = let
    lavender = "#b4befe";
    accent = lavender;
    base = "#11181c";
    text = "#e1e8f4";
    rosewater = "#f5e0dc";
    surface_blue = "#203147";
    on_surface_blue = "#9fcdfe";
  in {
    bg = lib.mkForce base;
    "bg+" = lib.mkForce surface_blue;
    spinner = lib.mkForce rosewater;
    hl = lib.mkForce on_surface_blue;
    fg = lib.mkForce text;
    header = lib.mkForce accent;
    info = lib.mkForce accent;
    pointer = lib.mkForce on_surface_blue;
    marker = lib.mkForce accent;
    prompt = lib.mkForce accent;
    "fg+" = lib.mkForce text;
    "hl+" = lib.mkForce on_surface_blue;
  };
}
