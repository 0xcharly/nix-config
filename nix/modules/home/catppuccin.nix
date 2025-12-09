{inputs, ...}: {
  imports = [inputs.catppuccin.homeModules.catppuccin];

  # Configure catppuccin theme applied throughout the configuration.
  catppuccin = {
    flavor = "mocha";
    accent = "blue";

    atuin.enable = true;
    bat.enable = true;
    # TODO(25.05): reenable this when fixed.
    # bottom.enable = true;
    mako.enable = true;
  };
}
