{
  # node-skl is the wake-on-LAN relay used by the `wake` helper
  # (modules/home/programs-wake.nix): WOL magic packets are L2 broadcasts
  # and must originate on the physical LAN. Removing this degrades every
  # `wake` invocation to the slower `nix run nixpkgs#wakeonlan` fallback.
  flake.nixosModules.programs-wakeonlan =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.wakeonlan ];
    };
}
