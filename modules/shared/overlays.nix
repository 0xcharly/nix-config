{
  self,
  inputs,
  ...
}: {
  nixpkgs.overlays = [
    self.overlays.default
    inputs.nur.overlays.default
    inputs.nix-config-fonts.overlays.default
    inputs.nix-config-ghostty.overlays.default
    inputs.nix-config-nvim.overlays.default
    inputs.rust-overlay.overlays.default
    (final: prev: {nvim = prev.nix-config-nvim;})
  ];
}
