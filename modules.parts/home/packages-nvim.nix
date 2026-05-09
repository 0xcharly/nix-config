{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.nvim = inputs.nix-config-nvim.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };
}
