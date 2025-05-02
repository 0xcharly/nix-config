{
  self,
  inputs,
  ...
}: {
  nixpkgs.overlays = [
    self.overlays.default
    inputs.hyprpanel.overlay
    inputs.nur.overlays.default
    inputs.nix-config-fonts.overlays.default
    inputs.nix-config-nvim.overlays.default
    inputs.nix-config-secrets.overlays.default
    inputs.rust-overlay.overlays.default
    inputs.zellij-plugins.overlays.default
    inputs.zellij-prime-hopper.overlays.default
    (final: prev: {
      # Use the latest stable version of Node.js.
      # https://github.com/NixOS/nixpkgs/issues/402079
      nodejs = prev.nodejs_22;
      # Inject Copilot's plugin late so it can be excluded from the corporate
      # config.
      nvim = prev.nix-config-nvim.override (old: {
        plugins = old.plugins ++ [final.vimPlugins.copilot-vim];
      });
    })
  ];
}
