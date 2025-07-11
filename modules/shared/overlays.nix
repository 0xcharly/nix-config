{
  self,
  inputs,
  ...
}: {
  nixpkgs.overlays = [
    self.overlays.default
    inputs.nix-config-fonts.overlays.default
    inputs.nix-config-nvim.overlays.default
    inputs.nur.overlays.default
  ];
}
