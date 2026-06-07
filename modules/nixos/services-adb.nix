{
  flake.nixosModules.services-adb =
    { pkgs, ... }:
    {
      environment.defaultPackages = [ pkgs.android-tools ];
    };
}
