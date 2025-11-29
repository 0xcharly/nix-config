{
  flake,
  inputs,
  ...
}: {
  nixpkgs.overlays = [
    flake.overlays.default
    (super: prev: {
      nvim = inputs.nix-config-nvim.packages.${super.stdenv.hostPlatform.system}.default;
    })
  ];
}
