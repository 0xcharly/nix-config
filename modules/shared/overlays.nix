{
  self,
  inputs,
  ...
}: {
  nixpkgs.overlays = [
    self.overlays.default
    inputs.nur.overlays.default
    inputs.nix-config-fonts.overlays.default
    inputs.nix-config-nvim.overlays.default
    inputs.nix-config-secrets.overlays.default
    inputs.rust-overlay.overlays.default
    inputs.zellij-prime-hopper.overlays.default
    (final: prev: {
      # Inject Copilot's plugin late so it can be excluded from the corporate
      # config.
      nvim = prev.nix-config-nvim.override {
        plugins = prev.plugins ++ [final.copilot-vim];
      };
    })
  ];
}
