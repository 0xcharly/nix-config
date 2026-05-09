{ inputs, ... }:
{
  flake.darwinModules.nix-config =
    { config, lib, ... }:
    {
      nix = {
        settings = {
          allowed-users = [
            "delay"
            "@admin"
          ];
          trusted-users = [
            "delay"
            "@wheel"
          ];

          # Enable flakes
          experimental-features = "nix-command flakes";
          accept-flake-config = true;

          # Add community cache
          substituters = [
            "https://cache.nixos.org"
            "https://nix-community.cachix.org"
            "https://0xcharly-nixos-config.cachix.org"
          ];
          trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "0xcharly-nixos-config.cachix.org-1:qnguqEXJ4bEmJ8ceXbgB2R0rQbFqfWgxI+F7j4Bi6oU="
          ];
        };

        gc.automatic = true; # Run garbage collection periodically. Default is weekly.
        optimise.automatic = true;

        # Add each flake input as a registry
        registry = builtins.mapAttrs (_: value: { flake = value; }) inputs;

        # Add inputs to the system's legacy channels
        nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
      };
    };
}
