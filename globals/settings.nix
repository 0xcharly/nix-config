{lib, ...}: let
  inherit (lib) mkOption types;
in {
  options.settings = mkOption {
    default = {};
    type = types.submodule {
      # Settings can be used to store any kind of value.
      freeformType = types.attrs;

      # Define the settings used in these configs.
      options.isCorpManaged = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Whether this host is managed by my employer.
        '';
      };
      options.isHeadless = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Whether this host runs without a graphical environment.
        '';
      };
    };
  };

  config.settings._debugIsEnabled = true;
}
