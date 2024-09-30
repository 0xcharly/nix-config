{
  self,
  inputs,
  ...
}: {
  nixpkgs.overlays = [
    self.overlays.default
    inputs.nix-config-fonts.overlays.default
    inputs.nix-config-nvim.overlays.default
    inputs.rust-overlay.overlays.default
    (final: prev: {nvim = prev.nix-config-nvim;})
    # NOTE: I know, this is probably blasphemy. But hear me out…
    # I originally used a separate private repository that provided a flake that
    # exported Ghostty as a package for macOS and Linux.
    # However, maintaining a privately owned input in a pain, in particular when
    # bootstrapping installations, e.g. the VMs and remotes used daily, that now
    # requires GitHub authentication to be setup out of band.
    # I'm _actually_ using Ghostty on macOS, and currently not using any desktop
    # Linux (only headless).
    # So for now and probably until the first public release of Ghostty, this is
    # using Alacritty to impersonate the Ghostty package to avoid having to undo
    # a lot of the existing configuration in this repository.
    # TODO: Remove this when Ghostty is publicly released.
    (final: prev: {ghostty = prev.alacritty;})
  ];
}
