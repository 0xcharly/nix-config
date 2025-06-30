{
  self,
  inputs,
  ...
}: {
  nixpkgs.overlays = [
    self.overlays.default
    inputs.hyprpanel.overlay

    # Override `pkgs.nvim` with custom distro.
    inputs.nix-config-nvim.overlays.default
    (_final: prev: {nvim = prev.nix-config-nvim.default;})

    inputs.nix-config-fonts.overlays.default
    inputs.nix-config-secrets.overlays.default

    inputs.nur.overlays.default
  ];
}
