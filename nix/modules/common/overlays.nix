{
  flake,
  inputs,
  ...
}: {
  nixpkgs.overlays = [
    flake.overlays.default
    inputs.nix-config-nvim.overlays.default
  ];
}
