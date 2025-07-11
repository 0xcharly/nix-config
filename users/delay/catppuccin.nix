{inputs, ...}: {
  imports = [inputs.catppuccin.homeModules.catppuccin];

  # Configure catppuccin theme applied throughout the configuration.
  catppuccin = {
    flavor = "mocha";

    bat.enable = true;
    bottom.enable = true;
    fish.enable = true;
    fzf.enable = true;
    hyprland.enable = true;
    nushell.enable = true;
  };
}
