{
  config,
  inputs,
  lib,
  ...
}:
{
  nix = {
    # Add each flake input as a registry.
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    # Add inputs to the system's legacy channels.
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
  };
}
