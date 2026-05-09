{
  flake.homeModules.programs-core-display =
    { pkgs, ... }:
    {
      # Packages I always want installed on systems with display
      home.packages = with pkgs; [
        mplayer # Remember QF60…
      ];
    };
}
