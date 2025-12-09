{inputs, ...}: {
  nixpkgs.overlays = [
    (super: prev: {
      nvim = inputs.nix-config-nvim.packages.${super.stdenv.hostPlatform.system}.default;
    })
  ];
}
