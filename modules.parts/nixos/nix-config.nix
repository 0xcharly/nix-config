{ inputs, ... }:
{
  flake.nixosModules.nix-config =
    { config, lib, ... }:
    {
      imports = [ inputs.nix-config-secrets.nixosModules.nix-config ];

      nix = {
        settings = {
          # Sudo's users
          allowed-users = [
            "delay"
            "@wheel"
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

        # Use a ! prefix to skip validation at build time (which fails since the file
        # is not stored in the Nix store).
        extraOptions = ''
          !include ${config.age.secrets."services/nix-access-tokens.conf".path}
        '';
      };
    };
}
