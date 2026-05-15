{
  flake.nixosModules.programs-terminfo =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        ghostty.terminfo
        kitty.terminfo
      ];
    };
}
