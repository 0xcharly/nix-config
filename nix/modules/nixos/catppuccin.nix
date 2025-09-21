{inputs, ...}: {
  imports = [inputs.catppuccin.nixosModules.catppuccin];

  catppuccin.tty.enable = true;
}
