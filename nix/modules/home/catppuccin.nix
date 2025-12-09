{inputs, ...}: {
  imports = [inputs.catppuccin.homeModules.catppuccin];

  # Configure catppuccin theme applied throughout the configuration.
  catppuccin = {
    flavor = "mocha";
    accent = "blue";
  };
}
