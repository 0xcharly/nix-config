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

      # TODO: merge into compositor as new "headless" option.
      options.isHeadless = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Whether this host runs without a graphical environment.
        '';
      };

      options.compositor = mkOption {
        default = "x11";
        type = types.enum ["x11" "wayland"];
        description = ''
          Which compositor to use for the graphical environment on Linux.
        '';
      };
    };
  };
}
