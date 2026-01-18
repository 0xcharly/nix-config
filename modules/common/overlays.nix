{ inputs, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      nvim = inputs.nix-config-nvim.packages.${prev.stdenv.hostPlatform.system}.default;
    })
  ];
}
