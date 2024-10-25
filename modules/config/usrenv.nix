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

    enableProfileFont = mkOption {
      default = false;
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

    switcherApp = mkOption {
      default = "tmux";
      type = enum ["tmux" "zellij"];
      description = ''
        Which app to use for repository switching.

        Repository switching has 2 implementations:
          - TMUX based, which is stable
          - Zellij base, which is experimental

        This option allows for toggling the experimental Zellij integration
        during its stabilization phase.
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
