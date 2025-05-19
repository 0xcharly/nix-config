{
  self,
  inputs,
  ...
}: {
  nixpkgs.overlays = [
    self.overlays.default
    inputs.hyprpanel.overlay
    inputs.nur.overlays.default
    inputs.nix-config-nvim.overlays.nvim-override
    inputs.nix-config-secrets.overlays.default
  ];
}
