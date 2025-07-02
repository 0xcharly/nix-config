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

    # Hotfix for Ghostty until a kernel fix.
    # https://github.com/nixos/nixpkgs/issues/421442
    (_final: prev: {
      ghostty = prev.ghostty.overrideAttrs (_: {
        preBuild = ''
          shopt -s globstar
          sed -i 's/^const xev = @import("xev");$/const xev = @import("xev").Epoll;/' **/*.zig
          shopt -u globstar
        '';
      });
    })
  ];
}
