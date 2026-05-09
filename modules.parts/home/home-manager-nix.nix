{
  flake.homeModules.home-manager-nix =
    { lib, osConfig, ... }:
    with lib;
    {
      # Ensure that HM uses the same Nix package as the system
      nix.package = mkForce osConfig.nix.package;
    };
}
