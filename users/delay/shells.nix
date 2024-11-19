{
  lib,
  pkgs,
  ...
} @ args: let
  config =
    if args ? osConfig
    then args.osConfig
    else args.config;
  inherit (config.modules.usrenv) isHeadless switcherApp;
  inherit (pkgs.stdenv) isLinux;

  isLinuxDesktop = isLinux && !isHeadless;

  homeDirectory = config.users.users.delay.home;
  codeDirectory = homeDirectory + "/code";
in {
  programs.bash.enable = true;
  programs.htop.enable = true;

  # `cat` replacement.
  programs.bat = {
    enable = true;
    catppuccin.enable = true;
  };

  # `find` replacement.
  programs.fd.enable = true;

  # `grep` replacement.
  programs.ripgrep.enable = true;

  # GitHub command-line integration.
  programs.gh.enable = true;

  # `ls` replacement.
  programs.eza = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.direnv = {
    enable = true;
    # enableFishIntegration = true; # read-only; always enabled.
    nix-direnv.enable = true;
    config.whitelist.prefix = [codeDirectory];
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
    catppuccin.enable = true;
  };

  programs.fish = {
    enable = true;
    catppuccin.enable = true;
    interactiveShellInit = lib.strings.concatStringsSep "\n" [
      (builtins.readFile ./config.fish)
      (lib.optionalString isLinuxDesktop "eval (${lib.getExe pkgs.keychain} --eval --nogui --quiet)")
      (lib.optionalString (switcherApp == "zellij") ''
        bind           \cf '__zellij_pathfinder'
        bind -M insert \cf '__zellij_pathfinder'
      '')
    ];

    functions = {
      fish_mode_prompt = ""; # Disable prompt vi mode reporting.
      __zellij_pathfinder = let
        launch_pathfinder = pkgs.writeTextFile {
          name = "launch-pathfinder.kdl";
          text = ''
            layout {
              floating_panes {
                pane {
                  plugin location="pathfinder" {
                    cwd "${codeDirectory}"
                    bootstrap true
                  }
                }
              }
            }
          '';
        };
      in ''
        if test -z $ZELLIJ
          command zellij -s bootstrap --layout ${launch_pathfinder} options --default-cwd ${codeDirectory}
        end
      '';
    };
    shellAliases =
      {
        # Shortcut to setup a nix-shell with `fish`. This lets you do something
        # like `nixsh -p go` to get an environment with Go but use `fish` along
        # with it.
        nixsh = "nix-shell --run ${lib.getExe pkgs.fish}";
        devsh = "nix develop --command ${lib.getExe pkgs.fish}";
      }
      // (lib.optionalAttrs isLinuxDesktop {
        # For consistency with macOS.
        pbcopy = lib.getExe pkgs.xclip;
        pbpaste = "${lib.getExe pkgs.xclip} -o";
      });
  };

  programs.zellij.settings.default_shell = lib.getExe pkgs.fish;

  home.sessionVariables.SHELL = lib.getExe pkgs.fish;

  home.packages =
    [
      pkgs.fishPlugins.fzf
      pkgs.fishPlugins.transient-fish
    ]
    ++ lib.optionals (switcherApp == "tmux") [
      pkgs.open-local-repository-fish
    ];
}
