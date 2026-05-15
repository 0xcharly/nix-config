{
  flake.nixosModules.programs-essentials =
    { pkgs, ... }:
    {
      environment.defaultPackages = with pkgs; [
        bmon
        rsync
      ];
    };
}
