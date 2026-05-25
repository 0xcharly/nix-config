{ lib, ... }:
{
  config.systems = [ "aarch64-darwin" ];

  options.flake.darwinModules =
    with lib;
    mkOption {
      type = types.lazyAttrsOf types.deferredModule;
      default = { };
      description = "Attribute set of nix-darwin modules.";
    };
}
