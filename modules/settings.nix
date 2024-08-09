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

      options.compositor = mkOption {
        default = "headless";
        type = types.enum ["headless" "quartz" "x11" "wayland"];
        description = ''
          Which compositor to use for the graphical environment on Linux.

          Use `headless` for a system without a graphical environment.
          macOS only supports `quartz`.
        '';
      };
    };
  };
}
