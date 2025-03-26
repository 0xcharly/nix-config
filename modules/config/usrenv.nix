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

    isLinuxDesktop = mkOption {
      default = builtins.elem cfg.compositor ["x11" "wayland"];
      type = bool;
      readOnly = true;
      description = ''
        Linux host with a graphical environment.
      '';
    };

    isLinuxWaylandDesktop = mkOption {
      default = cfg.compositor == "wayland";
      type = bool;
      readOnly = true;
      description = ''
        Linux host with a Wayland graphical environment.
      '';
    };

    isLinuxX11Desktop = mkOption {
      default = cfg.compositor == "x11";
      type = bool;
      readOnly = true;
      description = ''
        Linux host with a X11/Xorg graphical environment.
      '';
    };

    installFonts = mkOption {
      default = !cfg.isHeadless;
      type = bool;
      description = ''
        Whether to install fonts via Home Manager.
      '';
    };

    sshAgent = mkOption {
      default = "system";
      type = enum ["system" "1password"];
      description = ''
        Which agent to use for SSH.

        There's 2 agents available:
          - The traditional ssh-agent: keys are stored under ~/.ssh
          - 1Password: keys are stored within the app vault

        This option allows for choosing between the 2 agents.

        1Password is currently only supported on macOS.
      '';
    };
  };

  config.assertions = [
    {
      assertion = pkgs.stdenv.isDarwin -> cfg.compositor == "quartz";
      message = "macOS only supports the `quartz` compositor.";
    }
    {
      assertion = builtins.elem cfg.compositor ["x11" "wayland"] -> pkgs.stdenv.isLinux;
      message = "`x11` and `wayland` are only supported on Linux.";
    }
  ];
}
