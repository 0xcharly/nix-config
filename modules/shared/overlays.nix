{
  self,
  inputs,
  ...
}: {
  nixpkgs.overlays = [
    self.overlays.default

    inputs.nix-config-fonts.overlays.default
    # Override `pkgs.nvim` with custom distro.
    inputs.nix-config-nvim.overlays.default
    (_final: prev: {nvim = prev.nix-config-nvim.default;})

    inputs.nur.overlays.default
  ];
}
