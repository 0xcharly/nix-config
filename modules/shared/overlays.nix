{inputs, ...}: {
  nixpkgs.overlays = [
    inputs.alacritty-theme.overlays.default
    inputs.jujutsu.overlays.default
    inputs.nix-config-ghostty.overlays.default
    inputs.nix-config-nvim.overlays.default
    (final: prev: {nvim = prev.nix-config-nvim;})
  ];
}
