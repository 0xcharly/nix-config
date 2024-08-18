{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib.types) bool enum;

  cfg = config.modules.usrenv;
in {
  options.modules.usrenv = {
    isCorpManaged = mkOption {
      default = false;
      type = bool;
      description = ''
        Whether this host is managed by my employer.
      '';
    };

    compositor = mkOption {
      default = "quartz";
      type = enum ["headless" "quartz" "x11" "wayland"];
      description = ''
        Which compositor to use for the graphical environment on Linux.

        Use `headless` for a system without a graphical environment.
        macOS only supports `quartz`.
      '';
    };

    isHeadless = mkOption {
      default = cfg.compositor == "headless";
      type = bool;
      readOnly = true;
      description = ''
        Graphical environment will not be installed on a headless host.
      '';
    };
  };

  config.assertions = [
    {
      assertion = pkgs.stdenv.isDarwin -> cfg.compositor == "quartz";
      message = "macOS only supports the `quartz` compositor.";
    }
  ];
}
